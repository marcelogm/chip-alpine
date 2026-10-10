#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

LINUX=linux-6.18.55
UBOOT=u-boot-2026.07
FIRMWARE_TAG=20260916

mkdir -p build/dl build/src

fetch() {
	[ -f "build/dl/$2" ] && return 0
	curl -fL -o "build/dl/$2.part" "$1"
	mv "build/dl/$2.part" "build/dl/$2"
}

extract() {
	[ -d "build/src/$2" ] && return 0
	rm -rf "build/src/.$2"
	mkdir -p "build/src/.$2"
	tar -C "build/src/.$2" -xf "build/dl/$1"
	mv "build/src/.$2/$2" "build/src/$2"
	rmdir "build/src/.$2"
}

fetch "https://cdn.kernel.org/pub/linux/kernel/v6.x/$LINUX.tar.xz" "$LINUX.tar.xz"
fetch "https://ftp.denx.de/pub/u-boot/$UBOOT.tar.bz2" "$UBOOT.tar.bz2"
fetch "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/rtlwifi/rtl8723bu_nic.bin?h=$FIRMWARE_TAG" rtl8723bs_nic.bin

(cd build/dl && sha256sum -c ../../sources/sha256sums)

extract "$LINUX.tar.xz" "$LINUX"
extract "$UBOOT.tar.bz2" "$UBOOT"
mkdir -p build/src/firmware/rtlwifi
cp build/dl/rtl8723bs_nic.bin build/src/firmware/rtlwifi/
