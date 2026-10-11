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

uboot_env() {
	strings build/uboot/u-boot.bin | grep -x "$1=.*"
}

@test "u-boot runs the script sunxi-fel left in ram instead of the nand slots" {
	uboot_env bootcmd | grep -qx 'bootcmd=run chip_boot'
	uboot_env chip_boot | grep -q '^chip_boot=if test -n "${fel_scriptaddr}"; then source ${fel_scriptaddr}; else run chip_boot_a; run chip_boot_b; fi; run chip_rescue$'
}

@test "u-boot boots boot-a and tells the kernel which slot it used" {
	uboot_env chip_boot_a | grep -qF 'nand read ${chip_load} 0xc00000 0x2000000'
	uboot_env chip_boot_a | grep -qF 'chip.slot=a'
}

@test "u-boot falls back to boot-b" {
	uboot_env chip_boot_b | grep -qF 'nand read ${chip_load} 0x2c00000 0x2000000'
	uboot_env chip_boot_b | grep -qF 'chip.slot=b'
}

@test "u-boot opens a usb serial console when no slot boots" {
	uboot_env chip_rescue | grep -qF 'setenv stdout serial,usbacm'
}

@test "u-boot starts the usb controller before opening the rescue console" {
	grep -q 'int board_usb_init' build/src/u-boot-2026.07/board/sunxi/board.c
}
