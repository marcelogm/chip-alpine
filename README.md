# chip-alpine

Alpine Linux on the internal NAND of the Next Thing Co. C.H.I.P., using U-Boot 2022.01 with NextThingCo's NAND patches and mainline Linux.

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

- The board runs no DHCP server and its USB network interface is recreated on every boot. Give the host a persistent address, keyed on the board's fixed MAC (once):

  ```sh
  nmcli con add type ethernet con-name chip-usb ethernet.mac-address 02:c4:1b:00:00:01 ipv4.method manual ipv4.addresses 192.168.81.2/24 ipv6.method disabled
  ```

- Fedora's ModemManager probes `/dev/ttyACM*` and may type AT commands into the shell; stop it with `sudo systemctl stop ModemManager` while using the console.

Where the board is, from `lsusb`:

| `lsusb` | Board |
|---|---|
| `1f3a:efe8` | FEL mode: jumper in place, or no valid SPL on the NAND |
| `1d6b:0104` | Linux is up |
| nothing | stuck in the SPL or U-Boot, e.g. neither boot volume boots |

While the FEL jumper is in, a failed boot from RAM puts the board back in FEL mode.

Run a command on the board from the host and get its exit status:

```sh
dev/chip-sh 'cat /proc/mtd'
```

## NAND stress test (phase 1)

Erases the UBI partition, boot volumes included: run `dev/flash-nand.sh` again afterwards to boot from the NAND. Start with the board in FEL mode (jumper in place).

```sh
dev/nand-cycles.sh 1000
dev/nand-powercut.sh 10
```

`nand-cycles.sh` runs unattended: each cycle writes 50 MiB, drops the page cache and verifies the data, logging ECC statistics.
`nand-powercut.sh` asks you to cut and restore power with the hub port button while the board is writing, then checks that every file synced before the cut is intact.
Logs go to `build/logs/`.

## Boot from the NAND (phase 2)

The NAND boot chain is NextThingCo's, from [x-chip-uboot](https://github.com/NextThingCo/x-chip-uboot): U-Boot 2022.01 with their patches for SLC emulation on the MLC NAND and for the sun5i SPL's DMA reads, in `uboot/patches/`.

| NAND | Size | Content |
|---|---|---|
| `spl` at 0x0 | 4 MiB | SPL with ECC, raw |
| `spl-backup` at 0x400000 | 4 MiB | same |
| `uboot` at 0x800000 | 4 MiB | `u-boot-dtb.bin`, MLC with ECC |
| `UBI` at 0xc00000 | rest, SLC mode | UBI volumes `boot-a` and `boot-b`, 16 MiB each, holding the FIT |

Linux sees the SPL and U-Boot partitions read-only.

Overwrites the whole NAND. Start with the board in FEL mode (jumper in place) and the `chip-usb` NetworkManager profile in place (see the host notes above).

```sh
dev/flash-nand.sh
```

Linux, booted from RAM, formats `UBI`, creates `boot-a` and `boot-b` and writes the FIT to both, checking the readback.
The board then reboots into FEL, and U-Boot, loaded over FEL, writes the SPL twice and itself to the NAND and boots `boot-a` from UBI, which checks the whole chain.
Power off, remove the jumper and power on: the SPL loads U-Boot, and U-Boot boots the FIT in `boot-a`, or the one in `boot-b` when `boot-a` cannot be read or fails its FIT hash check.
When neither boots, U-Boot stops at its prompt.
A kernel that panics reboots into the same slot (there is no boot counter yet).
The kernel command line says which slot booted: `chip.slot=a`, `b` or `ram`.

Boot tests, with the jumper removed and Linux up:

```sh
dev/boot-fallback.sh
dev/boot-loop.sh 50
dev/cold-boots.sh 5
```

`boot-fallback.sh` empties `boot-a`, then writes a FIT with a corrupt kernel to it, expecting `boot-b` both times, and restores it.

To go back to FEL mode, put the jumper back and power-cycle.
