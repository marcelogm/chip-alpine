#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

exec flash/fel-run.sh \
	uboot build/out/u-boot-sunxi-with-spl.bin \
	write 0x42000000 build/out/chip.itb \
	write 0x44000000 build/out/boot-ram.scr
