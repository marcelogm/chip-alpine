load helpers

SRC=build/src/u-boot-2022.01
PAGE_WITH_OOB=$((0x4000 + 0x500))

@test "chip fragment is applied to the u-boot config" {
	assert_fragment_applied uboot/chip.config build/uboot/.config
}

@test "u-boot with spl is built" {
	[ -s build/out/u-boot-sunxi-with-spl.bin ]
}

@test "spl with ecc for the boot rom is built" {
	[ -s build/out/sunxi-spl-with-ecc.bin ]
}

@test "spl with ecc is whole pages with their oob" {
	[ $(( $(stat -c %s build/out/sunxi-spl-with-ecc.bin) % PAGE_WITH_OOB )) -eq 0 ]
}

@test "u-boot fits in the 4 MiB uboot partition" {
	[ -s build/out/u-boot-dtb.bin ]
	[ "$(stat -c %s build/out/u-boot-dtb.bin)" -le $((0x400000)) ]
}

@test "u-boot emulates slc on the mlc nand the way linux does" {
	grep -q 'mtd_set_pairing_scheme(mtd, &dist3_pairing_scheme)' $SRC/drivers/mtd/nand/raw/nand_base.c
}

@test "spl reads the nand with dma on sun5i" {
	grep -q 'SUNXI_DMA_DDMA_CFG_REG_DDMA_SRC_DRQ_TYPE_NFC' $SRC/drivers/mtd/nand/raw/sunxi_nand_spl.c
}

@test "u-boot never writes a bad block table to the nand" {
	run fdtget build/uboot/u-boot.dtb /soc@1c00000/nand@1c03000/nand@0 nand-on-flash-bbt
	[ "$status" -ne 0 ]
	fdtget build/uboot/u-boot.dtb /soc@1c00000/nand@1c03000/nand@0 reg
}

@test "binman builds without pkg_resources" {
	run grep -q pkg_resources $SRC/tools/binman/control.py
	[ "$status" -ne 0 ]
}

uboot_env() {
	tr '\0' '\n' < build/uboot/u-boot-initial-env | grep -x "$1=.*"
}

@test "u-boot runs the script sunxi-fel left in ram before booting from the nand" {
	uboot_env bootcmd | grep -q '^bootcmd=setenv chip_bootargs console=ttyS0,115200 panic=10; run bootcmd_fel; ubi part UBI;'
}

@test "u-boot boots boot-a from UBI and tells the kernel" {
	uboot_env bootcmd | grep -qF '; ubi read 0x42000000 boot-a && setenv bootargs ${chip_bootargs} chip.slot=a && bootm 0x42000000;'
}

@test "u-boot falls back to boot-b from UBI and tells the kernel" {
	uboot_env bootcmd | grep -qF '; ubi read 0x42000000 boot-b && setenv bootargs ${chip_bootargs} chip.slot=b && bootm 0x42000000'
}

@test "u-boot tries boot-a before boot-b" {
	uboot_env bootcmd | grep -q 'boot-a.*boot-b'
}

@test "u-boot stops when neither slot boots instead of resetting" {
	run uboot_env bootcmd
	[ "$status" -eq 0 ]
	[[ "$output" != *reset* ]]
}
