#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

OUT=build/out
PAGE_WITH_OOB=$((0x4000 + 0x500))

mkimage -f image/chip.its $OUT/chip.itb
mkimage -A arm -T script -C none -d image/boot-ram.cmd $OUT/boot-ram.scr

spl_size=$(stat -c %s $OUT/sunxi-spl-with-ecc.bin)
spl_pages=$(printf '0x%x' $(( (spl_size + PAGE_WITH_OOB - 1) / PAGE_WITH_OOB )))
uboot_size=$(printf '0x%x' "$(stat -c %s $OUT/u-boot.img)")

cat > $OUT/flash-uboot.cmd <<EOT
nand erase 0x0 0xc00000
nand write.raw.noverify 0x44100000 0x0 $spl_pages
nand write.raw.noverify 0x44100000 0x400000 $spl_pages
nand write 0x44200000 0x800000 0x100000
nand read 0x45000000 0x800000 0x100000
if cmp.b 0x44200000 0x45000000 $uboot_size; then reset; fi
run chip_rescue
EOT
mkimage -A arm -T script -C none -d $OUT/flash-uboot.cmd $OUT/flash-uboot.scr
