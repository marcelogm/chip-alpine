#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

dev/fel-run.sh \
	uboot build/out/u-boot-sunxi-with-spl.bin \
	write 0x44100000 build/out/sunxi-spl-with-ecc.bin \
	write 0x44200000 build/out/u-boot.img \
	write 0x44000000 build/out/flash-uboot.scr

sleep 5
tries=0
while :; do
	if sunxi-fel -l | grep -q .; then
		echo "spl and u-boot written"
		exit 0
	fi
	if [ -e /dev/ttyACM0 ]; then
		echo "u-boot failed to write itself; its console is on /dev/ttyACM0" >&2
		exit 1
	fi
	tries=$((tries + 1))
	if [ "$tries" -ge 60 ]; then
		echo "board did not come back to FEL nor open its rescue console" >&2
		exit 1
	fi
	sleep 1
done
