#!/usr/bin/env bash
set -euo pipefail

WIDTH="${WIDTH:-640}"
HEIGHT="${HEIGHT:-480}"
FPS="${FPS:-25}"
BITRATE="${BITRATE:-1500k}"
DEST_HOST="${DEST_HOST:-127.0.0.1}"
DEST_PORT="${DEST_PORT:-5602}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is not installed. Install it with: sudo apt install -y ffmpeg" >&2
  exit 1
fi

exec ffmpeg \
  -re \
  -f lavfi \
  -i "testsrc=size=${WIDTH}x${HEIGHT}:rate=${FPS}" \
  -an \
  -c:v libx264 \
  -preset ultrafast \
  -tune zerolatency \
  -b:v "$BITRATE" \
  -maxrate "$BITRATE" \
  -bufsize "$BITRATE" \
  -g "$FPS" \
  -f rtp \
  "rtp://${DEST_HOST}:${DEST_PORT}"
