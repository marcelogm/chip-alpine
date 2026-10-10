ITB=build/out/chip-ram.itb

@test "fit carries the kernel" {
	dumpimage -l $ITB | grep -q 'Type:.*Kernel Image'
}

@test "fit carries the device tree" {
	dumpimage -l $ITB | grep -q 'Type:.*Flat Device Tree'
}

@test "fit carries the initramfs" {
	dumpimage -l $ITB | grep -q 'Type:.*RAMDisk Image'
}

@test "fit fits below u-boot at 0x4a000000 when loaded at 0x42000000" {
	[ "$(stat -c %s $ITB)" -lt $((0x8000000)) ]
}
