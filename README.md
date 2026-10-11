# chip-alpine

Alpine Linux for the internal NAND of the Next Thing Co. C.H.I.P., on mainline Linux. The system is diskless: every boot installs it into RAM from a package cache and a saved configuration on the NAND, so it boots the same way every time and you keep changes with `lbu commit`. The boot loader is U-Boot 2022.01 with the NAND patches from NextThingCo's [x-chip-uboot](https://github.com/NextThingCo/x-chip-uboot) (SLC emulation on the MLC NAND and DMA reads in the SPL).

## What you need

- A C.H.I.P.
- A micro-USB data cable to a Linux PC.
- A jumper wire, to put the board in FEL mode.
- A good power supply. The board can brown out on a weak USB hub port once Wi-Fi is up.
- `sunxi-tools` (for `sunxi-fel`) and `python3` on the PC.

## Flash

### 1. Download

Download `chip-alpine-<version>.tar.gz` and `chip-alpine-<version>.tar.gz.sha256` from the [latest release](https://github.com/marcelogm/chip-alpine/releases/latest), then:

```sh
sha256sum -c chip-alpine-<version>.tar.gz.sha256
tar -xzf chip-alpine-<version>.tar.gz
cd chip-alpine-<version>
```

Run the commands below from this directory.

### 2. Set up the PC (once)

Let `sunxi-fel` reach the board without root:

```sh
sudo cp flash/99-chip-fel.rules /etc/udev/rules.d/
sudo udevadm control --reload
```

Your user must be in the `dialout` group, which also gives access to the board's console on `/dev/ttyACM0`:

```sh
sudo usermod -aG dialout "$USER"
```

Log out and back in for it to apply.

The board is `192.168.81.1` on its USB network and runs no DHCP server. Give the PC a fixed address there, keyed on the board's fixed MAC:

```sh
nmcli con add type ethernet con-name chip-usb ethernet.mac-address 02:c4:1b:00:00:01 ipv4.method manual ipv4.addresses 192.168.81.2/24 ipv6.method disabled
```

ModemManager probes `/dev/ttyACM*` and may type AT commands into the board's shell. Stop it while flashing:

```sh
sudo systemctl stop ModemManager
```

### 3. Choose the settings

```sh
flash/flash-setup.sh
```

It asks for the hostname (default `chip-alpine`), the SSH public key to authorize for root, and a Wi-Fi network and its password (optional), and saves them to `~/.config/chip-alpine/flash.conf`, readable only by you.

SSH accepts keys only. If you have no key for the board, create one first; `flash/flash-setup.sh` then offers it as the default:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/chip_ed25519
```

### 4. Flash the NAND

This erases the whole NAND.

1. Power off the board and connect the FEL pin (U14 pin 7) to a GND pin with the jumper wire.
2. Connect the board's micro-USB port to the PC.
3. Run:

```sh
flash/flash-nand.sh
```

It boots Linux from RAM over USB, writes the system to the NAND, then writes U-Boot, and ends with `done`.

`flash/flash-nand.sh --print-settings` shows the settings it will use without touching the board. `--hostname NAME`, `--ssh-key FILE`, `--wifi-ssid SSID --wifi-psk PSK` override the saved settings, and `--config FILE` reads another settings file.

### 5. Boot

Remove the jumper and power-cycle the board.

### 6. Log in

The first boot takes about a minute. Log in over Wi-Fi, at the address your router gave the board:

```sh
ssh -i ~/.ssh/chip_ed25519 root@<wifi ip>
```

or over the USB cable:

```sh
ssh -i ~/.ssh/chip_ed25519 root@192.168.81.1
```

The console on `/dev/ttyACM0` (`screen /dev/ttyACM0 115200`) logs in as `root` without a password.

The SSH host keys change on every boot until you save them. After the first login, run once:

```sh
lbu commit
```

## Using it

The root filesystem lives in RAM: changes are lost on reboot unless you save them with `lbu commit`, which writes the configuration to `/media/data` on the NAND. Packages are kept in `/media/data/cache` and installed again on every boot, without network.

Add a package:

```sh
apk add PACKAGE && apk cache sync && lbu commit
```

Upgrade the system:

```sh
apk -U upgrade && apk cache sync && lbu commit
```

### USB stick

An ext4 stick in the USB-A port can hold the data of your services. Find its UUID with `blkid`, then:

```sh
mkdir -p /media/usb
echo 'UUID=<uuid> /media/usb ext4 defaults,nofail 0 0' >> /etc/fstab
mount /media/usb
lbu commit
```

### Boot slots

U-Boot boots the system image in the `boot-a` volume and falls back to `boot-b` when `boot-a` cannot be read or fails its hash check.
`chip-boot-write boot-a IMAGE` on the board writes a new image to one slot and checks it, so the other slot stays bootable.

### Rescue

With the FEL jumper in place and the micro-USB connected, `flash/fel-boot-ram.sh` boots Linux from RAM without touching the NAND, with a root shell on `/dev/ttyACM0`.

## Build from source

Requires podman.

```sh
make container data image
make test
make release
```

The build outputs are in `build/out/`, and `flash/flash-nand.sh` flashes them from the source tree as well. `make release` bundles them in `build/release/chip-alpine-<version>.tar.gz`.

## License

GPL-2.0, see `LICENSE`.
