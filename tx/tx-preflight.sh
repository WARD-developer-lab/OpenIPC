#!/usr/bin/env bash
set -euo pipefail

fail=0

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK: $1"
  else
    echo "MISSING: $1"
    fail=1
  fi
}

echo "== Commands =="
check_cmd ffmpeg
check_cmd lsusb
check_cmd ip
check_cmd iw
check_cmd systemctl
check_cmd v4l2-ctl

echo
echo "== Camera =="
if ls /dev/video* >/dev/null 2>&1; then
  ls -l /dev/video*
else
  echo "MISSING: no /dev/video* devices"
  fail=1
fi

echo
echo "== USB =="
lsusb || true

echo
echo "== WiFi interfaces =="
ip link || true

echo
echo "== wfb-ng =="
if systemctl list-unit-files 'wifibroadcast@.service' >/dev/null 2>&1; then
  echo "OK: wifibroadcast@.service exists"
else
  echo "MISSING: wifibroadcast@.service"
  fail=1
fi

for key in /etc/drone.key /etc/gs.key; do
  if [ -s "$key" ]; then
    echo "OK: $key"
  else
    echo "MISSING: $key"
    fail=1
  fi
done

echo
echo "== Config =="
for cfg in /etc/default/openipc-video-tx /etc/wifibroadcast.cfg /etc/default/wifibroadcast; do
  if [ -s "$cfg" ]; then
    echo "OK: $cfg"
  else
    echo "MISSING: $cfg"
    fail=1
  fi
done

exit "$fail"
