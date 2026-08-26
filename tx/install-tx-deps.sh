#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/install-tx-deps.sh" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This helper currently supports Debian/Radxa OS images with apt-get." >&2
  echo "Install manually: ffmpeg v4l-utils iw iproute2 wireless-tools git ca-certificates" >&2
  exit 1
fi

apt-get update
apt-get install -y \
  ca-certificates \
  ffmpeg \
  git \
  iproute2 \
  iw \
  v4l-utils \
  wireless-tools

echo
echo "Base TX packages installed."
echo "Still required separately:"
echo "  - wfb-ng"
echo "  - WFB-capable RTL8812AU/RTL8812EU driver for your kernel"
