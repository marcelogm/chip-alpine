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

if ! dev/chip-sh '[ -e /dev/ubi0 ] || ubiattach -p /dev/$(grep "\"UBI\"" /proc/mtd | cut -d: -f1) > /dev/null; ubiupdatevol -t /dev/$(grep -lx boot-a /sys/class/ubi/ubi0_*/name | cut -d/ -f5)' 60; then
	echo "could not empty boot-a" >&2
	exit 1
fi
expect_slot b "empty boot-a"

cp build/out/chip.itb build/out/chip-corrupt.itb
printf 'CORRUPT!' | dd of=build/out/chip-corrupt.itb bs=1 seek=$((0x100000)) conv=notrunc 2> /dev/null
dev/chip-put build/out/chip-corrupt.itb /tmp/chip-corrupt.itb
dev/chip-sh 'chip-boot-write boot-a /tmp/chip-corrupt.itb' 300
expect_slot b "boot-a failing its fit hash"

dev/chip-put build/out/chip.itb /tmp/chip.itb
dev/chip-sh 'chip-boot-write boot-a /tmp/chip.itb' 300
expect_slot a "boot-a restored"
