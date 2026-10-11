matches() {
	case $1 in
	*'
'*) return 1 ;;
	esac
	printf '%s\n' "$1" | LC_ALL=C grep -Eq "$2"
}

valid_hostname() {
	matches "$1" '^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$'
}

valid_wifi_ssid() {
	matches "$1" '^[^"]{1,32}$'
}

valid_wifi_psk() {
	matches "$1" '^[ !#-~]{8,63}$' || wifi_psk_is_raw_key "$1"
}

wifi_psk_is_raw_key() {
	matches "$1" '^[0-9a-fA-F]{64}$'
}
