#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

tries=0
until sunxi-fel -l | grep -q .; do
	tries=$((tries + 1))
	if [ "$tries" -ge 30 ]; then
		echo "no C.H.I.P. in FEL mode found: jumper FEL to GND and reconnect the micro-USB" >&2
		exit 1
	fi
	sleep 1
done

sunxi-fel -v -p "$@"
