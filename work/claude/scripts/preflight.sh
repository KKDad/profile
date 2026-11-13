#!/bin/zsh
# Usage: preflight.sh [check|statusline]
#   check       run all checks, print a report, refresh the cache (use at shell startup)
#   statusline  print a compact cached line; refreshes the cache in the background when stale

cache_dir="$HOME/.cache/preflight"
cache_file="$cache_dir/status"
max_age_seconds=30
vnet_probe_host="tekton-dashboard.usw2.ci.upgrade.com"
vpn_probe_url="https://$vnet_probe_host/"

check_tsh() {
  tsh status >/dev/null 2>&1
}

check_vpn() {
  local http_code
  http_code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 --max-time 5 "$vpn_probe_url")
  [[ "$http_code" != 000 ]]
}

check_vnet() {
  local address
  address=$(dscacheutil -q host -a name "$vnet_probe_host" 2>/dev/null | awk '/^ip_address:/ { print $2; exit }')
  [[ "$address" =~ ^100\.([0-9]+)\.[0-9]+\.[0-9]+$ ]] || return 1
  (( match[1] >= 64 && match[1] <= 127 )) || return 1
  nc -z -G 2 "$address" 443 >/dev/null 2>&1
}

run_checks() {
  mkdir -p "$cache_dir"
  local tmp_file
  tmp_file=$(mktemp "$cache_dir/status.XXXXXX")
  for name in tsh vpn vnet; do
    if check_$name; then
      echo "$name=ok"
    else
      echo "$name=fail"
    fi
  done > "$tmp_file"
  mv "$tmp_file" "$cache_file"
}

cache_age_seconds() {
  [[ -f "$cache_file" ]] || { echo 999999; return; }
  echo $(( $(date +%s) - $(stat -f %m "$cache_file") ))
}

render_report() {
  local name state
  while IFS='=' read -r name state; do
    if [[ "$state" == ok ]]; then
      printf '  \033[32m✓\033[0m %s\n' "$name"
    else
      printf '  \033[31m✗\033[0m %s\n' "$name"
    fi
  done < "$cache_file"
}

render_statusline() {
  local name state line=""
  [[ -f "$cache_file" ]] || { echo "preflight: pending"; return; }
  while IFS='=' read -r name state; do
    if [[ "$state" == ok ]]; then
      line+="\033[32m✓\033[0m$name "
    else
      line+="\033[31m✗$name\033[0m "
    fi
  done < "$cache_file"
  printf '%b\n' "${line% }"
}

case "${1:-check}" in
  check)
    run_checks
    render_report
    ;;
  statusline)
    cat >/dev/null
    if (( $(cache_age_seconds) > max_age_seconds )); then
      ( run_checks >/dev/null 2>&1 & )
    fi
    render_statusline
    ;;
  *)
    echo "usage: preflight.sh [check|statusline]" >&2
    exit 2
    ;;
esac
