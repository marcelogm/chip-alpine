#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

dev/fel-boot-ram.sh
dev/wait-for-console.sh
dev/chip-put build/out/boot-a.img /tmp/boot-a.img
dev/chip-put build/out/boot-b.img /tmp/boot-b.img
dev/chip-put build/out/sunxi-spl-with-ecc.bin /tmp/spl.bin
dev/chip-sh 'chip-boot-write boot-a /tmp/boot-a.img' 600
dev/chip-sh 'chip-boot-write boot-b /tmp/boot-b.img' 600
dev/chip-sh 'chip-spl-write /tmp/spl.bin' 600
echo "done: power off, remove the FEL jumper and power on to boot from the NAND"
