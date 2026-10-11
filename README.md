# chip-alpine

Alpine Linux on the internal NAND of the Next Thing Co. C.H.I.P., using mainline U-Boot and Linux.

Status: phase 2 — boots on its own from the NAND, with A/B boot slots.

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
3. `make fel-boot` (loads the FIT, `build/out/chip.itb`, into RAM)
4. A serial console shows up as `/dev/ttyACM0` and a USB network interface with the board at `192.168.81.1`.

Host notes:

- The board runs no DHCP server: give the host's new USB network interface `192.168.81.2/24`, e.g. `sudo ip addr add 192.168.81.2/24 dev <iface>`.
- Fedora's ModemManager probes `/dev/ttyACM*` and may type AT commands into the shell; stop it with `sudo systemctl stop ModemManager` while using the console.

Where the board is, from `lsusb`:

| `lsusb` | Board |
|---|---|
| `1f3a:efe8` | FEL mode: jumper in place, or no valid SPL on the NAND |
| `1f3a:1010` | U-Boot rescue console on `/dev/ttyACM0`: no boot slot booted |
| `1d6b:0104` | Linux is up |
| nothing | stuck in the SPL or U-Boot |

While the FEL jumper is in, a failed boot from RAM puts the board back in FEL mode.

Run a command on the board from the host and get its exit status:

```sh
dev/chip-sh 'cat /proc/mtd'
```

## NAND stress test (phase 1)

Erases the UBI partition. Start with the board in FEL mode (jumper in place).

```sh
dev/nand-cycles.sh 1000
dev/nand-powercut.sh 10
```

`nand-cycles.sh` runs unattended: each cycle writes 50 MiB, drops the page cache and verifies the data, logging ECC statistics.
`nand-powercut.sh` asks you to cut and restore power with the hub port button while the board is writing, then checks that every file synced before the cut is intact.
Logs go to `build/logs/`.

## Boot from the NAND (phase 2)

Overwrites the boot slots, the SPL and U-Boot. Start with the board in FEL mode (jumper in place) and the host's USB network interface at `192.168.81.2/24`.

```sh
dev/flash-nand.sh
```

Linux, booted from RAM, writes the FIT to `boot-a` and `boot-b` and checks the readback; then U-Boot, loaded over FEL, writes the SPL (twice) and itself.
Power off, remove the jumper and power on: U-Boot boots `boot-a`, falls back to `boot-b`, and opens a USB serial console if neither boots.
The kernel command line says which slot booted: `chip.slot=a`, `b` or `ram`.

Boot tests, with the jumper removed and Linux up:

```sh
dev/boot-fallback.sh
dev/boot-loop.sh 50
dev/cold-boots.sh 5
```

To go back to FEL mode, put the jumper back and power-cycle.
