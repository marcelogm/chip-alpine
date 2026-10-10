#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

mkimage -f image/chip-ram.its build/out/chip-ram.itb
