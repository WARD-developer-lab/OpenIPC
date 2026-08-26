#!/usr/bin/env bash
set -euo pipefail

VIDEO_DEVICE="${VIDEO_DEVICE:-/dev/video0}"
WIDTH="${WIDTH:-720}"
HEIGHT="${HEIGHT:-576}"
FPS="${FPS:-25}"
BITRATE="${BITRATE:-2500k}"
DEST_HOST="${DEST_HOST:-127.0.0.1}"
DEST_PORT="${DEST_PORT:-5602}"
INPUT_FORMAT="${INPUT_FORMAT:-}"
ENCODER="${ENCODER:-libx264}"
EXTRA_INPUT_ARGS="${EXTRA_INPUT_ARGS:-}"
EXTRA_OUTPUT_ARGS="${EXTRA_OUTPUT_ARGS:-}"

if [ ! -e "$VIDEO_DEVICE" ]; then
  echo "Video device not found: $VIDEO_DEVICE" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is not installed" >&2
  exit 1
fi

cmd=(
  ffmpeg
  -hide_banner
  -loglevel info
  -fflags nobuffer
  -flags low_delay
  -f v4l2
)

if [ -n "$INPUT_FORMAT" ]; then
  cmd+=(-input_format "$INPUT_FORMAT")
fi

cmd+=(
  -framerate "$FPS"
  -video_size "${WIDTH}x${HEIGHT}"
)

if [ -n "$EXTRA_INPUT_ARGS" ]; then
  # shellcheck disable=SC2206
  input_args=($EXTRA_INPUT_ARGS)
  cmd+=("${input_args[@]}")
fi

cmd+=(
  -i "$VIDEO_DEVICE"
  -an
  -c:v "$ENCODER"
)

if [ "$ENCODER" = "libx264" ]; then
  cmd+=(
    -preset ultrafast
    -tune zerolatency
  )
fi

cmd+=(
  -b:v "$BITRATE"
  -maxrate "$BITRATE"
  -bufsize "$BITRATE"
  -g "$FPS"
)

if [ -n "$EXTRA_OUTPUT_ARGS" ]; then
  # shellcheck disable=SC2206
  output_args=($EXTRA_OUTPUT_ARGS)
  cmd+=("${output_args[@]}")
fi

cmd+=(
  -f rtp
  "rtp://${DEST_HOST}:${DEST_PORT}"
)

exec "${cmd[@]}"
