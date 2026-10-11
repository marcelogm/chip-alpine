WRITE=initramfs/rootfs/usr/sbin/chip-boot-write

@test "boot write needs a slot and an image" {
	run $WRITE boot-a
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "boot write takes one slot at a time" {
	run $WRITE boot-a boot-b /dev/null
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "boot write refuses anything but the boot slots" {
	run $WRITE UBI /dev/null
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "boot write takes the slot before the image" {
	run $WRITE /dev/null boot-a
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}
