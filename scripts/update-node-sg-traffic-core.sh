#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
args=(
  --target node-sg
  --instance node-sg2
  --image ghcr.io/1linhao/trojan-panel-core@sha256:c60be7fb4307eb6f41f01d72a876eba2da895139a96451551456dac8f40b3719
  --client-ca /home/lh/Public/vps/roles/node/files/trojan-panel-pki/client-ca.crt
  --server-name hy2sg2.lhsite.site
  --node-server-id 3
  --installer-url https://raw.githubusercontent.com/1linhao/trojan-panel-install-script/694ce82e11e10e9b2a75cb12f99f83a4eddb5a7d/custom_install.sh
)
if [[ "${1:-}" == "--apply" ]]; then args+=(--apply); shift; fi
[[ $# -eq 0 ]] || { echo "用法：$0 [--apply]" >&2; exit 2; }
exec "$root/scripts/bootstrap-tp-core-kernel-runtime.sh" "${args[@]}"
