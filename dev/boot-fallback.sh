#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. dev/lib.sh

expect_slot() {
	old=$(boot_id)
	dev/chip-sh 'reboot' 5 || true
	if ! wait_new_boot "$old"; then
		echo "$2: console did not come back" >&2
		exit 1
	fi
	got=$(slot)
	if [ "$got" != "$1" ]; then
		echo "$2: booted slot '$got', expected '$1'" >&2
		exit 1
	fi
	echo "$2: booted slot $1"
}

dev/chip-sh 'flash_erase -q /dev/$(grep "\"boot-a\"" /proc/mtd | cut -d: -f1) 0 0' 120
expect_slot b "erased boot-a"

cp build/out/boot-a.img build/out/boot-a-corrupt.img
printf 'CORRUPT!' | dd of=build/out/boot-a-corrupt.img bs=1 seek=$((0x200000)) conv=notrunc 2> /dev/null
dev/chip-put build/out/boot-a-corrupt.img /tmp/boot-a-corrupt.img
dev/chip-sh 'chip-boot-write boot-a /tmp/boot-a-corrupt.img' 300
expect_slot b "boot-a with a bad payload crc"

dev/chip-put build/out/boot-a.img /tmp/boot-a.img
dev/chip-sh 'chip-boot-write boot-a /tmp/boot-a.img' 300
expect_slot a "boot-a restored"
