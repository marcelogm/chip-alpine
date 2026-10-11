#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
. dev/lib.sh

boots=${1:-5}
log=build/logs/cold-boots.log
mkdir -p build/logs
: > "$log"

i=1
while [ "$i" -le "$boots" ]; do
	old=$(boot_id)
	press "boot $i/$boots: press the hub port button to CUT power"
	press "press it again to RESTORE power"
	echo "boot $i/$boots: waiting for the board"
	if ! wait_new_boot "$old"; then
		echo "boot $i FAILED: console did not come back" | tee -a "$log"
		exit 1
	fi
	got=$(slot)
	if [ "$got" != a ]; then
		echo "boot $i FAILED: slot '$got'" | tee -a "$log"
		exit 1
	fi
	echo "boot $i ok slot=a" | tee -a "$log"
	i=$((i + 1))
done

echo "all $boots cold boots came back from boot-a" | tee -a "$log"
