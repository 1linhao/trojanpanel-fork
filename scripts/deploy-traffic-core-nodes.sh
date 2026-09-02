#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bootstrap="$root/scripts/bootstrap-tp-core-kernel-runtime.sh"
ca="/home/lh/Public/vps/roles/node/files/trojan-panel-pki/client-ca.crt"
image="ghcr.io/1linhao/trojan-panel-core@sha256:c60be7fb4307eb6f41f01d72a876eba2da895139a96451551456dac8f40b3719"
installer="https://raw.githubusercontent.com/1linhao/trojan-panel-install-script/694ce82e11e10e9b2a75cb12f99f83a4eddb5a7d/custom_install.sh"

"$bootstrap" --target node-sf --instance node-sf --image "$image" --client-ca "$ca" \
  --server-name hy2sf2.lhsite.site --node-server-id 2 --installer-url "$installer" --apply
"$bootstrap" --target node-hk --instance node-hk --image "$image" --client-ca "$ca" \
  --server-name hy2hk.lhsite.site --node-server-id 5 --installer-url "$installer" --apply
