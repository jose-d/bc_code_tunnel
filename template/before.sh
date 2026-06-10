#!/usr/bin/env bash

[[ $(type -t module) == "function" ]] && export -f module

host="$(hostname -f)"
HOST="$host"
export host HOST

port=$(find_port)
PORT="$port"
export port PORT

password="$(create_passwd 16)"
PASSWORD="$password"
export password PASSWORD

TMPDIR="$(mktemp -d -p "/tmp" -t "$USER-tmpdir-XXXXXX")"
TMP_DIR="$TMPDIR"
chmod 700 "$TMPDIR"
export TMPDIR TMP_DIR

XDG_RUNTIME_DIR="$(mktemp -d -p "/tmp" -t "$USER-xdgrun-XXXXXX")"
chmod 700 "$XDG_RUNTIME_DIR"
export XDG_RUNTIME_DIR

OOD_SR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
if [ -f "${OOD_SR}/form.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  source "${OOD_SR}/form.sh"
fi
unset OOD_SR

function slurm_env_clean {
  eval "$(printenv | grep -i ^slurm | sed 's/^SLURM/export OOD_SLURM/')"
  unset $(compgen -v 'SLURM')
  echo "All environment variables starting with 'SLURM' have been renamed to be prefixed with 'OOD_'."
  printenv | grep -i '^OOD_SLURM'
}
export -f slurm_env_clean
