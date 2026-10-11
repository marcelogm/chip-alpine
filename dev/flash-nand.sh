#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

usage() {
	echo "usage: $0 [--hostname NAME] [--ssh-key FILE] [--wifi-ssid SSID --wifi-psk PSK]" >&2
	exit 2
}

HOSTNAME_WANTED=
SSH_KEY=
WIFI_SSID=
WIFI_PSK=

while [ $# -gt 0 ]; do
	[ $# -ge 2 ] || usage
	case $1 in
	--hostname) HOSTNAME_WANTED=$2 ;;
	--ssh-key) SSH_KEY=$2 ;;
	--wifi-ssid) WIFI_SSID=$2 ;;
	--wifi-psk) WIFI_PSK=$2 ;;
	*) usage ;;
	esac
	shift 2
done

[ -z "$SSH_KEY" ] || [ -f "$SSH_KEY" ] || usage
[ -n "$WIFI_SSID" ] || [ -z "$WIFI_PSK" ] || usage
[ -z "$WIFI_SSID" ] || [ -n "$WIFI_PSK" ] || usage

set --
[ -z "$HOSTNAME_WANTED" ] || set -- "$@" --hostname "$HOSTNAME_WANTED"
[ -z "$SSH_KEY" ] || set -- "$@" --ssh-key "$SSH_KEY"
[ -z "$WIFI_SSID" ] || set -- "$@" --wifi-ssid "$WIFI_SSID" --wifi-psk "$WIFI_PSK"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

data/apkovl.sh "$tmp/apkovl" "$@"
mkdir "$tmp/data"
cp -R build/out/data/cache "$tmp/data/cache"
cp "$tmp/apkovl"/*.apkovl.tar.gz "$tmp/data/"
tar -czf "$tmp/data.tar.gz" --owner=0 --group=0 --numeric-owner -C "$tmp/data" .

dev/fel-boot-ram.sh
dev/wait-for-console.sh
dev/chip-put build/out/chip.itb /tmp/chip.itb
dev/chip-sh 'chip-ubi-format' 600
dev/chip-sh 'chip-boot-write boot-a /tmp/chip.itb' 600
dev/chip-sh 'chip-boot-write boot-b /tmp/chip.itb' 600
dev/chip-put "$tmp/data.tar.gz" /tmp/data.tar.gz
dev/chip-sh 'chip-data-write /tmp/data.tar.gz' 600
dev/chip-sh 'reboot' 5 || true
dev/fel-flash-uboot.sh
echo "done: power off, remove the FEL jumper and power on to boot from the NAND"
