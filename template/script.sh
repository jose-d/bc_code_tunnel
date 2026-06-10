#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "TIMING - Starting main script at: $(date)"

if type module >/dev/null 2>&1; then
  module -q reset || true
fi

source "$OOD_STAGED_ROOT/ttyd.sh"

CODE_PATH="${OOD_CODE_PATH_OVERRIDE:-$(command -v code)}"
if [ -z "$CODE_PATH" ]; then
  echo "code not found in PATH"
  exit 12
fi

cd "$HOME" || exit 7

OOD_CODE_TUNNEL_NAME="${SLURM_JOB_ID}-$(hostname -s)"
OOD_CODE_TUNNEL_LOG="${TMPDIR}/code-tunnel.log"
OOD_CODE_TUNNEL_DATA_DIR="${HOME}/.local/cache/${SLURM_JOB_ID}"
OOD_CODE_TUNNEL_INFO="${OOD_STAGED_ROOT}/tunnel-info.yml"
mkdir -p "$OOD_CODE_TUNNEL_DATA_DIR"

export OOD_CODE_TUNNEL_NAME OOD_CODE_TUNNEL_LOG OOD_CODE_TUNNEL_DATA_DIR OOD_CODE_TUNNEL_INFO

OOD_UPDATE_TUNNEL_INFO_PID=""
OOD_CLEANED_UP=0

cleanup_tunnel() {
  if [ "$OOD_CLEANED_UP" -eq 1 ]; then
    return
  fi
  OOD_CLEANED_UP=1

  {
    printf '[%s] cleaning up VS Code tunnel\n' "$(date '+%F %T')"

    if [ -n "${OOD_UPDATE_TUNNEL_INFO_PID}" ] && kill -0 "${OOD_UPDATE_TUNNEL_INFO_PID}" 2>/dev/null; then
      kill "${OOD_UPDATE_TUNNEL_INFO_PID}" 2>/dev/null || true
      wait "${OOD_UPDATE_TUNNEL_INFO_PID}" 2>/dev/null || true
    fi

    if [ -n "${OOD_CODE_TUNNEL_PID:-}" ] && kill -0 "${OOD_CODE_TUNNEL_PID}" 2>/dev/null; then
      kill "${OOD_CODE_TUNNEL_PID}" 2>/dev/null || true
      wait "${OOD_CODE_TUNNEL_PID}" 2>/dev/null || true
    fi

    "$CODE_PATH" tunnel unregister \
      --cli-data-dir "$OOD_CODE_TUNNEL_DATA_DIR" || true

    printf '[%s] cleanup finished\n' "$(date '+%F %T')"
  } >>"$OOD_CODE_TUNNEL_LOG" 2>&1
}

trap cleanup_tunnel EXIT INT TERM HUP

cat >"$OOD_CODE_TUNNEL_INFO" <<EOF
status: starting
tunnel_name: "${OOD_CODE_TUNNEL_NAME}"
EOF

cat >"$OOD_CODE_TUNNEL_LOG" <<EOF
[$(date '+%F %T')] VS Code tunnel session starting
Slurm job: ${SLURM_JOB_ID}
Host: $(hostname -f)
Tunnel name: ${OOD_CODE_TUNNEL_NAME}
CLI data dir: ${OOD_CODE_TUNNEL_DATA_DIR}

The log below may show a device-login URL and short code.
Complete that login in your browser, then connect from local VS Code:
Remote Explorer -> Tunnels -> ${OOD_CODE_TUNNEL_NAME}

EOF

"$CODE_PATH" tunnel \
  --accept-server-license-terms \
  --name "$OOD_CODE_TUNNEL_NAME" \
  --cli-data-dir "$OOD_CODE_TUNNEL_DATA_DIR" \
  >>"$OOD_CODE_TUNNEL_LOG" 2>&1 &
OOD_CODE_TUNNEL_PID="$!"
export OOD_CODE_TUNNEL_PID

"$OOD_STAGED_ROOT/bin/update-tunnel-info.sh" &
OOD_UPDATE_TUNNEL_INFO_PID="$!"
export OOD_UPDATE_TUNNEL_INFO_PID

echo "TIMING - Starting ttyd at: $(date)"

"${OOD_TTYD_PATH_OVERRIDE:-ttyd}" \
  -p "${PORT}" \
  -b "/node/${HOST}/${PORT}" \
  "$OOD_STAGED_ROOT/bin/status-tail.sh"
