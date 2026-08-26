#!/usr/bin/env bash
set -euo pipefail

echo "== USB devices =="
lsusb || true

echo
echo "== Network interfaces =="
ip link || true

echo
echo "== Video nodes =="
ls -l /dev/video* 2>/dev/null || true

echo
echo "== Recent USB/kernel messages =="
dmesg | grep -Ei "usb|video|uvc|v4l|realtek|rtl|8812|capture|camera" | tail -120 || true
