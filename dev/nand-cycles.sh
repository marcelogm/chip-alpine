#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

cycles=${1:-1000}
log=build/logs/nand-cycles.log
mkdir -p build/logs

dev/fel-boot-ram.sh
dev/wait-for-console.sh
dev/chip-sh 'chip-nand-stress format' 600
dev/chip-sh "chip-nand-stress cycles $cycles > /tmp/cycles.log 2>&1 &"

while :; do
	sleep 60
	last=$(dev/chip-sh 'tail -n 1 /tmp/cycles.log' 15)
	echo "$last"
	case "$last" in
		done*) break ;;
		*FAIL*)
			dev/chip-sh 'cat /tmp/cycles.log' 120 > "$log"
			exit 1
			;;
	esac
done

dev/chip-sh 'cat /tmp/cycles.log' 120 > "$log"
