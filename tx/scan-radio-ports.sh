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
echo "Each port will run for ${seconds}s."
echo "The scan repeats forever. Watch RX and stop with Ctrl+C when it works."

cycle=1

while true; do
  for port in "${ports[@]}"; do
    echo
    echo "============================================================"
    echo "Cycle ${cycle}: testing WFB radio port ${port}"
    echo "============================================================"

    if [ -f /etc/default/wifibroadcast ]; then
      if grep -q '^WFB_RADIO_PORT=' /etc/default/wifibroadcast; then
        sed -i "s/^WFB_RADIO_PORT=.*/WFB_RADIO_PORT=\"${port}\"/" /etc/default/wifibroadcast
      else
        printf '\nWFB_RADIO_PORT="%s"\n' "$port" >> /etc/default/wifibroadcast
      fi
    fi

    systemctl stop openipc-tx-test-link.service >/dev/null 2>&1 || true
    systemctl stop openipc-wfb-tx.service >/dev/null 2>&1 || true
    systemctl reset-failed openipc-tx-test-link.service >/dev/null 2>&1 || true
    systemctl reset-failed openipc-wfb-tx.service >/dev/null 2>&1 || true

    TX_AUTOSTART_RADIO_PORT="$port" timeout --foreground "${seconds}" /opt/openipc-fpv/tx/start-tx-test-link.sh test || status="$?"
    status="${status:-0}"

    if [ "$status" != "124" ] && [ "$status" != "130" ] && [ "$status" != "143" ] && [ "$status" != "0" ]; then
      echo "Port ${port} test exited with status ${status}; continuing."
    fi
    unset status
  done

  cycle=$((cycle + 1))
done
