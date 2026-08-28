#!/usr/bin/env bash
set -euo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

mode="${1:-${TX_AUTOSTART_MODE:-test}}"
radio_pid=""
video_pid=""

cleanup() {
  if [ -n "$video_pid" ] && kill -0 "$video_pid" >/dev/null 2>&1; then
    kill "$video_pid" >/dev/null 2>&1 || true
  fi
  if [ -n "$radio_pid" ] && kill -0 "$radio_pid" >/dev/null 2>&1; then
    kill "$radio_pid" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT INT TERM

echo "Starting OpenIPC TX link in $mode mode"
/opt/openipc-fpv/tx/prepare-wfb-radio.sh

echo "Starting wfb_tx"
/opt/openipc-fpv/tx/start-wfb-tx.sh &
radio_pid="$!"
sleep 2

if ! kill -0 "$radio_pid" >/dev/null 2>&1; then
  echo "wfb_tx exited during startup" >&2
  wait "$radio_pid"
fi

case "$mode" in
  test)
    echo "Starting synthetic test video"
    /opt/openipc-fpv/tx/start-test-video.sh &
    video_pid="$!"
    ;;
  camera)
    echo "Starting CVBS/camera video"
    /opt/openipc-fpv/tx/start-video-tx.sh &
    video_pid="$!"
    ;;
  *)
    echo "Usage: $0 [test|camera]" >&2
    exit 1
    ;;
esac

wait "$radio_pid" "$video_pid"
