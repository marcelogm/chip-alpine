WRITE=initramfs/rootfs/usr/sbin/chip-data-write

@test "data write needs a tarball" {
	run $WRITE
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "data write takes one tarball" {
	run $WRITE /dev/null /dev/null
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "data write refuses a missing tarball" {
	run $WRITE /nonexistent.tar.gz
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

fake_board() {
	[ -f /run/.containerenv ] || skip "needs a container: writes to /media/data"
	BIN=$(mktemp -d)
	for tool in mount umount ubiattach; do
		printf '#!/bin/sh\n' > "$BIN/$tool"; chmod +x "$BIN/$tool"
	done
	ln -s /bin/busybox "$BIN/tar"
	rm -rf /media/data; mkdir -p /media/data
	SRC=$(mktemp -d); TARBALL=$(mktemp -d)/data.tar.gz
}

@test "data write gives root what it writes" {
	fake_board
	mkdir "$SRC/cache"; touch "$SRC/cache/alpine-base.apk"
	tar -czf "$TARBALL" --owner=1000 --group=1000 --numeric-owner -C "$SRC" .
	PATH="$BIN:$PATH" run $WRITE "$TARBALL"
	[ "$status" -eq 0 ]
	[ "$(stat -c %u:%g /media/data/cache/alpine-base.apk)" = 0:0 ]
	[ "$(stat -c %u:%g /media/data/cache)" = 0:0 ]
}
