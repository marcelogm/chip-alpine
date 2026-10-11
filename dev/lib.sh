boot_id() {
	dev/chip-sh 'cat /proc/sys/kernel/random/boot_id' 5 2> /dev/null
}

slot() {
	dev/chip-sh 'cat /proc/cmdline' 5 | tr ' ' '\n' | sed -n 's/^chip\.slot=//p'
}

wait_new_boot() {
	tries=0
	while :; do
		id=$(boot_id) && [ -n "$id" ] && [ "$id" != "$1" ] && return 0
		tries=$((tries + 1))
		[ "$tries" -lt 60 ] || return 1
		sleep 2
	done
}

press() {
	printf '%s, then press Enter: ' "$1"
	read -r _ < /dev/tty
}
