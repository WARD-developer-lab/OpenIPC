#!/usr/bin/env bash
set -euo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/run-tx-test.sh" >&2
  exit 1
fi

mode="${1:-test}"
video_pid=""

cleanup() {
  if [ -n "$video_pid" ] && kill -0 "$video_pid" >/dev/null 2>&1; then
    kill "$video_pid" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT INT TERM

echo "== OpenIPC TX quick test =="
echo "Preparing radio"
/opt/openipc-fpv/tx/prepare-wfb-radio.sh

echo
echo "Starting radio service"
systemctl daemon-reload
systemctl restart openipc-wfb-tx.service
sleep 2

if ! systemctl is-active --quiet openipc-wfb-tx.service; then
  echo "Radio service failed:" >&2
  systemctl status openipc-wfb-tx.service --no-pager >&2 || true
  exit 1
fi

echo "Radio service is running"
echo

case "$mode" in
  test)
    echo "Starting synthetic test video"
    /opt/openipc-fpv/tx/start-test-video.sh >/tmp/openipc-test-video.log 2>&1 &
    video_pid="$!"
    sleep 2

    if ! kill -0 "$video_pid" >/dev/null 2>&1; then
      echo "Test video failed:" >&2
      tail -40 /tmp/openipc-test-video.log >&2 || true
      exit 1
    fi

    echo
    echo "Test video is running. Watching radio packets."
    echo "PKT must become non-zero. Stop with Ctrl+C."
    journalctl -u openipc-wfb-tx.service -f --no-pager
    ;;
  camera)
    echo "Starting camera video service"
    systemctl restart openipc-video-tx.service
    sleep 2
    systemctl status openipc-video-tx.service --no-pager
    ;;
  *)
    echo "Usage: $0 [test|camera]" >&2
    exit 1
    ;;
esac
