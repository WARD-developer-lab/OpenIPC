#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo ./tx/install-tx.sh" >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install -d /opt/openipc-fpv/tx
install -m 0755 "$repo_dir/tx/detect-camera.sh" /opt/openipc-fpv/tx/detect-camera.sh
install -m 0755 "$repo_dir/tx/start-video-tx.sh" /opt/openipc-fpv/tx/start-video-tx.sh
install -m 0644 "$repo_dir/tx/openipc-video-tx.service" /etc/systemd/system/openipc-video-tx.service

systemctl daemon-reload

echo "Installed TX service."
echo "Edit /etc/default/openipc-video-tx before enabling if your device is not /dev/video0."
echo "Enable with: systemctl enable --now openipc-video-tx.service"
