# chip-alpine

Alpine Linux on the internal NAND of the Next Thing Co. C.H.I.P., running mainline Linux. The boot loader is U-Boot 2022.01 with the NAND patches from NextThingCo's [x-chip-uboot](https://github.com/NextThingCo/x-chip-uboot) (SLC emulation on the MLC NAND and DMA reads in the sun5i SPL), kept in `uboot/patches/`.

## Build

Requires podman.

```sh
make container
make data
make image
```

The outputs are in `build/out/`. `make data` downloads the packages of the system to `build/out/data/cache`; run it again only to refresh them.

## Host setup

Requires `sunxi-tools`.

Allow `sunxi-fel` to run without root (once):

```sh
sudo cp dev/99-chip-fel.rules /etc/udev/rules.d/
sudo udevadm control --reload
```

Your user must be in the `dialout` group, which also gives access to `/dev/ttyACM0`.

The board runs no DHCP server and its USB network interface is recreated on every boot. Give the host a persistent address, keyed on the board's fixed MAC (once):

```sh
nmcli con add type ethernet con-name chip-usb ethernet.mac-address 02:c4:1b:00:00:01 ipv4.method manual ipv4.addresses 192.168.81.2/24 ipv6.method disabled
```

Fedora's ModemManager probes `/dev/ttyACM*` and may type AT commands into the shell; stop it with `sudo systemctl stop ModemManager` while using the console.

## Flash

This erases the whole NAND.

1. Power off the C.H.I.P. and connect the FEL pin (U14 pin 7) to a GND pin.
2. Connect the micro-USB port to the host. Use only this port.
3. Run:

```sh
dev/flash-nand.sh [--hostname NAME] [--ssh-key FILE] [--wifi-ssid SSID --wifi-psk PSK]
```

`--ssh-key` is a public key file installed for root, `--hostname` defaults to `chip-alpine`, and the two Wi-Fi options go together. Run `make data` and `make image` first.

It boots Linux from RAM over FEL, formats the UBI partition, writes the FIT image to the `boot-a` and `boot-b` volumes and the system data (package cache and configuration) to the `data` volume. Then it loads U-Boot over FEL, which writes the SPL (twice) and itself to the NAND and boots `boot-a`.

4. Remove the jumper and power-cycle the board.

## How it boots

The SPL loads U-Boot, and U-Boot boots the FIT image in the UBI volume `boot-a`. If `boot-a` cannot be read or fails the FIT hash check, it boots `boot-b`. If neither boots, U-Boot stops at its prompt. A kernel that panics reboots into the same slot.

The kernel command line says which slot booted: `chip.slot=a` or `chip.slot=b` (`ram` when booted over FEL).

| NAND | Size | Content |
|---|---|---|
| `spl` at 0x0 | 4 MiB | SPL with ECC, raw |
| `spl-backup` at 0x400000 | 4 MiB | same |
| `uboot` at 0x800000 | 4 MiB | `u-boot-dtb.bin`, MLC with ECC |
| `UBI` at 0xc00000 | rest, SLC mode | UBI volumes `boot-a` and `boot-b`, 16 MiB each, holding the FIT |

Linux sees the SPL and U-Boot partitions read-only.

## First boot

The board boots a diskless Alpine Linux in RAM, with OpenRC, from the packages and configuration in the `data` volume. Log in over the USB network with the key given at flash time:

```sh
ssh root@192.168.81.1
```

or at the Wi-Fi IP if you set a network. SSH accepts keys only. The serial console on `/dev/ttyACM0` logs in as `root` without a password.

## Keeping changes

The root filesystem is in RAM, so changes are lost on reboot unless saved. `lbu commit` saves the configuration to `/media/data`; packages live in `/media/data/cache` and are installed again on every boot without network.

Add a package:

```sh
apk add PACKAGE && apk cache sync && lbu commit
```

Upgrade the system:

```sh
apk -U upgrade && apk cache sync && lbu commit
```

If a package is missing from the cache, the board still boots with the packages that are there.

## USB stick

An ext4 stick in the USB-A port can hold the data of your services. Find its UUID with `blkid`, then:

```sh
mkdir -p /media/usb
echo 'UUID=<uuid> /media/usb ext4 defaults,nofail 0 2' >> /etc/fstab
mount /media/usb
lbu commit
```

## Console

When Linux is up, the board shows a serial console on `/dev/ttyACM0` (a root shell) and a USB network interface with the board at `192.168.81.1`.

Run a command on the board from the host and get its exit status:

```sh
dev/chip-sh 'cat /proc/mtd'
```

## Status from lsusb

| `lsusb` | Board |
|---|---|
| `1f3a:efe8` | FEL mode: jumper in place, or no valid SPL on the NAND |
| `1d6b:0104` | Linux is up |
| nothing | stuck before Linux, e.g. neither boot volume boots |

## Update the boot image

With Linux up, copy a new FIT to the board and write it to a slot:

```sh
dev/chip-put build/out/chip.itb /tmp/chip.itb
dev/chip-sh 'chip-boot-write boot-b /tmp/chip.itb' 600
dev/chip-sh 'chip-boot-write boot-a /tmp/chip.itb' 600
```

`chip-boot-write` checks the readback. Writing one slot at a time keeps the other bootable.
