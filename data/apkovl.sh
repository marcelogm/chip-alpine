#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

usage() {
	echo "usage: $0 OUT_DIR [--hostname NAME] [--ssh-key FILE] [--wifi-ssid SSID --wifi-psk PSK]" >&2
	exit 2
}

enable() {
	mkdir -p "$STAGE/etc/runlevels/$1"
	ln -s "/etc/init.d/$2" "$STAGE/etc/runlevels/$1/$2"
}

reject_unsafe() {
	case $1 in
	*'"'* | *'
'*) usage ;;
	esac
}

[ $# -ge 1 ] || usage
OUT_DIR=$1
shift
HOSTNAME_WANTED=chip-alpine
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
reject_unsafe "$WIFI_SSID"
reject_unsafe "$WIFI_PSK"
[ -n "$HOSTNAME_WANTED" ] || usage

mkdir -p "$OUT_DIR"
OUT_DIR=$(cd "$OUT_DIR" && pwd)
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

cp -R data/overlay/. "$STAGE"

for service in devfs dmesg mdev hwdrivers; do enable sysinit $service; done
for service in modules sysctl hostname bootmisc syslog swclock; do enable boot $service; done
for service in networking sshd chronyd; do enable default $service; done
for service in mount-ro killprocs savecache; do enable shutdown $service; done

echo "$HOSTNAME_WANTED" > "$STAGE/etc/hostname"
cp data/world "$STAGE/etc/apk/world"
ln -s /media/data/cache "$STAGE/etc/apk/cache"

if [ -n "$SSH_KEY" ]; then
	mkdir -p "$STAGE/root/.ssh"
	chmod 700 "$STAGE/root/.ssh"
	cp "$SSH_KEY" "$STAGE/root/.ssh/authorized_keys"
	chmod 600 "$STAGE/root/.ssh/authorized_keys"
fi

if [ -n "$WIFI_SSID" ]; then
	mkdir -p "$STAGE/etc/wpa_supplicant"
	printf 'ctrl_interface=/var/run/wpa_supplicant\n\nnetwork={\n\tssid="%s"\n\tpsk="%s"\n}\n' \
		"$WIFI_SSID" "$WIFI_PSK" > "$STAGE/etc/wpa_supplicant/wpa_supplicant.conf"
	chmod 600 "$STAGE/etc/wpa_supplicant/wpa_supplicant.conf"
	printf '\nauto wlan0\niface wlan0 inet dhcp\n' >> "$STAGE/etc/network/interfaces"
	enable default wpa_supplicant
fi

chmod 755 "$STAGE"
tar -czf "$OUT_DIR/$HOSTNAME_WANTED.apkovl.tar.gz" --owner=0 --group=0 -C "$STAGE" $(ls -A "$STAGE")
