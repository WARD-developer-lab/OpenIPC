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
install -m 0755 "$repo_dir/tx/start-test-video.sh" /opt/openipc-fpv/tx/start-test-video.sh
install -m 0755 "$repo_dir/tx/start-wfb-tx.sh" /opt/openipc-fpv/tx/start-wfb-tx.sh
install -m 0755 "$repo_dir/tx/run-tx-test.sh" /opt/openipc-fpv/tx/run-tx-test.sh
install -m 0755 "$repo_dir/tx/tx-preflight.sh" /opt/openipc-fpv/tx/tx-preflight.sh
install -m 0755 "$repo_dir/tx/install-tx-deps.sh" /opt/openipc-fpv/tx/install-tx-deps.sh
install -m 0755 "$repo_dir/tx/install-wfb-ng-standalone.sh" /opt/openipc-fpv/tx/install-wfb-ng-standalone.sh
install -m 0755 "$repo_dir/tx/configure-wfb-interface.sh" /opt/openipc-fpv/tx/configure-wfb-interface.sh
install -m 0755 "$repo_dir/tx/prepare-wfb-radio.sh" /opt/openipc-fpv/tx/prepare-wfb-radio.sh
install -m 0644 "$repo_dir/tx/openipc-video-tx.service" /etc/systemd/system/openipc-video-tx.service
install -m 0644 "$repo_dir/tx/openipc-wfb-tx.service" /etc/systemd/system/openipc-wfb-tx.service

if [ ! -f /etc/default/openipc-video-tx ]; then
  install -m 0644 "$repo_dir/tx/openipc-video-tx.env.example" /etc/default/openipc-video-tx
fi

if [ ! -f /etc/wifibroadcast.cfg ]; then
  install -m 0644 "$repo_dir/tx/wifibroadcast-drone.cfg.example" /etc/wifibroadcast.cfg
fi

if [ ! -f /etc/default/wifibroadcast ]; then
  install -m 0644 "$repo_dir/tx/wifibroadcast.default.example" /etc/default/wifibroadcast
fi

systemctl daemon-reload

echo "Installed TX service."
echo "Next:"
echo "  1. Run /opt/openipc-fpv/tx/install-tx-deps.sh if dependencies are missing."
echo "  1a. Run /opt/openipc-fpv/tx/install-wfb-ng-standalone.sh if wfb_tx is missing."
echo "  2. Edit /etc/default/openipc-video-tx if your camera is not /dev/video0."
echo "  3. Edit /etc/default/wifibroadcast and set WFB_NICS to your radio interface."
echo "  4. Run /opt/openipc-fpv/tx/prepare-wfb-radio.sh wlanX for that interface."
echo "  5. Copy matching /etc/drone.key and /etc/gs.key from the same wfb_keygen run."
echo "  6. Run: /opt/openipc-fpv/tx/tx-preflight.sh"
echo "  7. Quick test with: /opt/openipc-fpv/tx/run-tx-test.sh"
echo "  8. Enable with:"
echo "       systemctl enable --now openipc-video-tx.service"
echo "       systemctl enable --now openipc-wfb-tx.service"
