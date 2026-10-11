#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. dev/lib.sh

boots=${1:-50}
log=build/logs/boot-loop.log
mkdir -p build/logs
: > "$log"

i=1
while [ "$i" -le "$boots" ]; do
	old=$(boot_id)
	start=$(date +%s)
	dev/chip-sh 'reboot' 5 || true
	if ! wait_new_boot "$old"; then
		echo "boot $i FAILED: console did not come back" | tee -a "$log"
		exit 1
	fi
	got=$(slot)
	if [ "$got" != a ]; then
		echo "boot $i FAILED: slot '$got'" | tee -a "$log"
		exit 1
	fi
	echo "boot $i ok slot=a seconds=$(( $(date +%s) - start ))" | tee -a "$log"
	i=$((i + 1))
done

echo "all $boots reboots came back from boot-a" | tee -a "$log"
