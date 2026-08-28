#!/usr/bin/env bash
set -euo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/scan-radio-ports.sh [seconds] [ports...]" >&2
  exit 1
fi

seconds="${1:-30}"
shift || true

if ! [[ "$seconds" =~ ^[0-9]+$ ]]; then
  echo "First argument must be seconds, for example: $0 30 0 1 2 3" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  ports=("$@")
else
  ports=(0 1 2 3 4 5)
fi

echo "Scanning WFB radio ports: ${ports[*]}"
echo "Each port will run for ${seconds}s. Watch RX and stop with Ctrl+C when it works."

for port in "${ports[@]}"; do
  echo
  echo "============================================================"
  echo "Testing WFB radio port ${port}"
  echo "============================================================"

  if [ -f /etc/default/wifibroadcast ]; then
    if grep -q '^WFB_RADIO_PORT=' /etc/default/wifibroadcast; then
      sed -i "s/^WFB_RADIO_PORT=.*/WFB_RADIO_PORT=\"${port}\"/" /etc/default/wifibroadcast
    else
      printf '\nWFB_RADIO_PORT="%s"\n' "$port" >> /etc/default/wifibroadcast
    fi
  fi

  timeout --foreground "${seconds}" /opt/openipc-fpv/tx/run-tx-test.sh test "$port" || status="$?"
  status="${status:-0}"

  if [ "$status" != "124" ] && [ "$status" != "130" ] && [ "$status" != "143" ] && [ "$status" != "0" ]; then
    echo "Port ${port} test exited with status ${status}; continuing."
  fi
  unset status
done

echo
echo "Scan finished. If RX never woke up, the issue is probably not radio port."
