#!/bin/sh
set -eu
. "$(dirname "$0")/../data/settings.sh"

CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/chip-alpine
CONFIG=$CONFIG_DIR/flash.conf
DEFAULT_KEY=$HOME/.ssh/chip_ed25519.pub

refuse() {
	echo "$1" >&2
	exit 2
}

ask() {
	printf '%s' "$1" >&2
	answer=
	IFS= read -r answer || true
}

ask_secret() {
	if [ -t 0 ]; then
		stty -echo
		ask "$1"
		stty echo
		printf '\n' >&2
	else
		ask "$1"
	fi
}

if [ -t 0 ]; then
	trap 'stty echo' EXIT
	trap 'exit 130' INT TERM HUP
fi

ask "Hostname [chip-alpine]: "
hostname=${answer:-chip-alpine}
valid_hostname "$hostname" || refuse "hostname needs 1 to 63 letters, digits or dashes, not starting with a dash"

if [ -f "$DEFAULT_KEY" ]; then
	ask "SSH public key for root [$DEFAULT_KEY]: "
	ssh_key=${answer:-$DEFAULT_KEY}
else
	ask "SSH public key for root (empty for none): "
	ssh_key=$answer
fi
case $ssh_key in
'~/'*) ssh_key=$HOME/${ssh_key#'~/'} ;;
/* | '') ;;
*) ssh_key=$PWD/$ssh_key ;;
esac
[ -z "$ssh_key" ] || [ -f "$ssh_key" ] || refuse "$ssh_key: no such file"

ask "Wi-Fi network (empty for none): "
wifi_ssid=$answer
wifi_psk=
if [ -n "$wifi_ssid" ]; then
	valid_wifi_ssid "$wifi_ssid" || refuse "wifi network name needs 1 to 32 characters without quotes"
	ask_secret "Wi-Fi password: "
	wifi_psk=$answer
	ask_secret "Wi-Fi password again: "
	[ "$answer" = "$wifi_psk" ] || refuse "the wifi passwords differ"
	valid_wifi_psk "$wifi_psk" || refuse "wifi password needs 8 to 63 printable characters without quotes, or 64 hex digits"
fi

umask 077
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
rm -f "$CONFIG"
printf 'hostname=%s\nssh_key=%s\nwifi_ssid=%s\nwifi_psk=%s\n' \
	"$hostname" "$ssh_key" "$wifi_ssid" "$wifi_psk" > "$CONFIG"
echo "$CONFIG"
