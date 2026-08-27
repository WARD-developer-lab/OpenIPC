#!/usr/bin/env bash
set -euo pipefail

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/prepare-wfb-radio.sh [iface]" >&2
  exit 1
fi

if [ -f /etc/default/wifibroadcast ]; then
  # shellcheck disable=SC1091
  . /etc/default/wifibroadcast
fi

iface="${1:-${WFB_NICS:-}}"
iface="${iface%% *}"
channel="${WFB_CHANNEL:-161}"
channel_mode="${WFB_CHANNEL_MODE:-HT20}"

if [ -z "$iface" ]; then
  iface="$(iw dev 2>/dev/null | awk '/Interface/ {print $2; exit}')"
fi

if [ -z "$iface" ]; then
  echo "No WiFi interface found. Plug in the RTL8812AU adapter and retry." >&2
  exit 1
fi

if ! command -v iw >/dev/null 2>&1; then
  echo "Missing iw command. Install package: sudo apt install -y iw" >&2
  exit 1
fi

stop_wifi_managers() {
  systemctl stop openipc-wfb-tx.service >/dev/null 2>&1 || true
  systemctl stop NetworkManager.service >/dev/null 2>&1 || true
  systemctl stop wpa_supplicant.service >/dev/null 2>&1 || true
  systemctl stop dhcpcd.service >/dev/null 2>&1 || true
  systemctl stop networking.service >/dev/null 2>&1 || true
  pkill -x NetworkManager >/dev/null 2>&1 || true
  pkill -x wpa_supplicant >/dev/null 2>&1 || true
  pkill -x dhclient >/dev/null 2>&1 || true
  pkill -x dhcpcd >/dev/null 2>&1 || true
}

get_phy() {
  local dev="$1"
  local phy_path=""

  phy_path="$(readlink -f "/sys/class/net/${dev}/phy80211" 2>/dev/null || true)"
  if [ -n "$phy_path" ]; then
    basename "$phy_path"
    return 0
  fi

  iw dev "$dev" info 2>/dev/null | awk '/wiphy/ {print "phy"$2; exit}'
}

echo "Preparing $iface for wfb-ng TX"
stop_wifi_managers

phy="$(get_phy "$iface")"
if [ -z "$phy" ]; then
  echo "Could not find physical radio for $iface." >&2
  exit 1
fi

ip link set "$iface" down >/dev/null 2>&1 || true
iw dev "$iface" del >/dev/null 2>&1 || true
sleep 1

if ip link show "$iface" >/dev/null 2>&1; then
  echo "Could not delete $iface. Unplug/replug the WiFi adapter and retry." >&2
  exit 1
fi

iw phy "$phy" interface add "$iface" type monitor
ip link set "$iface" up
iw dev "$iface" set channel "$channel" "$channel_mode"

if [ -f /etc/default/wifibroadcast ]; then
  if grep -q '^WFB_NICS=' /etc/default/wifibroadcast; then
    sed -i "s/^WFB_NICS=.*/WFB_NICS=\"${iface}\"/" /etc/default/wifibroadcast
  else
    printf '\nWFB_NICS="%s"\n' "$iface" >> /etc/default/wifibroadcast
  fi
fi

echo "Radio ready:"
iw dev "$iface" info | sed 's/^/  /'
