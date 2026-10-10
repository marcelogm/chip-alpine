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

Host notes:

- The board runs no DHCP server: give the host's new USB network interface `192.168.81.2/24`, e.g. `sudo ip addr add 192.168.81.2/24 dev <iface>`.
- Fedora's ModemManager probes `/dev/ttyACM*` and may type AT commands into the shell; stop it with `sudo systemctl stop ModemManager` while using the console.

Status signals while the FEL jumper is in:

- LED off: U-Boot or early kernel.
- LED blinking: kernel running.
- LED solid: USB console ready.
- Board back in FEL mode (`lsusb` shows `1f3a:efe8`): boot failed. Within seconds means U-Boot or FIT; about 10 s after the blinking started means kernel panic.
