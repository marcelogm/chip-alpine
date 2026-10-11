ITB=build/out/chip.itb
FLASH=build/out/flash-uboot.cmd
PAGE_WITH_OOB=$((0x4000 + 0x500))

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

@test "fit fits in a 16 MiB boot volume" {
	[ "$(stat -c %s $ITB)" -le $((0x1000000)) ]
}

@test "u-boot for the nand is u-boot-dtb.bin padded to its 4 MiB partition" {
	[ "$(stat -c %s build/out/uboot-4m.bin)" -eq $((0x400000)) ]
	cmp -n "$(stat -c %s build/out/u-boot-dtb.bin)" build/out/u-boot-dtb.bin build/out/uboot-4m.bin
}

@test "flash script is a u-boot script" {
	dumpimage -l build/out/flash-uboot.scr | grep -q 'Script'
}

@test "flash script erases the spl, its backup and u-boot, and nothing of UBI" {
	grep -qx 'nand erase 0x0 0xc00000' $FLASH
	[ "$(grep -c erase $FLASH)" -eq 1 ]
}

@test "flash script writes the spl raw with its ecc at 0x0 and 0x400000" {
	pages=$(printf '0x%x' $(( ($(stat -c %s build/out/sunxi-spl-with-ecc.bin) + PAGE_WITH_OOB - 1) / PAGE_WITH_OOB )))
	grep -qx "nand write.raw.noverify 0x47000000 0x0 $pages" $FLASH
	grep -qx "nand write.raw.noverify 0x47000000 0x400000 $pages" $FLASH
}

@test "flash script writes u-boot with ecc at 0x800000" {
	grep -qx 'nand write 0x48000000 0x800000 0x400000' $FLASH
}

@test "flash script erases before it writes" {
	[ "$(head -n 1 $FLASH)" = 'nand erase 0x0 0xc00000' ]
	[ "$(wc -l < $FLASH)" -eq 4 ]
}

@test "flash script returns to bootcmd so the board boots the freshly written slots" {
	[ -s $FLASH ]
	run grep -q reset $FLASH
	[ "$status" -ne 0 ]
}
