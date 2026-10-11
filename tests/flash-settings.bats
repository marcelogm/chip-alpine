bats_require_minimum_version 1.5.0

NAND=$PWD/flash/flash-nand.sh
SETUP=$PWD/flash/flash-setup.sh

setup() {
	export XDG_CONFIG_HOME=$(mktemp -d)
	export HOME=$(mktemp -d)
	CONFIG=$XDG_CONFIG_HOME/chip-alpine/flash.conf
	KEY=$(mktemp); echo 'ssh-ed25519 AAAA test' > "$KEY"
}

write_config() {
	mkdir -p "${CONFIG%/*}"
	cat > "$CONFIG"
}

@test "flash uses the defaults without a flash config" {
	run $NAND --print-settings
	[ "$status" -eq 0 ]
	[ "$output" = "hostname=chip-alpine
ssh_key=
wifi_ssid=
wifi_psk=unset" ]
}

@test "flash takes its settings from the flash config without showing the wifi password" {
	write_config <<-EOF
	# the board in the garage
	hostname=garage

	ssh_key=$KEY
	wifi_ssid=home net
	wifi_psk=pass=word 1
	EOF
	run $NAND --print-settings
	[ "$status" -eq 0 ]
	[ "$output" = "hostname=garage
ssh_key=$KEY
wifi_ssid=home net
wifi_psk=set" ]
}

@test "flash options override the flash config" {
	write_config <<-EOF
	hostname=garage
	wifi_ssid=home
	wifi_psk=pass word
	EOF
	run $NAND --hostname shed --wifi-ssid office --wifi-psk 'other pass' --print-settings
	[ "$status" -eq 0 ]
	[ "$output" = "hostname=shed
ssh_key=
wifi_ssid=office
wifi_psk=set" ]
}

@test "flash reads another flash config given with --config" {
	other=$(mktemp); echo hostname=other > "$other"
	write_config <<-EOF
	hostname=garage
	EOF
	run $NAND --config "$other" --print-settings
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = hostname=other ]
}

@test "flash refuses a missing flash config given with --config" {
	run $NAND --config /nonexistent --print-settings
	[ "$status" -eq 2 ]
}

@test "flash refuses unknown settings and lines that are not settings" {
	write_config <<-EOF
	hostnme=garage
	EOF
	run $NAND --print-settings
	[ "$status" -eq 2 ]
	write_config <<-EOF
	garage
	EOF
	run $NAND --print-settings
	[ "$status" -eq 2 ]
}

@test "flash reads the flash config as data, not as a script" {
	marker=$(mktemp -d)/ran
	write_config <<-EOF
	hostname=garage; touch $marker
	wifi_ssid=\$(touch $marker)
	EOF
	run $NAND --print-settings
	[ ! -e "$marker" ]
}

@test "flash refuses an invalid hostname or wifi password from the flash config" {
	write_config <<-EOF
	hostname=-garage
	EOF
	run $NAND --print-settings
	[ "$status" -eq 2 ]
	write_config <<-EOF
	wifi_ssid=home
	wifi_psk=short
	EOF
	run $NAND --print-settings
	[ "$status" -eq 2 ]
	[[ "$output" != *short* ]]
}

@test "flash takes paths relative to where it is run" {
	dir=$(mktemp -d); cp "$KEY" "$dir/key.pub"; echo hostname=other > "$dir/flash.conf"
	cd "$dir"
	run $NAND --config flash.conf --ssh-key key.pub --print-settings
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = hostname=other ]
	[ "${lines[1]}" = "ssh_key=$dir/key.pub" ]
}

@test "flash setup writes the answers to a flash config only the user can read" {
	run --separate-stderr $SETUP <<-EOF
	garage
	$KEY
	home net
	pass word 1
	pass word 1
	EOF
	[ "$status" -eq 0 ]
	[ "$output" = "$CONFIG" ]
	[[ "$stderr" != *"pass word"* ]]
	[ "$(cat "$CONFIG")" = "hostname=garage
ssh_key=$KEY
wifi_ssid=home net
wifi_psk=pass word 1" ]
	[ "$(stat -c %a "$CONFIG")" = 600 ]
	[ "$(stat -c %a "${CONFIG%/*}")" = 700 ]
}

@test "flash setup defaults to chip-alpine, the chip key and no wifi" {
	mkdir "$HOME/.ssh"; cp "$KEY" "$HOME/.ssh/chip_ed25519.pub"
	run $SETUP <<-EOF



	EOF
	[ "$status" -eq 0 ]
	[ "$(cat "$CONFIG")" = "hostname=chip-alpine
ssh_key=$HOME/.ssh/chip_ed25519.pub
wifi_ssid=
wifi_psk=" ]
}

@test "flash setup takes a key path relative to the home or to where it is run" {
	mkdir "$HOME/keys"; cp "$KEY" "$HOME/keys/chip.pub"
	run $SETUP <<-EOF
	garage
	~/keys/chip.pub

	EOF
	[ "$status" -eq 0 ]
	grep -qx "ssh_key=$HOME/keys/chip.pub" "$CONFIG"
	cd "$HOME"
	run $SETUP <<-EOF
	garage
	keys/chip.pub

	EOF
	[ "$status" -eq 0 ]
	grep -qx "ssh_key=$HOME/keys/chip.pub" "$CONFIG"
}

@test "flash setup refuses wifi passwords that differ" {
	run $SETUP <<-EOF
	garage

	home
	pass word 1
	pass word 2
	EOF
	[ "$status" -eq 2 ]
	[ ! -e "$CONFIG" ]
}

@test "flash setup refuses an invalid hostname, key or wifi password" {
	printf -- '-garage\n\n\n' | { run $SETUP; [ "$status" -eq 2 ]; }
	printf 'garage\n/nonexistent\n\n' | { run $SETUP; [ "$status" -eq 2 ]; }
	printf 'garage\n\nhome\nshort\nshort\n' | { run $SETUP; [ "$status" -eq 2 ]; }
	[ ! -e "$CONFIG" ]
}

@test "flash reads what flash setup writes" {
	$SETUP > /dev/null 2>&1 <<-EOF
	garage
	$KEY
	home net
	pass word 1
	pass word 1
	EOF
	run $NAND --print-settings
	[ "$output" = "hostname=garage
ssh_key=$KEY
wifi_ssid=home net
wifi_psk=set" ]
}

@test "flash checks every build output before touching the board" {
	tree=$(mktemp -d); bin=$(mktemp -d)
	cp -R flash data "$tree/"
	mkdir -p "$tree/build/out/data/cache"
	touch "$tree/build/out/data/cache/APKINDEX.test.tar.gz"
	for file in u-boot-sunxi-with-spl.bin sunxi-spl-with-ecc.bin flash-uboot.scr boot-ram.scr chip.itb; do
		touch "$tree/build/out/$file"
	done
	printf '#!/bin/sh\ntouch %s/touched\nexit 1\n' "$bin" > "$bin/sunxi-fel"; chmod +x "$bin/sunxi-fel"
	PATH="$bin:$PATH" run "$tree/flash/flash-nand.sh"
	[ "$status" -eq 1 ]
	[[ "$output" == *build/out/uboot-4m.bin* ]]
	[ ! -e "$bin/touched" ]
}
