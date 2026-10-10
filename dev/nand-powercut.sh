#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

cuts=${1:-30}
log=build/logs/nand-powercut.log
mkdir -p build/logs

boot() {
	dev/fel-boot-ram.sh > /dev/null
	dev/wait-for-console.sh
}

press() {
	printf '%s, then press Enter: ' "$1"
	read -r _ < /dev/tty
}

boot
dev/chip-sh 'chip-nand-stress format' 600 | tee "$log"

i=1
while [ "$i" -le "$cuts" ]; do
	dev/chip-sh 'chip-nand-stress powercut-write > /dev/null 2>&1 &'
	sleep $(( $(od -An -N1 -tu1 /dev/urandom) % 26 + 5 ))
	press "cut $i/$cuts: press the hub port button to CUT power"
	press "press it again to RESTORE power"
	boot
	if dev/chip-sh 'chip-nand-stress powercut-check' 600 | tee -a "$log" | grep -q '^verified'; then
		echo "cut $i ok" | tee -a "$log"
	else
		echo "cut $i FAILED" | tee -a "$log"
		exit 1
	fi
	i=$((i + 1))
done

echo "all $cuts power cuts survived" | tee -a "$log"
