#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

dev/fel-boot-ram.sh
dev/wait-for-console.sh
dev/chip-put build/out/chip.itb /tmp/chip.itb
dev/chip-sh 'chip-boot-write /tmp/chip.itb boot-a boot-b' 600
dev/chip-sh 'reboot' 5 || true
dev/fel-flash-uboot.sh
echo "done: power off, remove the FEL jumper and power on to boot from the NAND"
