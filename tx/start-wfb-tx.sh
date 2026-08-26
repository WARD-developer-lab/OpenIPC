#!/usr/bin/env bash
set -euo pipefail

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files 'wifibroadcast@.service' >/dev/null 2>&1; then
  exec systemctl start wifibroadcast@drone.service
fi

if command -v wfb_tx >/dev/null 2>&1; then
  echo "wifibroadcast@.service was not found. This image has wfb_tx but no known wrapper."
  echo "Install wfb-ng with systemd support or start wfb-ng manually for profile 'drone'." >&2
  exit 1
fi

echo "wfb-ng is not installed or is not in PATH." >&2
echo "Install wfb-ng before enabling openipc-wfb-tx.service." >&2
exit 1
