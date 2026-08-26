# RX Bring-Up Checklist

RX should start from the upstream OpenIPC SBC GroundStation image for Radxa Zero 3W/E.

## Flashing

Use the image from:

```text
https://github.com/OpenIPC/sbc-groundstations/releases
```

For the first target, use the Radxa Zero 3W/E image described by the OpenIPC
GroundStation documentation.

## Config Partition

After flashing, reinsert the SD card into Windows and open the `config` partition.
Edit:

```text
setup.txt
```

Known beta 2 style:

```ini
[screen mode]
screen_mode = 1280x720@60

[dvr recording]
rec_fps = 60

[gpio]
gpio_layout = Ruby

[msposd]
osd = air
```

Use `1920x1080@60` if the display does not accept 720p.

## First Boot

Connect:

- HDMI display;
- RTL8812AU WiFi adapter with antennas;
- stable 5 V power.

Expected result without TX:

- boot screen, menu, OSD, or no-video waiting state;
- no normal desktop environment.

If HDMI shows `No signal`, test:

- another HDMI mode in `setup.txt`;
- another HDMI cable/display;
- boot without the WiFi adapter to remove power load;
- Ethernet or gadget mode if available for logs.
