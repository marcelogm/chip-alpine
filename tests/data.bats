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
