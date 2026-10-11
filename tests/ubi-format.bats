FORMAT=initramfs/rootfs/usr/sbin/chip-ubi-format

@test "ubi format takes no arguments" {
	run $FORMAT UBI
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}

@test "ubi format gives the rest of the nand to the data volume" {
	grep -q 'ubimkvol /dev/ubi0 -N data -m' initramfs/rootfs/usr/sbin/chip-ubi-format
}
