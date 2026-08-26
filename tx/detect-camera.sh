#!/usr/bin/env bash
set -euo pipefail

echo "== USB devices =="
lsusb || true

echo
echo "== Video nodes =="
ls -l /dev/video* 2>/dev/null || {
  echo "No /dev/video* devices found"
  exit 1
}

echo
if command -v v4l2-ctl >/dev/null 2>&1; then
  echo "== V4L2 devices =="
  v4l2-ctl --list-devices || true

  first_video="$(ls /dev/video* 2>/dev/null | head -n 1)"
  if [ -n "${first_video:-}" ]; then
    echo
    echo "== Formats for ${first_video} =="
    v4l2-ctl --device="$first_video" --list-formats-ext || true
  fi
else
  echo "v4l2-ctl is not installed. Install package: v4l-utils"
fi
