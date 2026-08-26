# TX Bring-Up Checklist

This is the transmitter path for the analog thermal camera.

## Hardware

Connect:

- Radxa board with minimal Linux;
- stable 5 V power supply;
- USB CVBS capture device;
- analog thermal camera with its own required power;
- RTL8812AU WiFi adapter with antennas attached.

## First Boot Checks

Run:

```bash
lsusb
ls /dev/video*
ip link
```

Expected:

- one Realtek WiFi adapter in `lsusb`;
- one USB video/capture device in `lsusb`;
- at least one `/dev/videoX`.

If available, inspect camera formats:

```bash
v4l2-ctl --list-devices
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

## Local Video Test

Before radio transmission, prove that the camera can be opened:

```bash
ffplay -fflags nobuffer -flags low_delay -framedrop /dev/video0
```

If `/dev/video0` is not the capture device, use the output from `v4l2-ctl --list-devices`
to select the correct device.

## TX Pipeline Goal

The TX service should eventually produce an RTP/UDP stream for wfb-ng:

```text
/dev/videoX -> low-latency H.264/H.265 encoder -> 127.0.0.1:5602
```

The first software encoder prototype is in:

```text
tx/start-video-tx.sh
```

## Install The TX Layer

Clone this repository on the TX Radxa and run:

```bash
sudo ./tx/install-tx.sh
```

The installer copies scripts to `/opt/openipc-fpv/tx`, installs systemd units, writes an
example `/etc/default/openipc-video-tx`, and writes a conservative drone-side
`/etc/wifibroadcast.cfg` if one does not already exist.

Before enabling the service, inspect:

```bash
sudo nano /etc/default/openipc-video-tx
sudo nano /etc/wifibroadcast.cfg
sudo nano /etc/default/wifibroadcast
```

Then run the preflight:

```bash
sudo /opt/openipc-fpv/tx/tx-preflight.sh
```

Enable:

```bash
sudo systemctl enable --now openipc-video-tx.service
sudo systemctl enable --now openipc-wfb-tx.service
```

Follow logs:

```bash
journalctl -u openipc-video-tx.service -f
journalctl -u openipc-wfb-tx.service -f
```

## Expected Ports

The local encoder sends RTP video to:

```text
127.0.0.1:5602
```

wfb-ng drone mode listens on the same port through:

```ini
[drone_video]
peer = 'listen://0.0.0.0:5602'
```
