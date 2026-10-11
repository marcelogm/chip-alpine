#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

OUT=build/out
UBOOT_MAX=$((0x100000))

mkimage -f image/chip.its $OUT/chip.itb
mkimage -A arm -T script -C none -d image/boot-ram.cmd $OUT/boot-ram.scr

if [ "$(stat -c %s $OUT/u-boot.bin)" -ge "$UBOOT_MAX" ]; then
	echo "u-boot.bin does not fit in the 1 MiB before the fit in a boot slot" >&2
	exit 1
fi
cp $OUT/u-boot.bin $OUT/payload.bin
truncate -s 1M $OUT/payload.bin
cat $OUT/chip.itb >> $OUT/payload.bin

for slot in boot-a boot-b; do
	mkimage -A arm -O u-boot -T firmware -C none -a 0x4a000000 -e 0x4a000000 -n $slot \
		-d $OUT/payload.bin $OUT/$slot.img
done
