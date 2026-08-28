#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/restore-internet.sh" >&2
  exit 1
fi

systemctl stop openipc-tx-test-link.service >/dev/null 2>&1 || true
systemctl stop openipc-wfb-tx.service >/dev/null 2>&1 || true
systemctl start NetworkManager.service >/dev/null 2>&1 || true
ip link set eth0 up >/dev/null 2>&1 || true

if command -v nmcli >/dev/null 2>&1; then
  nmcli device connect eth0 >/dev/null 2>&1 || true
fi

echo "Ethernet restore requested."
echo "Check with: ping github.com"
