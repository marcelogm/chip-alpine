FORMAT=initramfs/rootfs/usr/sbin/chip-ubi-format

@test "ubi format takes no arguments" {
	run $FORMAT UBI
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}
