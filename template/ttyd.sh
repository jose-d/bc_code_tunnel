#!/usr/bin/env bash

TTYD_PATH="$(command -v ttyd)"
if [ -z "$TTYD_PATH" ]; then
  echo "ttyd not found in PATH"
  exit 9
fi
export TTYD_PATH

function ttyd {
  "$TTYD_PATH" "$@"
}
export -f ttyd
