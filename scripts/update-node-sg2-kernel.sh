#!/usr/bin/env bash
set -euo pipefail

readonly CORE_IMAGE="ghcr.io/1linhao/trojan-panel-core@sha256:ab95f17cd26075b50db5c7e25c647a5dd71da83f15e81908bb471fc28f436b3b"
readonly INSTALLER_URL="https://raw.githubusercontent.com/1linhao/trojan-panel-install-script/bcb1a587ccf94f083b1e9c09e8530ccfeddf2fc3/custom_install.sh"

usage() {
  cat <<'EOF'
用法：
  scripts/update-node-sg2-kernel.sh --server-name <SG2证书域名> [选项]

示例：
  scripts/update-node-sg2-kernel.sh \
    --server-name hy2sg2.example.com \
    --apply

默认只做只读预检。必须传入 --apply 才会生成、上传并升级。

选项：
  --target <SSH目标>       默认 node-sg2
  --server-name <域名>     必填；必须是 SG2 当前可签发证书的域名
  --ssh-port <端口>
  --identity <SSH私钥>
  --client-ca <CA公钥>     默认使用 VPS 脚本工厂中的客户端 CA
  --factory-root <目录>    默认 /home/lh/Public/vps/script-factory
  --keep-copied-sf-cert    不清理误复制到 SG2 的 hy2sf2.lhsite.site lineage
  --apply

升级成功后，仍需在面板服务器列表点击“检测并启用 mTLS”。
EOF
}

die() {
  echo "错误：$*" >&2
  exit 1
}

target="node-sg2"
server_name=""
ssh_port=""
identity=""
factory_root="/home/lh/Public/vps/script-factory"
client_ca=""
apply="false"
cleanup_sf="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="${2:-}"; shift 2 ;;
    --server-name) server_name="${2:-}"; shift 2 ;;
    --ssh-port) ssh_port="${2:-}"; shift 2 ;;
    --identity) identity="${2:-}"; shift 2 ;;
    --client-ca) client_ca="${2:-}"; shift 2 ;;
    --factory-root) factory_root="${2:-}"; shift 2 ;;
    --keep-copied-sf-cert) cleanup_sf="false"; shift ;;
    --apply) apply="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1" ;;
  esac
done

[[ "$target" =~ ^[A-Za-z0-9._@:-]+$ ]] || die "SSH 目标包含不支持的字符"
[[ "$server_name" =~ ^[A-Za-z0-9.-]+$ ]] || die "缺少或无效的 --server-name"
[[ "$server_name" != "hy2sf2.lhsite.site" ]] ||
  die "SG2 不能继续使用 SF 的证书域名 hy2sf2.lhsite.site"
[[ -d "$factory_root" ]] || die "脚本工厂不存在：$factory_root"
[[ -x "$factory_root/generator/gen.sh" ]] || die "找不到脚本工厂生成器"

if [[ -z "$client_ca" ]]; then
  client_ca="$factory_root/profiles/node/files/trojan-panel-pki/client-ca.crt"
fi
[[ -f "$client_ca" ]] || die "客户端 CA 公钥不存在：$client_ca"
grep -q -- "BEGIN CERTIFICATE" "$client_ca" || die "--client-ca 不是 PEM 证书"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bootstrap="$script_dir/bootstrap-tp-core-kernel-runtime.sh"
[[ -x "$bootstrap" ]] || die "找不到可执行的引导脚本：$bootstrap"

ssh_args=(-o BatchMode=yes -o ConnectTimeout=10)
rsync_ssh=(ssh -o BatchMode=yes -o ConnectTimeout=10)
bootstrap_args=(
  --target "$target"
  --instance node-sg2
  --image "$CORE_IMAGE"
  --client-ca "$client_ca"
  --server-name "$server_name"
)
if [[ -n "$ssh_port" ]]; then
  ssh_args+=(-p "$ssh_port")
  rsync_ssh+=(-p "$ssh_port")
  bootstrap_args+=(--ssh-port "$ssh_port")
fi
if [[ -n "$identity" ]]; then
  ssh_args+=(-i "$identity")
  rsync_ssh+=(-i "$identity")
  bootstrap_args+=(--identity "$identity")
fi
printf -v rsync_shell '%q ' "${rsync_ssh[@]}"

echo "node-sg2 一键内核升级"
echo "目标：$target"
echo "证书域名：$server_name"
echo "TP Core：$CORE_IMAGE"
if [[ "$cleanup_sf" == "true" ]]; then
  echo "升级健康检查成功后将清理误复制的 SF Certbot lineage。"
else
  echo "已选择保留误复制的 SF Certbot lineage。"
fi

source_env="$(
  ssh "${ssh_args[@]}" "$target" bash -s <<'REMOTE_DISCOVER'
set -euo pipefail
for candidate in \
  /root/vps-script-factory/node-sg2/node.env.yaml \
  /root/vps-script-factory/node/node.env.yaml; do
  [[ -f "$candidate" ]] || continue
  valid="true"
  for key in mariadb_host mariadb_port mariadb_user mariadb_password redis_host redis_port redis_password; do
    value="$(yq -r ".trojan_panel.${key} // \"\"" "$candidate")"
    if [[ -z "$value" || "$value" == REPLACE_WITH_* ]]; then
      valid="false"
      break
    fi
  done
  [[ "$valid" == "true" ]] || continue
  printf '%s\n' "$candidate"
  exit 0
done
exit 1
REMOTE_DISCOVER
)" || die "远端没有找到包含有效连接配置的 node-sg2 或旧 node 配置"

ssh "${ssh_args[@]}" "$target" bash -s -- "$source_env" <<'REMOTE_PREFLIGHT'
set -euo pipefail
source_env="$1"
command -v docker >/dev/null
command -v yq >/dev/null
command -v rsync >/dev/null
[[ "$(stat -c '%a' "$source_env")" =~ ^(600|640|400|440)$ ]] ||
  echo "警告：远端节点配置权限不是推荐的 0600/0640。" >&2
container="$(docker ps -a --format '{{.Names}}' | awk '$0=="trojan-panel-core"{print; exit}')"
[[ "$container" == "trojan-panel-core" ]]
docker inspect "$container" --format '当前容器={{.Name}} 镜像={{.Config.Image}} 状态={{.State.Status}}'
[[ "$(docker inspect "$container" --format '{{.State.Running}}')" == "true" ]]
df -Pk /tpdata | awk 'NR==2 { if ($4 < 524288) exit 1 }'
for key in mariadb_host mariadb_port mariadb_user mariadb_password redis_host redis_port redis_password; do
  value="$(yq -r ".trojan_panel.${key} // \"\"" "$source_env")"
  [[ -n "$value" && "$value" != REPLACE_WITH_* ]]
done
REMOTE_PREFLIGHT

if [[ "$apply" != "true" ]]; then
  echo "只读预检通过；未传入 --apply，远端没有发生修改。"
  exit 0
fi

echo "生成 node-sg2 专属部署包……"
(
  cd "$factory_root"
  bash generator/gen.sh node-sg2 --clean
  bash generator/gen.sh validate node-sg2
)

dist_dir="$factory_root/dist/node-sg2"
[[ -d "$dist_dir" ]] || die "node-sg2 生成包不存在"

source_copy="/root/vps-script-factory/.node-sg2-source-env.$$"
cleanup_remote_source() {
  ssh "${ssh_args[@]}" "$target" bash -s -- "$source_copy" <<'REMOTE_CLEANUP' >/dev/null 2>&1 || true
set -euo pipefail
source_copy="$1"
if [[ -f "$source_copy" ]]; then
  unlink "$source_copy"
fi
REMOTE_CLEANUP
}
trap cleanup_remote_source EXIT

ssh "${ssh_args[@]}" "$target" bash -s -- "$source_env" "$source_copy" <<'REMOTE_STAGE_SOURCE'
set -euo pipefail
source_env="$1"
source_copy="$2"
install -m 0600 "$source_env" "$source_copy"
REMOTE_STAGE_SOURCE

echo "上传 node-sg2 包（不会在上传阶段启动服务）……"
rsync -a --delete --exclude /backups/ -e "$rsync_shell" \
  "$dist_dir/" "$target:/root/vps-script-factory/node-sg2/"

ssh "${ssh_args[@]}" "$target" bash -s -- \
  "$source_copy" "$server_name" "$CORE_IMAGE" "$INSTALLER_URL" <<'REMOTE_HYDRATE'
set -euo pipefail
source_copy="$1"
server_name="$2"
core_image="$3"
installer_url="$4"
remote_root="/root/vps-script-factory/node-sg2"
node_env="$remote_root/node.env.yaml"
factory_env="$remote_root/env.yaml"

# Start from the server's existing restricted config so database and Redis
# credentials never leave the VPS, then add only the new managed-kernel fields.
install -m 0600 "$source_copy" "$node_env"
SERVER_NAME="$server_name" CORE_IMAGE="$core_image" INSTALLER_URL="$installer_url" \
  yq -i '
    .trojan_panel.url = strenv(INSTALLER_URL) |
    .trojan_panel.node_hostname = strenv(SERVER_NAME) |
    .trojan_panel.core_image = strenv(CORE_IMAGE) |
    .trojan_panel.grpc_tls_mode = "mtls" |
    .trojan_panel.grpc_tls_server_name = strenv(SERVER_NAME) |
    .trojan_panel.grpc_client_ca_path = "/tpdata/trojan-panel-core/pki/client-ca.crt" |
    .trojan_panel.kernel_runtime_path = "/tpdata/trojan-panel-core/runtime" |
    .trojan_panel.force = "1" |
    .trojan_panel.purge_data = "0"
  ' "$node_env"

node_mail="$(yq -r '.trojan_panel.node_mail // ""' "$node_env")"
SERVER_NAME="$server_name" INSTALLER_URL="$installer_url" yq -i '
  .cert.items[0].domain = strenv(SERVER_NAME) |
  .trojan_panel.url = strenv(INSTALLER_URL)
' "$factory_env"
if [[ -n "$node_mail" ]]; then
  NODE_MAIL="$node_mail" yq -i '.cert.email = strenv(NODE_MAIL)' "$factory_env"
fi
chmod 0600 "$node_env"
REMOTE_HYDRATE

cleanup_remote_source
trap - EXIT

if [[ "$cleanup_sf" == "true" ]]; then
  bootstrap_args+=(--cleanup-copied-sf-cert)
fi
bootstrap_args+=(--apply)

"$bootstrap" "${bootstrap_args[@]}"

echo
echo "node-sg2 内核升级完成。"
echo "下一步：在面板服务器列表点击“检测并启用 mTLS”。"
