#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

log_file="${OOD_CODE_TUNNEL_LOG:?}"
info_file="${OOD_CODE_TUNNEL_INFO:?}"
tunnel_name="${OOD_CODE_TUNNEL_NAME:?}"
tunnel_pid="${OOD_CODE_TUNNEL_PID:?}"

write_info() {
  local status="$1"
  local login_url="$2"
  local device_code="$3"
  local info_tmp
  info_tmp="$(mktemp "${info_file}.tmp.XXXXXX")"

  {
    printf 'status: %s\n' "$status"
    printf 'tunnel_name: "%s"\n' "$tunnel_name"
    if [ -n "$login_url" ]; then
      printf 'login_url: "%s"\n' "$login_url"
    fi
    if [ -n "$device_code" ]; then
      printf 'device_code: "%s"\n' "$device_code"
    fi
  } >"$info_tmp"

  mv "$info_tmp" "$info_file"
}

while kill -0 "$tunnel_pid" 2>/dev/null; do
  login_url="$(sed -n 's/.*please log into \(https:\/\/[^ ]*\).*/\1/pI' "$log_file" | tail -n 1)"
  device_code="$(sed -n 's/.*use code \([A-Z0-9-][A-Z0-9-]*\).*/\1/p' "$log_file" | tail -n 1)"

  status="starting"
  if [ -n "$login_url" ] || [ -n "$device_code" ]; then
    status="waiting_login"
  fi

  if rg -q 'Creating tunnel with the name:|Connected to an existing tunnel process' "$log_file"; then
    status="tunnel_ready"
  fi

  write_info "$status" "$login_url" "$device_code"
  sleep 2
done

login_url="$(sed -n 's/.*please log into \(https:\/\/[^ ]*\).*/\1/pI' "$log_file" | tail -n 1)"
device_code="$(sed -n 's/.*use code \([A-Z0-9-][A-Z0-9-]*\).*/\1/p' "$log_file" | tail -n 1)"
status="stopped"
if rg -q 'Creating tunnel with the name:|Connected to an existing tunnel process' "$log_file"; then
  status="tunnel_ready"
fi
write_info "$status" "$login_url" "$device_code"
