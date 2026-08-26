#!/usr/bin/env bash
set -euo pipefail

if [ -f /etc/default/wifibroadcast ]; then
  # shellcheck disable=SC1091
  . /etc/default/wifibroadcast
fi

WFB_NICS="${WFB_NICS:-}"
WFB_KEY="${WFB_KEY:-/etc/drone.key}"
WFB_UDP_PORT="${WFB_UDP_PORT:-5602}"
WFB_RADIO_PORT="${WFB_RADIO_PORT:-0}"
WFB_CHANNEL="${WFB_CHANNEL:-161}"
WFB_BANDWIDTH="${WFB_BANDWIDTH:-20}"
WFB_GI="${WFB_GI:-long}"
WFB_STBC="${WFB_STBC:-1}"
WFB_LDPC="${WFB_LDPC:-0}"
WFB_MCS="${WFB_MCS:-1}"

if [ -z "$WFB_NICS" ]; then
  echo "WFB_NICS is empty. Edit /etc/default/wifibroadcast." >&2
  exit 1
fi

if [ ! -s "$WFB_KEY" ]; then
  echo "Missing WFB key: $WFB_KEY" >&2
  exit 1
fi

if ! command -v wfb_tx >/dev/null 2>&1; then
  echo "wfb_tx is not installed. Run /opt/openipc-fpv/tx/install-wfb-ng-standalone.sh" >&2
  exit 1
fi

for iface in $WFB_NICS; do
  ip link set "$iface" down || true
  iw dev "$iface" set type monitor
  iw dev "$iface" set channel "$WFB_CHANNEL" HT20
  ip link set "$iface" up
done

exec wfb_tx \
  -K "$WFB_KEY" \
  -u "$WFB_UDP_PORT" \
  -p "$WFB_RADIO_PORT" \
  -B "$WFB_BANDWIDTH" \
  -G "$WFB_GI" \
  -S "$WFB_STBC" \
  -L "$WFB_LDPC" \
  -M "$WFB_MCS" \
  $WFB_NICS
