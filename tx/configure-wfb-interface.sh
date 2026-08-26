#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/configure-wfb-interface.sh wlanX" >&2
  exit 1
fi

iface="${1:-}"

if [ -z "$iface" ]; then
  echo "Usage: $0 wlanX" >&2
  ip -brief link || true
  exit 1
fi

if ! ip link show "$iface" >/dev/null 2>&1; then
  echo "Interface not found: $iface" >&2
  ip -brief link || true
  exit 1
fi

if [ -f /etc/default/wifibroadcast ]; then
  if grep -q '^WFB_NICS=' /etc/default/wifibroadcast; then
    sed -i "s/^WFB_NICS=.*/WFB_NICS=\"${iface}\"/" /etc/default/wifibroadcast
  else
    printf '\nWFB_NICS="%s"\n' "$iface" >> /etc/default/wifibroadcast
  fi
fi

if [ -d /etc/NetworkManager/conf.d ]; then
  cat > /etc/NetworkManager/conf.d/99-openipc-wfb-unmanaged.conf <<EOF
[keyfile]
unmanaged-devices=interface-name:${iface}
EOF
  systemctl reload NetworkManager 2>/dev/null || true
fi

if [ -f /etc/dhcpcd.conf ] && ! grep -q "denyinterfaces ${iface}" /etc/dhcpcd.conf; then
  printf '\ndenyinterfaces %s\n' "$iface" >> /etc/dhcpcd.conf
fi

ip link set "$iface" down || true

echo "Configured $iface for wfb-ng use."
echo "Reboot before starting the radio link if NetworkManager or dhcpcd was active."
