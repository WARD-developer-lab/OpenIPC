# Architecture

## Goal

Build a digital FPV video link on OpenIPC/WFB-ng while keeping the camera side compatible
with an analog thermal camera. The analog camera is digitized by a USB CVBS capture device
and handled as a Linux V4L2 video input.

## Roles

### TX: custom Radxa transmitter

The TX Radxa is responsible for:

- detecting the USB CVBS capture device as `/dev/videoX`;
- reading video through V4L2;
- encoding the stream with low latency;
- sending RTP/UDP video to the local wfb-ng TX input port;
- starting all services automatically at boot.

Initial TX video flow:

```text
/dev/video0 -> ffmpeg/gstreamer -> udp://127.0.0.1:5602 -> wfb-ng TX -> WiFi radio
```

The repository starts with an `ffmpeg` software encoder because it is easy to validate on
almost any Linux image. Once the Radxa hardware is available, the TX can be upgraded to a
Rockchip MPP/GStreamer hardware encoder profile if the installed image exposes it.

### RX: OpenIPC GroundStation

The RX Radxa should use the upstream OpenIPC SBC GroundStation image. It already contains
the ground-station side of the WFB/OpenIPC stack and is intended to receive video from an
OpenIPC/WFB transmitter.

Initial RX output:

```text
WiFi radio -> wfb-ng RX -> HDMI display
```

Later RX output:

```text
WiFi radio -> wfb-ng RX -> Ethernet UDP/RTSP/SRT output
```

## Synchronization Model

The radios are not paired like Bluetooth and do not join a normal WiFi access point. Both
sides must be configured with the same radio parameters and WFB keys:

- WiFi channel/frequency;
- channel width;
- wfb-ng key material;
- video port;
- FEC settings;
- compatible video codec and payload format.

The TX continuously broadcasts encoded packets. RX listens on the same channel, validates
the WFB stream, reconstructs packets with FEC where possible, and forwards the resulting
video stream to HDMI or Ethernet.

## Open Questions For Hardware Bring-Up

- Exact USB capture chipset and supported formats.
- Exact Realtek chipset: RTL8812AU, RTL8812EU, RTL8812BU, or another variant.
- Whether the selected Radxa image has working Rockchip hardware encoding.
- Practical latency with USB CVBS capture and software vs hardware encoding.

## First Radio Target

Use conservative parameters first:

- 5 GHz channel 161;
- 20 MHz bandwidth;
- MCS 1;
- STBC enabled where the driver supports it;
- 720x576 or 640x480 at 25/30 fps from CVBS;
- 2.5 Mbit/s video bitrate.

After the link is stable on the bench, raise bitrate, channel width, or frame rate one
parameter at a time.
