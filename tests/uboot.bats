load helpers

@test "chip fragment is applied to the u-boot config" {
	assert_fragment_applied uboot/chip.config build/uboot/.config
}

@test "u-boot with spl is built" {
	[ -s build/out/u-boot-sunxi-with-spl.bin ]
}

@test "u-boot source scrambles data on the toshiba mlc nand like linux does" {
	grep -q 'NAND_NEED_SCRAMBLING' build/src/u-boot-2026.07/drivers/mtd/nand/raw/nand_toshiba.c
}

UDTB=build/uboot/u-boot.dtb
UNAND=/soc/nand-controller@1c03000

@test "u-boot device tree enables the nand controller" {
	[ "$(fdtget -t s $UDTB $UNAND status)" = okay ]
}

@test "u-boot uses the same ecc as linux on the nand" {
	[ "$(fdtget $UDTB $UNAND/nand@0 nand-ecc-strength)" = 40 ]
	[ "$(fdtget $UDTB $UNAND/nand@0 nand-ecc-step-size)" = 1024 ]
}

@test "u-boot binary carries the toshiba scrambling fix" {
	strings build/uboot/u-boot | grep -qx 'TC58TEG5DCLTA00'
}

@test "spl with ecc for the boot rom is built" {
	[ -s build/out/sunxi-spl-with-ecc.bin ]
}

@test "u-boot image for the spl fits in the 1 MiB written to the uboot partition" {
	[ -s build/out/u-boot.img ]
	[ "$(stat -c %s build/out/u-boot.img)" -lt $((0x100000)) ]
}
