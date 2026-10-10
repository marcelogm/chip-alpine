#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

SRC=build/src/u-boot-2026.07
OUT=$PWD/build/uboot
UMAKE="make -C $SRC O=$OUT CROSS_COMPILE=arm-none-eabi-"

mkdir -p "$OUT" build/out
$UMAKE CHIP_defconfig
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" uboot/fel-ram.config
$UMAKE olddefconfig
$UMAKE -j"$(nproc)"
cp "$OUT/u-boot-sunxi-with-spl.bin" build/out/
