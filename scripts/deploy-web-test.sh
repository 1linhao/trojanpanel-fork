#!/usr/bin/env bash

set -Eeuo pipefail

SSH_TARGET="${1:-web-test}"

ssh "${SSH_TARGET}" 'bash -s' <<'REMOTE_SCRIPT'
set -Eeuo pipefail

backend_name="trojan-panel"
ui_name="trojan-panel-ui"
backend_image="ghcr.io/1linhao/trojan-panel:singbox"
ui_image="ghcr.io/1linhao/trojan-panel-ui:singbox"
release_id="$(date +%Y%m%d-%H%M%S)"
backend_backup="${backend_name}-rollback-${release_id}"
ui_backup="${ui_name}-rollback-${release_id}"
deploy_tmp="$(mktemp -d /tmp/trojan-panel-deploy.XXXXXX)"
db_backup_dir="/tpdata/trojan-panel/backups"
db_backup="${db_backup_dir}/db-before-client-types-${release_id}.sql"
backend_renamed=0
ui_renamed=0
deployment_complete=0

chmod 700 "${deploy_tmp}"

rollback() {
  set +e
  echo "Deployment failed; restoring previous containers."

  if [ "${backend_renamed}" -eq 1 ]; then
    docker rm -f "${backend_name}" >/dev/null 2>&1 || true
    docker rename "${backend_backup}" "${backend_name}"
    docker update --restart=always "${backend_name}" >/dev/null
    docker start "${backend_name}" >/dev/null
  fi
  if [ "${ui_renamed}" -eq 1 ]; then
    docker rm -f "${ui_name}" >/dev/null 2>&1 || true
    docker rename "${ui_backup}" "${ui_name}"
    docker update --restart=always "${ui_name}" >/dev/null
    docker start "${ui_name}" >/dev/null
  fi
}

finish() {
  status=$?
  if [ "${deployment_complete}" -ne 1 ]; then
    rollback
  fi
  find "${deploy_tmp}" -type f -exec sh -c 'umask 077; : > "$1"; unlink "$1"' _ {} \;
  rmdir "${deploy_tmp}" 2>/dev/null || true
  exit "${status}"
}
trap finish EXIT

for name in "${backend_name}" "${ui_name}" "trojan-panel-mariadb"; do
  docker inspect "${name}" >/dev/null
done

docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${backend_name}" >"${deploy_tmp}/backend.env"
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${ui_name}" >"${deploy_tmp}/ui.env"
chmod 600 "${deploy_tmp}/backend.env" "${deploy_tmp}/ui.env"

mkdir -p "${db_backup_dir}"
umask 077
docker exec trojan-panel-mariadb sh -lc \
  'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' >"${db_backup}"
test -s "${db_backup}"

docker pull "${backend_image}"
docker pull "${ui_image}"

docker update --restart=no "${backend_name}" "${ui_name}" >/dev/null
docker stop "${backend_name}" >/dev/null
docker rename "${backend_name}" "${backend_backup}"
backend_renamed=1

docker run -d \
  --name "${backend_name}" \
  --restart=always \
  --network=host \
  --env-file "${deploy_tmp}/backend.env" \
  --volumes-from "${backend_backup}" \
  "${backend_image}" >/dev/null

backend_ready=0
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8081/api/auth/setting >/dev/null; then
    backend_ready=1
    break
  fi
  sleep 2
done
test "${backend_ready}" -eq 1

# Preserve the current compatibility decision for existing NaiveProxy nodes.
docker exec trojan-panel-mariadb sh -lc \
  'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e "UPDATE node SET client_types='\''sing-box'\'' WHERE node_type_id=4"'

docker stop "${ui_name}" >/dev/null
docker rename "${ui_name}" "${ui_backup}"
ui_renamed=1

docker run -d \
  --name "${ui_name}" \
  --restart=always \
  --network=host \
  --env-file "${deploy_tmp}/ui.env" \
  --volumes-from "${ui_backup}" \
  "${ui_image}" >/dev/null

ui_ready=0
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8888/ >/dev/null &&
    curl -fsS http://127.0.0.1:8888/api/auth/setting >/dev/null; then
    ui_ready=1
    break
  fi
  sleep 2
done
test "${ui_ready}" -eq 1

docker exec trojan-panel-mariadb sh -lc \
  'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N -e "SELECT client_types, COUNT(*) FROM node GROUP BY client_types ORDER BY client_types"'

deployment_complete=1
echo "Deployment completed."
echo "Database backup: ${db_backup}"
echo "Rollback containers kept stopped: ${backend_backup}, ${ui_backup}"
echo "After verification, remove them with:"
echo "  docker rm ${backend_backup} ${ui_backup}"
REMOTE_SCRIPT
