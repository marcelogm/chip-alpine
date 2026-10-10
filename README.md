# chip-alpine

Alpine Linux on the internal NAND of the Next Thing Co. C.H.I.P., using mainline U-Boot and Linux.

Status: phase 1 — boots from RAM over FEL; Linux writes UBI to the NAND in SLC mode.

## Build

Requires podman.

```sh
make container
make image
```

## Boot from RAM (phase 0)

Requires `sunxi-tools` on the host.

Allow `sunxi-fel` to run without root (once):

```sh
sudo cp dev/99-chip-fel.rules /etc/udev/rules.d/
sudo udevadm control --reload
```

Your user must be in the `dialout` group, which also gives access to `/dev/ttyACM0`.

1. Power off the C.H.I.P., connect the FEL pin (U14 pin 7) to a GND pin.
2. Connect the micro-USB port to the host.
3. `make fel-boot`
4. A serial console shows up as `/dev/ttyACM0` and a USB network interface with the board at `192.168.81.1`.

Host notes:

- The board runs no DHCP server: give the host's new USB network interface `192.168.81.2/24`, e.g. `sudo ip addr add 192.168.81.2/24 dev <iface>`.
- Fedora's ModemManager probes `/dev/ttyACM*` and may type AT commands into the shell; stop it with `sudo systemctl stop ModemManager` while using the console.

Status signals while the FEL jumper is in:

- LED off: U-Boot or early kernel.
- LED blinking: kernel running.
- LED solid: USB console ready.
- Board back in FEL mode (`lsusb` shows `1f3a:efe8`): boot failed. Within seconds means U-Boot or FIT; about 10 s after the blinking started means kernel panic.

Run a command on the board from the host and get its exit status:

```sh
dev/chip-sh 'cat /proc/mtd'
```

## NAND stress test (phase 1)

Erases the UBI partition. Start with the board in FEL mode (jumper in place).

```sh
dev/nand-cycles.sh 1000
dev/nand-powercut.sh 30
```

`nand-cycles.sh` runs unattended: each cycle writes 50 MiB, drops the page cache and verifies the data, logging ECC statistics.
`nand-powercut.sh` asks you to cut and restore power with the hub port button while the board is writing, then checks that every file synced before the cut is intact.
Logs go to `build/logs/`.
