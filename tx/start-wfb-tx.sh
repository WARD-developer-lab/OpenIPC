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
WFB_CHANNEL_MODE="${WFB_CHANNEL_MODE:-HT20}"

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

stop_wifi_managers() {
  systemctl stop NetworkManager.service >/dev/null 2>&1 || true
  systemctl stop wpa_supplicant.service >/dev/null 2>&1 || true
  systemctl stop dhcpcd.service >/dev/null 2>&1 || true
  systemctl stop networking.service >/dev/null 2>&1 || true
  pkill -x NetworkManager >/dev/null 2>&1 || true
  pkill -x wpa_supplicant >/dev/null 2>&1 || true
  pkill -x dhclient >/dev/null 2>&1 || true
  pkill -x dhcpcd >/dev/null 2>&1 || true
}

set_monitor_mode() {
  local iface="$1"
  local current_type=""

  current_type="$(iw dev "$iface" info 2>/dev/null | awk '/type/ {print $2; exit}')"
  if [ "$current_type" = "monitor" ]; then
    return 0
  fi

  ip link set "$iface" nomaster >/dev/null 2>&1 || true
  ip addr flush dev "$iface" >/dev/null 2>&1 || true
  ip link set "$iface" down || true
  sleep 1

  if iw dev "$iface" set monitor otherbss; then
    return 0
  fi

  stop_wifi_managers
  ip link set "$iface" down || true
  sleep 2

  if iw dev "$iface" set monitor otherbss; then
    return 0
  fi

  if command -v iwconfig >/dev/null 2>&1; then
    iwconfig "$iface" mode monitor
    return 0
  fi

  return 1
}

for iface in $WFB_NICS; do
  echo "Preparing $iface for wfb-ng TX"

  if command -v rfkill >/dev/null 2>&1; then
    rfkill unblock wifi || true
  fi

  if command -v nmcli >/dev/null 2>&1; then
    nmcli device set "$iface" managed no >/dev/null 2>&1 || true
    nmcli device disconnect "$iface" >/dev/null 2>&1 || true
  fi

  systemctl stop "wpa_supplicant@${iface}.service" >/dev/null 2>&1 || true
  stop_wifi_managers

  if ! set_monitor_mode "$iface"; then
    echo "Could not switch $iface to monitor mode. It may still be busy." >&2
    echo "Try unplugging/replugging the WiFi adapter, then start this service again." >&2
    exit 1
  fi

  iw dev "$iface" set channel "$WFB_CHANNEL" "$WFB_CHANNEL_MODE"
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
