# chip-alpine

Alpine Linux on the internal NAND of the Next Thing Co. C.H.I.P., using mainline U-Boot and Linux.

Status: phase 0 — booting entirely from RAM over FEL, nothing is written to the NAND.

## Build

Requires podman.

```sh
make container
make image
```

## Boot from RAM (phase 0)

Requires `sunxi-tools` on the host.

1. Power off the C.H.I.P., connect the FEL pin (U14 pin 7) to a GND pin.
2. Connect the micro-USB port to the host.
3. `sudo dev/fel-boot-ram.sh`
4. A serial console shows up as `/dev/ttyACM0` and a USB network interface with the board at `192.168.81.1`.
