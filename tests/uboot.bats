load helpers

@test "fel-ram fragment is applied to the u-boot config" {
	assert_fragment_applied uboot/fel-ram.config build/uboot/.config
}

@test "u-boot with spl is built" {
	[ -s build/out/u-boot-sunxi-with-spl.bin ]
}
