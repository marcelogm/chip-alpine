load helpers

@test "fel-ram fragment is applied to the u-boot config" {
	assert_fragment_applied uboot/fel-ram.config build/uboot/.config
}

@test "u-boot with spl is built" {
	[ -s build/out/u-boot-sunxi-with-spl.bin ]
}

@test "u-boot source scrambles data on the toshiba mlc nand like linux does" {
	grep -q 'NAND_NEED_SCRAMBLING' build/src/u-boot-2026.07/drivers/mtd/nand/raw/nand_toshiba.c
}
