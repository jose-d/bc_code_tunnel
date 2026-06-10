#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

log_file="${OOD_CODE_TUNNEL_LOG:?}"
tunnel_name="${OOD_CODE_TUNNEL_NAME:?}"
tunnel_pid="${OOD_CODE_TUNNEL_PID:?}"

cat <<EOF
VS Code Tunnel status viewer
============================

This page is read-only.

Tunnel name: ${tunnel_name}
Host: $(hostname -f)
Slurm job: ${SLURM_JOB_ID}

What to do:
1. Wait for the device-login URL and code below.
2. Complete login in your browser.
3. Open local VS Code and attach from Remote Explorer -> Tunnels.

EOF

tail --pid="$tunnel_pid" -n +1 -F "$log_file" || true

printf '\n[%s] tunnel process is no longer running\n' "$(date '+%F %T')"
sleep infinity
