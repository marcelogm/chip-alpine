ITB=build/out/chip.itb

@test "fit carries the kernel" {
	dumpimage -l $ITB | grep -q 'Type:.*Kernel Image'
}

@test "fit carries the device tree" {
	dumpimage -l $ITB | grep -q 'Type:.*Flat Device Tree'
}

@test "fit carries the initramfs" {
	dumpimage -l $ITB | grep -q 'Type:.*RAMDisk Image'
}

@test "fit fits below the boot script sunxi-fel writes at 0x44000000" {
	[ "$(stat -c %s $ITB)" -lt $((0x2000000)) ]
}

@test "ram boot script boots the fit sunxi-fel left at 0x42000000" {
	dumpimage -l build/out/boot-ram.scr | grep -q 'Script'
	grep -qF 'chip.slot=ram' image/boot-ram.cmd
	grep -qx 'bootm 0x42000000' image/boot-ram.cmd
}

@test "slot payloads are u-boot firmware images the spl loads at 0x4a000000" {
	for slot in boot-a boot-b; do
		dumpimage -l build/out/$slot.img > "$BATS_TEST_TMPDIR/$slot"
		grep -qx "Image Name:   $slot" "$BATS_TEST_TMPDIR/$slot"
		grep -q 'Image Type:   ARM U-Boot Firmware (uncompressed)' "$BATS_TEST_TMPDIR/$slot"
		grep -qx 'Load Address: 4a000000' "$BATS_TEST_TMPDIR/$slot"
		grep -qx 'Entry Point:  4a000000' "$BATS_TEST_TMPDIR/$slot"
	done
}

@test "fit sits 1 MiB into the payload, right after u-boot" {
	cmp -n "$(stat -c %s $ITB)" $ITB build/out/boot-a.img 0 $((64 + 0x100000))
	cmp -n "$(stat -c %s $ITB)" $ITB build/out/boot-b.img 0 $((64 + 0x100000))
}

@test "payload fits in a 32 MiB boot slot" {
	[ "$(stat -c %s build/out/boot-a.img)" -le $((0x2000000)) ]
	[ "$(stat -c %s build/out/boot-b.img)" -le $((0x2000000)) ]
}
