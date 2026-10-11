#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

SRC=build/src/u-boot-2026.07
OUT=$PWD/build/uboot
UMAKE="make -C $SRC O=$OUT CROSS_COMPILE=arm-none-eabi-"

mkdir -p "$OUT" build/out
for p in uboot/patches/*.patch; do
	patch -d "$SRC" -p1 -R -s -f --dry-run < "$p" > /dev/null 2>&1 || patch -d "$SRC" -p1 -s -f < "$p"
done
cp uboot/sun5i-r8-chip-u-boot.dtsi "$SRC/arch/arm/dts/"
$UMAKE CHIP_defconfig
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" uboot/chip.config
$UMAKE olddefconfig
$UMAKE -j"$(nproc)"
cp "$OUT/u-boot-sunxi-with-spl.bin" "$OUT/spl/sunxi-spl-with-ecc.bin" "$OUT/u-boot.img" build/out/
