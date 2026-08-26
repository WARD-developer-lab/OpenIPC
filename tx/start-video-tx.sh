#!/usr/bin/env bash
set -euo pipefail

VIDEO_DEVICE="${VIDEO_DEVICE:-/dev/video0}"
WIDTH="${WIDTH:-720}"
HEIGHT="${HEIGHT:-576}"
FPS="${FPS:-25}"
BITRATE="${BITRATE:-2500k}"
DEST_HOST="${DEST_HOST:-127.0.0.1}"
DEST_PORT="${DEST_PORT:-5602}"

if [ ! -e "$VIDEO_DEVICE" ]; then
  echo "Video device not found: $VIDEO_DEVICE" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is not installed" >&2
  exit 1
fi

exec ffmpeg \
  -hide_banner \
  -loglevel info \
  -fflags nobuffer \
  -flags low_delay \
  -f v4l2 \
  -framerate "$FPS" \
  -video_size "${WIDTH}x${HEIGHT}" \
  -i "$VIDEO_DEVICE" \
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
