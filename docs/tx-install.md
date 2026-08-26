# TX Installation

This page describes the custom transmitter role for Radxa.

## Base OS

Use a minimal Debian/Radxa OS image first. Avoid a full desktop image unless it is the only
image that boots reliably on the board.

## Install

Clone the project and run:

```bash
cd OpenIPC
sudo ./tx/install-tx.sh
```

If packages are missing:

```bash
sudo /opt/openipc-fpv/tx/install-tx-deps.sh
```

Do not install GStreamer development packages on the Radxa Bullseye image unless we are
specifically building the full RTSP-enabled wfb-ng Debian package. The first TX path uses
`ffmpeg` and standalone `wfb_tx`, so those packages are unnecessary.

## Configure Camera

Edit:

```bash
sudo nano /etc/default/openipc-video-tx
```

Default CVBS settings:

```bash
VIDEO_DEVICE=/dev/video0
WIDTH=720
HEIGHT=576
FPS=25
BITRATE=2500k
DEST_HOST=127.0.0.1
DEST_PORT=5602
ENCODER=libx264
```

For NTSC CVBS, try:

```bash
WIDTH=720
HEIGHT=480
FPS=30
```

## Configure Radio Interface

Find the radio interface:

```bash
ip -brief link
iw dev
```

Then dedicate it to wfb-ng:

```bash
sudo /opt/openipc-fpv/tx/configure-wfb-interface.sh wlan1
```

Use the real interface name instead of `wlan1`.

## Configure wfb-ng

The installer creates `/etc/wifibroadcast.cfg` only if it does not already exist.
The important TX section is:

```ini
[drone_video]
peer = 'listen://0.0.0.0:5602'
```

Generate one matching key pair and distribute it correctly:

```bash
wfb_keygen
sudo cp drone.key /etc/drone.key
```

Copy the matching `gs.key` to the RX side.

## Preflight

Run:

```bash
sudo /opt/openipc-fpv/tx/tx-preflight.sh
```

Do not start the link until the preflight sees:

- camera device;
- Realtek WiFi adapter;
- `/etc/drone.key`;
- `/etc/wifibroadcast.cfg`;
- `wfb_tx` or `wifibroadcast@.service`.

## Start

```bash
sudo systemctl enable --now openipc-video-tx.service
sudo systemctl enable --now openipc-wfb-tx.service
```

Logs:

```bash
journalctl -u openipc-video-tx.service -f
journalctl -u openipc-wfb-tx.service -f
```
