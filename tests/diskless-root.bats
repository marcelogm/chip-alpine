ROOTER=initramfs/rootfs/usr/sbin/chip-diskless-root

setup() {
	MEDIA=$(mktemp -d); SYSROOT=$(mktemp -d); BIN=$(mktemp -d)
	printf '#!/bin/sh\necho "$@" > %s/apk-args\n' "$BIN" > "$BIN/apk"; chmod +x "$BIN/apk"
	ovl=$(mktemp -d); mkdir -p "$ovl/etc/apk"
	echo alpine-base > "$ovl/etc/apk/world"; echo https://example/main > "$ovl/etc/apk/repositories"
	tar -czf "$MEDIA/chip.apkovl.tar.gz" -C "$ovl" .
	mkdir -p "$MEDIA/cache"
}

@test "diskless root installs the overlay's world offline from the cache" {
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	grep -q -- "--no-network" "$BIN/apk-args"
	grep -q -- "--cache-dir $MEDIA/cache" "$BIN/apk-args"
	grep -q 'alpine-base' "$BIN/apk-args"
}

@test "diskless root lays the overlay over the sysroot" {
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ -f "$SYSROOT/etc/apk/world" ]
}

@test "diskless root refuses a data volume without an overlay" {
	rm "$MEDIA"/*.apkovl.tar.gz
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ "$status" -eq 1 ]
}

@test "diskless root refuses a data volume with more than one overlay" {
	cp "$MEDIA/chip.apkovl.tar.gz" "$MEDIA/other.apkovl.tar.gz"
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ "$status" -eq 1 ]
	[ ! -e "$BIN/apk-args" ]
}

@test "diskless root trusts the initramfs keys and the overlay's repositories" {
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	grep -q -- "--keys-dir /etc/apk/keys" "$BIN/apk-args"
	grep -q -- "--repositories-file $SYSROOT/etc/apk/repositories" "$BIN/apk-args"
	grep -q -- "--root $SYSROOT --initdb" "$BIN/apk-args"
}

@test "diskless root gives the system the nand tools" {
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ "$status" -eq 0 ]
	[ -x "$SYSROOT/usr/sbin/chip-boot-write" ]
	[ -x "$SYSROOT/usr/sbin/chip-ubi-format" ]
}

@test "diskless root fails when the packages do not install" {
	printf '#!/bin/sh\nexit 3\n' > "$BIN/apk"
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ "$status" -ne 0 ]
	[ ! -e "$SYSROOT/usr/sbin/chip-boot-write" ]
}

@test "diskless root installs what the cache has when a package is missing from it" {
	printf '#!/bin/sh\necho "$@" >> %s/apk-args\ncase " $* " in *" --initramfs-diskless-boot "*) exit 0 ;; esac\nexit 1\n' "$BIN" > "$BIN/apk"
	PATH="$BIN:$PATH" run $ROOTER "$MEDIA" "$SYSROOT"
	[ "$status" -eq 0 ]
	[ "$(wc -l < "$BIN/apk-args")" -eq 2 ]
	head -n 1 "$BIN/apk-args" | grep -vq -- --initramfs-diskless-boot
	[ -x "$SYSROOT/usr/sbin/chip-boot-write" ]
}

@test "diskless root needs the data volume and the sysroot" {
	run $ROOTER "$MEDIA"
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}
