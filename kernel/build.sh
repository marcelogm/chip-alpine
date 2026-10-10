#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

SRC=build/src/linux-6.18.55
OUT=$PWD/build/kernel
KMAKE="make -C $SRC O=$OUT ARCH=arm CROSS_COMPILE=arm-none-eabi-"

mkdir -p "$OUT" build/out
$KMAKE sunxi_defconfig
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" kernel/chip.config
$KMAKE olddefconfig
$KMAKE -j"$(nproc)" zImage modules
rm -rf build/modules
$KMAKE INSTALL_MOD_PATH="$PWD/build/modules" INSTALL_MOD_STRIP=1 modules_install
cp "$OUT/arch/arm/boot/zImage" build/out/
