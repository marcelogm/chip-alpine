#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

SRC=build/src/linux-6.18.55
OUT=$PWD/build/kernel
DTS_DIR=$SRC/arch/arm/boot/dts/allwinner
KMAKE="make -C $SRC O=$OUT ARCH=arm CROSS_COMPILE=arm-none-eabi-"

mkdir -p "$OUT" build/out
cp kernel/dts/sun5i-r8-chip-alpine.dts "$DTS_DIR/"
grep -q sun5i-r8-chip-alpine.dtb "$DTS_DIR/Makefile" ||
	echo 'dtb-$(CONFIG_MACH_SUN5I) += sun5i-r8-chip-alpine.dtb' >> "$DTS_DIR/Makefile"

$KMAKE sunxi_defconfig
"$SRC/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" kernel/chip.config
$KMAKE olddefconfig
$KMAKE -j"$(nproc)" zImage modules allwinner/sun5i-r8-chip-alpine.dtb
rm -rf build/modules
$KMAKE INSTALL_MOD_PATH="$PWD/build/modules" INSTALL_MOD_STRIP=1 modules_install
cp "$OUT/arch/arm/boot/zImage" build/out/
cp "$OUT/arch/arm/boot/dts/allwinner/sun5i-r8-chip-alpine.dtb" build/out/
