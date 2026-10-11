#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

exec dev/fel-run.sh uboot build/out/u-boot-sunxi-with-spl.bin
