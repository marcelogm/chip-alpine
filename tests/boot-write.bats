WRITE=initramfs/rootfs/usr/sbin/chip-boot-write

@test "boot write needs an image and at least one slot" {
	run $WRITE /dev/null
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "boot write refuses anything but the boot slots" {
	run $WRITE /dev/null boot-a UBI
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}
