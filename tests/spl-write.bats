WRITE=initramfs/rootfs/usr/sbin/chip-spl-write
PAGE_WITH_OOB=$((0x4000 + 0x500))

@test "spl write needs one image" {
	run $WRITE
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
	run $WRITE a b
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "spl write refuses an image that is not whole pages with their oob" {
	head -c $((PAGE_WITH_OOB + 1)) /dev/zero > "$BATS_TEST_TMPDIR/spl.bin"
	run $WRITE "$BATS_TEST_TMPDIR/spl.bin"
	[ "$status" -eq 2 ]
	[[ "$output" == *"not whole pages"* ]]
}

@test "spl write refuses an empty image" {
	: > "$BATS_TEST_TMPDIR/spl.bin"
	run $WRITE "$BATS_TEST_TMPDIR/spl.bin"
	[ "$status" -eq 2 ]
	[[ "$output" == *"not whole pages"* ]]
}

@test "spl with ecc is whole pages with their oob" {
	[ $(( $(stat -c %s build/out/sunxi-spl-with-ecc.bin) % PAGE_WITH_OOB )) -eq 0 ]
}
