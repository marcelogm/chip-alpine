#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

ROOT=build/initramfs
REPO=https://dl-cdn.alpinelinux.org/alpine/v3.24/main

rm -rf "$ROOT"
mkdir -p "$ROOT/etc/apk/keys" build/out
cp /usr/share/apk/keys/armv7/* "$ROOT/etc/apk/keys/"

apk add --root "$ROOT" --arch armv7 --initdb --no-cache --no-scripts \
	--repository "$REPO" $(cat initramfs/packages)

cp -a initramfs/rootfs/. "$ROOT/"
mkdir -p "$ROOT/lib/firmware"
cp -a build/modules/lib/modules "$ROOT/lib/"
cp -a build/src/firmware/rtlwifi "$ROOT/lib/firmware/"
mkdir -p "$ROOT/proc" "$ROOT/sys" "$ROOT/dev" "$ROOT/run" "$ROOT/tmp"

(cd "$ROOT" && find . -mindepth 1 | sed 's|^\./||' | cpio -o -H newc -R 0:0 --quiet) |
	gzip -9 > build/out/initramfs.cpio.gz
