CACHE=$PWD/build/out/data/cache

@test "apk cache holds the signed alpine indexes" {
	ls $CACHE/APKINDEX.*.tar.gz > /dev/null
}

@test "the system installs offline from the apk cache" {
	root=$(mktemp -d)
	apk add --root "$root" --arch armv7 --initdb --no-network --no-scripts \
		--cache-dir "$CACHE" --keys-dir /usr/share/apk/keys/armv7 \
		--repository https://dl-cdn.alpinelinux.org/alpine/v3.24/main \
		$(cat data/world)
	[ -x "$root/usr/sbin/sshd" ]
	[ -x "$root/sbin/openrc" ]
	rm -rf "$root"
}

apkovl() {
	out=$(mktemp -d)
	data/apkovl.sh "$out" "$@"
	tar -tzvf "$out"/*.apkovl.tar.gz
}

@test "apkovl is named after the hostname" {
	out=$(mktemp -d)
	data/apkovl.sh "$out" --hostname nas
	[ -f "$out/nas.apkovl.tar.gz" ]
}

@test "apkovl keeps lbu commits and the apk cache on the data volume" {
	out=$(mktemp -d); data/apkovl.sh "$out"
	tar -xzOf "$out"/*.apkovl.tar.gz etc/lbu/lbu.conf | grep -qx 'LBU_MEDIA=data'
	tar -xzOf "$out"/*.apkovl.tar.gz etc/fstab | grep -q '^ubi0:data[[:space:]]*/media/data[[:space:]]*ubifs'
	apkovl | grep -q 'etc/apk/cache -> /media/data/cache'
}

@test "apkovl starts ssh and the network on boot" {
	apkovl | grep -q 'etc/runlevels/default/sshd -> /etc/init.d/sshd'
	apkovl | grep -q 'etc/runlevels/default/networking -> /etc/init.d/networking'
}

@test "apkovl files belong to root" {
	[ -z "$(apkovl | grep -v " root/root ")" ]
}

@test "apkovl authorizes the given ssh key for root only" {
	key=$(mktemp); echo 'ssh-ed25519 AAAA test' > "$key"
	apkovl --ssh-key "$key" | grep -E '^-rw------- .*root/\.ssh/authorized_keys$'
	apkovl --ssh-key "$key" | grep -E '^drwx------ .*root/\.ssh/$'
}

@test "apkovl joins the given wifi network" {
	out=$(mktemp -d); data/apkovl.sh "$out" --wifi-ssid home --wifi-psk 'pass word'
	tar -xzOf "$out"/*.apkovl.tar.gz etc/wpa_supplicant/wpa_supplicant.conf | grep -q 'ssid="home"'
	tar -xzOf "$out"/*.apkovl.tar.gz etc/wpa_supplicant/wpa_supplicant.conf | grep -q 'psk="pass word"'
	tar -xzOf "$out"/*.apkovl.tar.gz etc/network/interfaces | grep -q 'iface wlan0 inet dhcp'
	tar -tzvf "$out"/*.apkovl.tar.gz | grep -E '^-rw------- .*etc/wpa_supplicant/wpa_supplicant.conf$'
	tar -tzvf "$out"/*.apkovl.tar.gz | grep -q 'etc/runlevels/default/wpa_supplicant -> /etc/init.d/wpa_supplicant'
}

@test "apkovl needs both wifi name and password" {
	run data/apkovl.sh "$(mktemp -d)" --wifi-ssid home
	[ "$status" -eq 2 ]
}

@test "apkovl rejects a missing key and unknown options" {
	run data/apkovl.sh "$(mktemp -d)" --ssh-key /nonexistent
	[ "$status" -eq 2 ]
	run data/apkovl.sh "$(mktemp -d)" --bogus
	[ "$status" -eq 2 ]
}

@test "apkovl rejects wifi values with quotes" {
	run data/apkovl.sh "$(mktemp -d)" --wifi-ssid 'a"b' --wifi-psk x
	[ "$status" -eq 2 ]
}
