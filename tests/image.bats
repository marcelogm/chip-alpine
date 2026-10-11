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

@test "fit fits in a 32 MiB boot slot and below the scripts at 0x44000000" {
	[ "$(stat -c %s $ITB)" -lt $((0x2000000)) ]
}

@test "ram boot script boots the fit sunxi-fel left at 0x42000000" {
	dumpimage -l build/out/boot-ram.scr | grep -q 'Script'
	grep -qF 'chip.slot=ram' image/boot-ram.cmd
	grep -qx 'bootm 0x42000000' image/boot-ram.cmd
}

@test "flash script writes the spl and its backup raw, with ecc already in the image" {
	pages=$(( ($(stat -c %s build/out/sunxi-spl-with-ecc.bin) + PAGE_WITH_OOB - 1) / PAGE_WITH_OOB ))
	grep -qx "nand write.raw.noverify 0x44100000 0x0 $(printf '0x%x' $pages)" $FLASH
	grep -qx "nand write.raw.noverify 0x44100000 0x400000 $(printf '0x%x' $pages)" $FLASH
}

@test "flash script writes u-boot where the spl looks for it" {
	grep -qx 'nand write 0x44200000 0x800000 0x100000' $FLASH
}

@test "flash script resets only when u-boot reads back intact" {
	size=$(printf '0x%x' "$(stat -c %s build/out/u-boot.img)")
	grep -qx "if cmp.b 0x44200000 0x45000000 $size; then reset; fi" $FLASH
	[ "$(tail -n 1 $FLASH)" = "if cmp.b 0x44200000 0x45000000 $size; then reset; fi" ]
	dumpimage -l build/out/flash-uboot.scr | grep -q 'Script'
}
