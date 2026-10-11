#!/bin/sh
set -eu
caller=$PWD
cd "$(dirname "$0")/.."
. data/settings.sh

absolute() {
	case $1 in
	/* | '') printf '%s\n' "$1" ;;
	*) printf '%s\n' "$caller/$1" ;;
	esac
}

missing() {
	echo "$1 is missing: run make $2" >&2
	exit 1
}

usage() {
	echo "usage: $0 [--config FILE] [--hostname NAME] [--ssh-key FILE] [--wifi-ssid SSID --wifi-psk PSK] [--print-settings]" >&2
	exit 2
}

refuse() {
	echo "$1" >&2
	exit 2
}

find_config() {
	while [ $# -gt 0 ]; do
		case $1 in
		--print-settings) shift ;;
		--config)
			[ $# -ge 2 ] || usage
			CONFIG=$(absolute "$2")
			CONFIG_GIVEN=yes
			shift 2
			;;
		*)
			[ $# -ge 2 ] || usage
			shift 2
			;;
		esac
	done
}

read_config() {
	number=0
	while IFS= read -r line || [ -n "$line" ]; do
		number=$((number + 1))
		case $line in
		'' | '#'*) continue ;;
		*=*) ;;
		*) refuse "$1:$number: not a key=value setting" ;;
		esac
		value=${line#*=}
		case ${line%%=*} in
		hostname) HOSTNAME_WANTED=$value ;;
		ssh_key) SSH_KEY=$value ;;
		wifi_ssid) WIFI_SSID=$value ;;
		wifi_psk) WIFI_PSK=$value ;;
		*) refuse "$1:$number: unknown setting ${line%%=*}" ;;
		esac
	done < "$1"
}

CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/chip-alpine/flash.conf
CONFIG_GIVEN=
HOSTNAME_WANTED=chip-alpine
SSH_KEY=
WIFI_SSID=
WIFI_PSK=
PRINT_SETTINGS=

find_config "$@"
if [ -n "$CONFIG_GIVEN" ] || [ -e "$CONFIG" ]; then
	[ -f "$CONFIG" ] || refuse "$CONFIG: no such file"
	read_config "$CONFIG"
fi

while [ $# -gt 0 ]; do
	if [ "$1" = --print-settings ]; then
		PRINT_SETTINGS=yes
		shift
		continue
	fi
	[ $# -ge 2 ] || usage
	case $1 in
	--config) ;;
	--hostname) HOSTNAME_WANTED=$2 ;;
	--ssh-key) SSH_KEY=$2 ;;
	--wifi-ssid) WIFI_SSID=$2 ;;
	--wifi-psk) WIFI_PSK=$2 ;;
	*) usage ;;
	esac
	shift 2
done

SSH_KEY=$(absolute "$SSH_KEY")
[ -z "$SSH_KEY" ] || [ -f "$SSH_KEY" ] || refuse "$SSH_KEY: no such file"
valid_hostname "$HOSTNAME_WANTED" || refuse "hostname needs 1 to 63 letters, digits or dashes, not starting with a dash"
if [ -n "$WIFI_SSID$WIFI_PSK" ]; then
	valid_wifi_ssid "$WIFI_SSID" || refuse "wifi network name needs 1 to 32 characters without quotes"
	valid_wifi_psk "$WIFI_PSK" || refuse "wifi password needs 8 to 63 printable characters without quotes, or 64 hex digits"
fi

if [ -n "$PRINT_SETTINGS" ]; then
	psk_state=unset
	[ -z "$WIFI_PSK" ] || psk_state=set
	printf 'hostname=%s\nssh_key=%s\nwifi_ssid=%s\nwifi_psk=%s\n' \
		"$HOSTNAME_WANTED" "$SSH_KEY" "$WIFI_SSID" "$psk_state"
	exit 0
fi

[ -f build/out/chip.itb ] || missing build/out/chip.itb image
ls build/out/data/cache/APKINDEX.*.tar.gz > /dev/null 2>&1 || missing build/out/data/cache data

set -- --hostname "$HOSTNAME_WANTED"
[ -z "$SSH_KEY" ] || set -- "$@" --ssh-key "$SSH_KEY"
[ -z "$WIFI_SSID" ] || set -- "$@" --wifi-ssid "$WIFI_SSID" --wifi-psk "$WIFI_PSK"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

data/apkovl.sh "$tmp/apkovl" "$@"
mkdir "$tmp/data"
cp -R build/out/data/cache "$tmp/data/cache"
cp "$tmp/apkovl"/*.apkovl.tar.gz "$tmp/data/"
tar -czf "$tmp/data.tar.gz" --owner=0 --group=0 --numeric-owner -C "$tmp/data" .

flash/fel-boot-ram.sh
flash/wait-for-console.sh
flash/chip-put build/out/chip.itb /tmp/chip.itb
flash/chip-sh 'chip-ubi-format' 600
flash/chip-sh 'chip-boot-write boot-a /tmp/chip.itb' 600
flash/chip-sh 'chip-boot-write boot-b /tmp/chip.itb' 600
flash/chip-put "$tmp/data.tar.gz" /tmp/data.tar.gz
flash/chip-sh 'chip-data-write /tmp/data.tar.gz' 600
flash/chip-sh 'reboot' 5 || true
flash/fel-flash-uboot.sh
echo "done: power off, remove the FEL jumper and power on to boot from the NAND"
