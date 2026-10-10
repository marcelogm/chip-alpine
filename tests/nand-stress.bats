STRESS=initramfs/rootfs/usr/sbin/chip-nand-stress

setup() {
	DIR=$(mktemp -d)
	head -c 1024 /dev/urandom > "$DIR/f000001"
	head -c 1024 /dev/urandom > "$DIR/f000002"
	(cd "$DIR" && sha256sum f000001 f000002) > "$DIR/manifest"
}

teardown() {
	rm -rf "$DIR"
}

@test "files listed in the manifest pass verification" {
	run $STRESS verify "$DIR"
	[ "$status" -eq 0 ]
	[[ "$output" == *"verified 2 files"* ]]
}

@test "a corrupted file fails verification" {
	printf 'corrupted' | dd of="$DIR/f000002" bs=1 seek=10 conv=notrunc 2>/dev/null
	run $STRESS verify "$DIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *f000002* ]]
}

@test "a manifest line cut short by power loss is ignored" {
	printf '0123456789abcdef' >> "$DIR/manifest"
	run $STRESS verify "$DIR"
	[ "$status" -eq 0 ]
	[[ "$output" == *"verified 2 files"* ]]
}

@test "a file still being written when power was cut is not required" {
	head -c 100 /dev/urandom > "$DIR/f000003"
	run $STRESS verify "$DIR"
	[ "$status" -eq 0 ]
}
