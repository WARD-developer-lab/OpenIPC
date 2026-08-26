# Hardware Notes

## Required System Parts

- Two Radxa Zero 3E/3W class boards.
- Two RTL8812AU-class WiFi adapters with antennas.
- One analog thermal camera.
- One USB CVBS capture device for the TX side.
- Stable 5 V power for each Radxa.
- HDMI display for first RX testing.

## Antennas

Do not power the WiFi adapters for transmission without antennas. If the adapter exposes
ports marked `TX`, `RX`, and `T/R`, use antennas on `TX` and `T/R` at minimum. Use all
three when available.

## Analog Camera Handling

The analog camera is not an OpenIPC camera. The TX sees it only after the USB CVBS capture
device converts CVBS into a V4L2 video node such as `/dev/video0`.

For Linux, the useful abstraction is:

```text
USB CVBS capture == webcam-like V4L2 source
```
