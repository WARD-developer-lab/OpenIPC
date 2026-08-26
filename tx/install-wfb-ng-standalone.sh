#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo /opt/openipc-fpv/tx/install-wfb-ng-standalone.sh" >&2
  exit 1
fi

workdir="${WFB_BUILD_DIR:-/opt/src/wfb-ng}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required. Run /opt/openipc-fpv/tx/install-tx-deps.sh first." >&2
  exit 1
fi

install -d "$(dirname "$workdir")"

if [ ! -d "$workdir/.git" ]; then
  git clone https://github.com/svpcom/wfb-ng.git "$workdir"
else
  git -C "$workdir" pull --ff-only
fi

make -C "$workdir" all_bin

install -m 0755 "$workdir/wfb_tx" /usr/local/bin/wfb_tx
install -m 0755 "$workdir/wfb_rx" /usr/local/bin/wfb_rx
install -m 0755 "$workdir/wfb_keygen" /usr/local/bin/wfb_keygen
install -m 0755 "$workdir/wfb_tx_cmd" /usr/local/bin/wfb_tx_cmd
install -m 0755 "$workdir/wfb_tun" /usr/local/bin/wfb_tun

if [ ! -s /etc/drone.key ] || [ ! -s /etc/gs.key ]; then
  tmpdir="$(mktemp -d)"
  (
    cd "$tmpdir"
    /usr/local/bin/wfb_keygen
    install -m 0600 drone.key /etc/drone.key
    install -m 0600 gs.key /etc/gs.key
  )
  rm -rf "$tmpdir"
fi

echo "Installed standalone wfb-ng binaries to /usr/local/bin."
echo "TX key: /etc/drone.key"
echo "Copy matching RX key to the receiver: /etc/gs.key"
