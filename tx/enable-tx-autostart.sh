#!/usr/bin/env bash
set -euo pipefail

mode="${1:-test}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/enable-tx-autostart.sh [test|camera|off]" >&2
  exit 1
fi

case "$mode" in
  test|camera)
    mkdir -p /etc/systemd/system/openipc-tx-test-link.service.d
    cat > /etc/systemd/system/openipc-tx-test-link.service.d/mode.conf <<EOF
[Service]
Environment=TX_AUTOSTART_MODE=${mode}
EOF
    systemctl daemon-reload
    systemctl enable openipc-tx-test-link.service
    systemctl restart openipc-tx-test-link.service
    echo "TX autostart enabled in ${mode} mode."
    echo "Logs: journalctl -u openipc-tx-test-link.service -f"
    ;;
  off|disable|disabled)
    systemctl disable --now openipc-tx-test-link.service
    echo "TX autostart disabled."
    ;;
  *)
    echo "Usage: $0 [test|camera|off]" >&2
    exit 1
    ;;
esac
