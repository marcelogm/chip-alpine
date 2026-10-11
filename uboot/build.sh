#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

SRC=build/src/u-boot-2022.01
OUT=$PWD/build/uboot
UMAKE="make -C $SRC O=$OUT CROSS_COMPILE=arm-none-eabi- DTC=dtc"

mkdir -p "$OUT" build/out
for p in uboot/patches/*.patch; do
	applied=$SRC/.applied-$(basename "$p")
	[ -f "$applied" ] && continue
	patch -d "$SRC" -p1 -s -f < "$p"
	touch "$applied"
done
$UMAKE CHIP_defconfig
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" uboot/chip.config
$UMAKE olddefconfig
$UMAKE -j"$(nproc)" all u-boot-initial-env
cp "$OUT/u-boot-sunxi-with-spl.bin" "$OUT/spl/sunxi-spl-with-ecc.bin" "$OUT/u-boot-dtb.bin" build/out/
