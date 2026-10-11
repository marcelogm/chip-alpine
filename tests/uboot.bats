load helpers

@test "chip fragment is applied to the u-boot config" {
	assert_fragment_applied uboot/chip.config build/uboot/.config
}

@test "u-boot with spl is built" {
	[ -s build/out/u-boot-sunxi-with-spl.bin ]
}

@test "spl with ecc for the boot rom is built" {
	[ -s build/out/sunxi-spl-with-ecc.bin ]
}

@test "u-boot fits in the 1 MiB that comes before the fit in a boot slot" {
	[ -s build/out/u-boot.bin ]
	[ "$(stat -c %s build/out/u-boot.bin)" -lt $((0x100000)) ]
}

@test "spl tries boot-b when boot-a fails its data crc" {
	grep -q 'spl_nand_image_intact' build/src/u-boot-2026.07/common/spl/spl_nand.c
}

@test "u-boot never touches the nand" {
	run grep -qx 'CONFIG_CMD_NAND=y' build/uboot/.config
	[ "$status" -ne 0 ]
	run fdtget -t s build/uboot/u-boot.dtb /soc/nand-controller@1c03000 status
	[ "$output" != okay ]
}

uboot_env() {
	strings build/uboot/u-boot.bin | grep -x "$1=.*"
}

@test "u-boot runs the script sunxi-fel left in ram instead of booting the slot" {
	uboot_env bootcmd | grep -qx 'bootcmd=run chip_boot'
	uboot_env chip_boot | grep -qxF 'chip_boot=if test -n "${fel_scriptaddr}"; then source ${fel_scriptaddr}; else run chip_boot_nand; fi; reset'
}

@test "u-boot reads the slot from the payload name the spl left at 0x49ffffe0" {
	uboot_env chip_boot_nand | grep -qF 'if itest.s *0x49ffffe0 == boot-b; then setenv chip_slot b; else setenv chip_slot a; fi'
	uboot_env chip_boot_nand | grep -qF 'chip.slot=${chip_slot}'
}

@test "u-boot boots the fit the spl loaded 1 MiB after itself" {
	uboot_env chip_boot_nand | grep -q 'bootm 0x4a100000$'
}
