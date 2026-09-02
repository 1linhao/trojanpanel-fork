#!/usr/bin/env bash
set -Eeuo pipefail

target="${1:-web}"
readonly BACKEND_IMAGE="ghcr.io/1linhao/trojan-panel@sha256:3a8ce5f58593da534ff4f122161bb06ad8bb1a9225f2f43d5487487514a7dbd4"
readonly UI_IMAGE="ghcr.io/1linhao/trojan-panel-ui@sha256:c557b244dcc70ea4335441cdc0a72290b8b77570e1cbb25b423da26e2daf873e"

ssh -o BatchMode=yes -o ConnectTimeout=10 "$target" bash -s -- "$BACKEND_IMAGE" "$UI_IMAGE" <<'REMOTE'
set -Eeuo pipefail
backend_image="$1"
ui_image="$2"
release_id="$(date -u +%Y%m%dT%H%M%SZ)"
tmp="$(mktemp -d /tmp/tp-traffic-web.XXXXXX)"
backup_dir="/tpdata/trojan-panel/backups"
db_backup="$backup_dir/db-before-traffic-dashboard-$release_id.sql"
backend_old="trojan-panel-traffic-rollback-$release_id"
ui_old="trojan-panel-ui-traffic-rollback-$release_id"
backend_swapped=0
ui_swapped=0
complete=0

rollback() {
  set +e
  if [[ "$ui_swapped" -eq 1 ]]; then
    docker rm -f trojan-panel-ui >/dev/null 2>&1 || true
    docker rename "$ui_old" trojan-panel-ui
    docker update --restart=always trojan-panel-ui >/dev/null
    docker start trojan-panel-ui >/dev/null
  fi
  if [[ "$backend_swapped" -eq 1 ]]; then
    docker rm -f trojan-panel >/dev/null 2>&1 || true
    docker rename "$backend_old" trojan-panel
    docker update --restart=always trojan-panel >/dev/null
    docker start trojan-panel >/dev/null
  fi
}
finish() {
  status=$?
  [[ "$complete" -eq 1 ]] || rollback
  find "$tmp" -type f -exec sh -c ': > "$1"; unlink "$1"' _ {} \;
  rmdir "$tmp" 2>/dev/null || true
  exit "$status"
}
trap finish EXIT

for container in trojan-panel trojan-panel-ui trojan-panel-mariadb; do docker inspect "$container" >/dev/null; done
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' trojan-panel >"$tmp/backend.env"
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' trojan-panel-ui >"$tmp/ui.env"
chmod 600 "$tmp/backend.env" "$tmp/ui.env"
mkdir -p "$backup_dir"
umask 077
docker exec trojan-panel-mariadb sh -lc 'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' >"$db_backup"
test -s "$db_backup"
docker pull "$backend_image"
docker pull "$ui_image"

docker update --restart=no trojan-panel >/dev/null
docker stop trojan-panel >/dev/null
docker rename trojan-panel "$backend_old"
backend_swapped=1
docker run -d --name trojan-panel --restart=always --network=host --env-file "$tmp/backend.env" --volumes-from "$backend_old" "$backend_image" >/dev/null
for _ in $(seq 1 45); do
  curl -fsS http://127.0.0.1:8081/api/auth/setting >/dev/null 2>&1 && break
  sleep 2
done
curl -fsS http://127.0.0.1:8081/api/auth/setting >/dev/null
docker exec trojan-panel-mariadb sh -lc 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N -e "
SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='"'"'node_server'"'"' AND COLUMN_NAME LIKE '"'"'traffic_%'"'"';
SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('"'"'account_traffic_total'"'"','"'"'account_server_traffic_daily'"'"');
SELECT COUNT(*) FROM casbin_rule WHERE v1='"'"'/api/dashboard/serverTrafficUsage'"'"' AND v0 IN ('"'"'sysadmin'"'"','"'"'admin'"'"');"' | awk 'NR==1 && $1!=5 {exit 1} NR==2 && $1!=2 {exit 1} NR==3 && $1!=2 {exit 1}'

docker update --restart=no trojan-panel-ui >/dev/null
docker stop trojan-panel-ui >/dev/null
docker rename trojan-panel-ui "$ui_old"
ui_swapped=1
docker run -d --name trojan-panel-ui --restart=always --network=host --env-file "$tmp/ui.env" --volumes-from "$ui_old" "$ui_image" >/dev/null
for _ in $(seq 1 30); do
  curl -fsS http://127.0.0.1:8888/ >/dev/null 2>&1 && curl -fsS http://127.0.0.1:8888/api/auth/setting >/dev/null 2>&1 && break
  sleep 2
done
curl -fsS http://127.0.0.1:8888/ >/dev/null
curl -fsS http://127.0.0.1:8888/api/auth/setting >/dev/null

complete=1
echo "Web traffic dashboard deployment completed."
echo "Database backup: $db_backup"
echo "Rollback containers retained: $backend_old, $ui_old"
REMOTE
