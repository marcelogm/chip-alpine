#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

tries=0
until [ -e /dev/ttyACM0 ] && dev/chip-sh true 5 > /dev/null 2>&1; do
	tries=$((tries + 1))
	if [ "$tries" -ge 60 ]; then
		echo "board console did not come up on /dev/ttyACM0" >&2
		exit 1
	fi
	sleep 2
done
