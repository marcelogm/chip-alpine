#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

flash/fel-run.sh \
	uboot build/out/u-boot-sunxi-with-spl.bin \
	write 0x47000000 build/out/sunxi-spl-with-ecc.bin \
	write 0x48000000 build/out/uboot-4m.bin \
	write 0x43100000 build/out/flash-uboot.scr

deadline=$(( $(date +%s) + 180 ))
until [ -e /dev/ttyACM0 ] && flash/chip-sh true 5 > /dev/null 2>&1; do
	if [ "$(date +%s)" -ge "$deadline" ]; then
		echo "FAILED: linux did not come up from boot-a within 3 minutes of writing the spl and u-boot" >&2
		exit 1
	fi
	sleep 2
done

got=$(flash/chip-sh 'cat /proc/cmdline' 5 | tr ' ' '\n' | sed -n 's/^chip\.slot=//p')
if [ "$got" != a ]; then
	echo "FAILED: linux booted slot '$got' after writing the spl and u-boot, expected a" >&2
	exit 1
fi
echo "spl and u-boot written: u-boot booted boot-a from UBI"
