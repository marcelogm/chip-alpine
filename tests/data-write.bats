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
