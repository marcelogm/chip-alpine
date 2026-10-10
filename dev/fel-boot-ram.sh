#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

if ! sunxi-fel -l | grep -q .; then
	echo "no C.H.I.P. in FEL mode found: jumper FEL to GND and reconnect the micro-USB" >&2
	exit 1
fi

sunxi-fel -v -p \
	uboot build/out/u-boot-sunxi-with-spl.bin \
	write 0x42000000 build/out/chip-ram.itb
