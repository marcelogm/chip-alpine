#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

OUT=build/out
UBOOT_PART=$((0x400000))
PAGE_WITH_OOB=$((0x4000 + 0x500))

mkimage -f image/chip.its $OUT/chip.itb
mkimage -A arm -T script -C none -d image/boot-ram.cmd $OUT/boot-ram.scr

if [ "$(stat -c %s $OUT/u-boot-dtb.bin)" -gt "$UBOOT_PART" ]; then
	echo "u-boot-dtb.bin does not fit in the 4 MiB uboot partition" >&2
	exit 1
fi
cp $OUT/u-boot-dtb.bin $OUT/uboot-4m.bin
truncate -s $UBOOT_PART $OUT/uboot-4m.bin

spl_pages=$(( ($(stat -c %s $OUT/sunxi-spl-with-ecc.bin) + PAGE_WITH_OOB - 1) / PAGE_WITH_OOB ))
cat > $OUT/flash-uboot.cmd <<CMD
nand erase 0x0 0xc00000
nand write.raw.noverify 0x47000000 0x0 $(printf '0x%x' $spl_pages)
nand write.raw.noverify 0x47000000 0x400000 $(printf '0x%x' $spl_pages)
nand write 0x48000000 0x800000 0x400000
CMD
mkimage -A arm -T script -C none -d $OUT/flash-uboot.cmd $OUT/flash-uboot.scr
