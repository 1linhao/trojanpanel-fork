#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
用法：
  bootstrap-tp-core-kernel-runtime.sh --target <ssh目标> \
    --image ghcr.io/1linhao/trojan-panel-core@sha256:<64位摘要> \
    --client-ca <客户端CA公钥文件> --server-name <节点证书域名> [选项]

默认仅执行只读预检；必须显式传入 --apply 才会修改远端。

选项：
  --instance <node-sf|node-hk|node-sg> 默认 node-sf
  --node-server-id <正整数>           面板 node_server.id，流量记账必填
  --installer-url <HTTPS URL>         新版 custom_install.sh 固定地址
  --ssh-port <端口>
  --identity <SSH私钥>
  --apply
  --cleanup-copied-sf-cert            仅允许与 --instance node-sg2 一起使用；
                                      清理误复制的 hy2sf2.lhsite.site Certbot lineage
EOF
}

die() {
  echo "错误：$*" >&2
  exit 1
}

target=""
image=""
client_ca=""
server_name=""
node_server_id=""
installer_url=""
instance="node-sf"
ssh_port=""
identity=""
apply="false"
cleanup_sf="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="${2:-}"; shift 2 ;;
    --image) image="${2:-}"; shift 2 ;;
    --client-ca) client_ca="${2:-}"; shift 2 ;;
    --server-name) server_name="${2:-}"; shift 2 ;;
    --node-server-id) node_server_id="${2:-}"; shift 2 ;;
    --installer-url) installer_url="${2:-}"; shift 2 ;;
    --instance) instance="${2:-}"; shift 2 ;;
    --ssh-port) ssh_port="${2:-}"; shift 2 ;;
    --identity) identity="${2:-}"; shift 2 ;;
    --apply) apply="true"; shift ;;
    --cleanup-copied-sf-cert) cleanup_sf="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1" ;;
  esac
done

[[ -n "$target" ]] || die "缺少 --target"
[[ "$target" =~ ^[A-Za-z0-9._@:-]+$ ]] || die "SSH 目标包含不支持的字符"
[[ "$image" =~ ^ghcr\.io/1linhao/trojan-panel-core@sha256:[a-f0-9]{64}$ ]] ||
  die "--image 必须是固定的 ghcr.io/1linhao/trojan-panel-core@sha256 摘要"
[[ -f "$client_ca" ]] || die "客户端 CA 公钥文件不存在"
grep -q -- "BEGIN CERTIFICATE" "$client_ca" || die "--client-ca 不是 PEM 证书"
[[ "$server_name" =~ ^[A-Za-z0-9.-]+$ ]] || die "节点证书域名无效"
[[ "$node_server_id" =~ ^[1-9][0-9]*$ ]] || die "缺少或无效的 --node-server-id"
[[ -z "$installer_url" || "$installer_url" =~ ^https:// ]] || die "--installer-url 必须使用 HTTPS"
case "$instance" in
  node-sf|node-hk|node-sg|node-sg2) ;;
  *) die "--instance 只允许 node-sf、node-hk、node-sg 或 node-sg2" ;;
esac
if [[ "$cleanup_sf" == "true" && "$instance" != "node-sg2" ]]; then
  die "证书清理开关只能用于 node-sg2"
fi

ssh_args=(-o BatchMode=yes -o ConnectTimeout=10)
[[ -z "$ssh_port" ]] || ssh_args+=(-p "$ssh_port")
[[ -z "$identity" ]] || ssh_args+=(-i "$identity")
remote_root="/root/vps-script-factory/$instance"
remote_env="$(ssh "${ssh_args[@]}" "$target" bash -s -- "$remote_root" <<'REMOTE_ENV'
set -euo pipefail
root="$1"
for candidate in "$root/node.env.yaml" "$root/runtime/trojan-panel.yaml"; do
  if [[ -f "$candidate" ]]; then
    printf '%s\n' "$candidate"
    exit 0
  fi
done
exit 1
REMOTE_ENV
)" || die "远端没有找到节点部署配置"

echo "预检目标：$target（实例 $instance）"
ssh "${ssh_args[@]}" "$target" bash -s -- "$remote_env" <<'REMOTE_PREFLIGHT'
set -euo pipefail
env_path="$1"
[[ -f "$env_path" ]]
command -v docker >/dev/null
command -v yq >/dev/null
command -v curl >/dev/null
container="$(docker ps -a --format '{{.Names}}' | awk '$0=="trojan-panel-core"{print; exit}')"
[[ "$container" == "trojan-panel-core" ]]
docker inspect "$container" --format '容器={{.Name}} 镜像={{.Image}} 状态={{.State.Status}}'
test -x /usr/bin/sha256sum || command -v sha256sum >/dev/null
df -Pk /tpdata | awk 'NR==2 { if ($4 < 524288) exit 1 }'
REMOTE_PREFLIGHT

if [[ "$apply" != "true" ]]; then
  echo "预检通过；未传入 --apply，远端没有发生修改。"
  exit 0
fi

ca_remote="/tmp/trojan-panel-client-ca.$$.crt"
scp_args=()
[[ -z "$ssh_port" ]] || scp_args+=(-P "$ssh_port")
[[ -z "$identity" ]] || scp_args+=(-i "$identity")
scp "${scp_args[@]}" "$client_ca" "$target:$ca_remote"

set +e
ssh "${ssh_args[@]}" "$target" bash -s -- \
  "$remote_root" "$remote_env" "$image" "$ca_remote" "$server_name" "$cleanup_sf" "$node_server_id" "$installer_url" <<'REMOTE_APPLY'
set -euo pipefail
remote_root="$1"
env_path="$2"
image="$3"
ca_source="$4"
server_name="$5"
cleanup_sf="$6"
node_server_id="$7"
installer_url="$8"
data_root="/tpdata/trojan-panel-core"
runtime_root="$data_root/runtime"
backup_root="$remote_root/backups/kernel-runtime-$(date -u +%Y%m%dT%H%M%SZ)"
container="trojan-panel-core"

run_node_installer() {
  local url installer
  url="$(yq -r '.trojan_panel.url // ""' "$env_path")"
  [[ "$url" =~ ^https:// ]] || { echo "节点安装器 URL 无效" >&2; return 1; }
  installer="$(mktemp /tmp/trojan-panel-node-installer.XXXXXX)"
  curl -fsSL "$url" -o "$installer"
  chmod 700 "$installer"
  if ! bash "$installer" node "$env_path"; then
    unlink "$installer"
    return 1
  fi
  unlink "$installer"
}

mkdir -p "$backup_root" "$runtime_root" "$data_root/pki"
chmod 700 "$backup_root" "$data_root/pki"
cp -a "$env_path" "$backup_root/node.env.yaml"
docker inspect "$container" >"$backup_root/container-inspect.json"
docker inspect "$container" --format '{{.Config.Image}}' >"$backup_root/previous-image.txt"

restore() {
  echo "升级失败，正在恢复旧配置和容器……" >&2
  cp -a "$backup_root/node.env.yaml" "$env_path"
  previous_image="$(cat "$backup_root/previous-image.txt")"
  yq -i ".trojan_panel.core_image = \"$previous_image\"" "$env_path"
  run_node_installer || true
}
trap restore ERR

snapshot_kernel() {
  local kernel="$1"
  local binary="$2"
  local legacy_version="$3"
  local version_dir="$runtime_root/$kernel/versions/$legacy_version"
  if [[ -e "$runtime_root/$kernel/current" ]]; then
    return
  fi
  mkdir -p "$version_dir"
  docker cp "$container:$data_root/bin/$binary/$binary" "$version_dir/$binary"
  chmod 755 "$version_dir/$binary"
  sha="$(sha256sum "$version_dir/$binary" | awk '{print $1}')"
  cat >"$version_dir/metadata.json" <<EOF
{"version":"$legacy_version","channel":"legacy","sha256":"$sha","installedAt":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","legacy":true,"successful":true}
EOF
  ln -s "versions/$legacy_version" "$runtime_root/$kernel/.current-new"
  mv -Tf "$runtime_root/$kernel/.current-new" "$runtime_root/$kernel/current"
}

snapshot_kernel xray xray legacy-v1.8.4
snapshot_kernel hysteria2 hysteria2 legacy-v2.0.4-dev
install -m 0644 "$ca_source" "$data_root/pki/client-ca.crt"
unlink "$ca_source"

yq -i \
  ".trojan_panel.core_image = \"$image\" |
   .trojan_panel.grpc_tls_mode = \"mtls\" |
   .trojan_panel.grpc_tls_server_name = \"$server_name\" |
	   .trojan_panel.grpc_client_ca_path = \"$data_root/pki/client-ca.crt\" |
	   .trojan_panel.kernel_runtime_path = \"$runtime_root\" |
	   .trojan_panel.node_server_id = \"$node_server_id\"" \
	  "$env_path"

	if [[ -n "$installer_url" ]]; then
	  INSTALLER_URL="$installer_url" yq -i '.trojan_panel.url = strenv(INSTALLER_URL)' "$env_path"
	fi

docker pull "$image"
run_node_installer

deadline=$((SECONDS + 60))
until [[ "$(docker inspect "$container" --format '{{.State.Running}}')" == "true" ]]; do
  (( SECONDS < deadline )) || {
    docker logs --tail 100 "$container" >&2 || true
    false
  }
  sleep 2
done
docker exec "$container" test -x "$data_root/runtime/xray/current/xray"
docker exec "$container" test -x "$data_root/runtime/hysteria2/current/hysteria2"

# The replacement is now healthy. Certificate incident cleanup must never
# roll the Core back after this point.
trap - ERR

# Only remove the wrongly copied SF lineage after the replacement Core has
# passed its health checks. A failed upgrade therefore leaves the old
# certificate state untouched for the rollback path.
if [[ "$cleanup_sf" == "true" ]]; then
  certbot delete --cert-name hy2sf2.lhsite.site --non-interactive || true
  for copied_path in \
    /etc/letsencrypt/live/hy2sf2.lhsite.site \
    /etc/letsencrypt/archive/hy2sf2.lhsite.site; do
    if [[ -d "$copied_path" ]]; then
      find "$copied_path" -depth -delete
    fi
  done
  if [[ -f /etc/letsencrypt/renewal/hy2sf2.lhsite.site.conf ]]; then
    unlink /etc/letsencrypt/renewal/hy2sf2.lhsite.site.conf
  fi
  find /etc/letsencrypt/renewal-hooks -maxdepth 2 -type f \
    -exec grep -l 'hy2sf2\.lhsite\.site' {} \; -delete 2>/dev/null || true
fi

echo "升级完成。备份位于：$backup_root"
REMOTE_APPLY
status=$?
set -e
if [[ $status -ne 0 ]]; then
  die "远端升级失败；脚本已尝试恢复旧容器和配置"
fi

echo "节点升级成功。请在面板服务器列表中点击“检测并启用 mTLS”。"
