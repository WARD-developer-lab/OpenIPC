# OpenIPC Analog FPV Link

This repository contains the project glue for an OpenIPC/WFB-ng based FPV video link
using an analog thermal camera through a USB CVBS capture dongle.

## Target Architecture

```text
TX Radxa:
analog thermal camera -> USB CVBS capture -> /dev/videoX
  -> low-latency encoder -> RTP/UDP -> wfb-ng TX -> RTL8812AU radio

RX Radxa:
RTL8812AU radio -> OpenIPC SBC GroundStation / wfb-ng RX
  -> HDMI output first
  -> Ethernet video output later
```

## Current Direction

- RX is based on the upstream OpenIPC `sbc-groundstations` image.
- TX is custom: minimal Linux on Radxa plus camera capture, encoding, and wfb-ng TX.
- The analog camera is treated as a standard V4L2/UVC video source.

Start with [docs/architecture.md](docs/architecture.md), then use the TX and RX bring-up
checklists under [docs/](docs/).
