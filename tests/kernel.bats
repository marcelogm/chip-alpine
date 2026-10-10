load helpers

@test "chip fragment is applied to the kernel config" {
	assert_fragment_applied kernel/chip.config build/kernel/.config
}

@test "zImage is built" {
	[ -s build/out/zImage ]
}

@test "wifi driver module is installed" {
	compgen -G 'build/modules/lib/modules/*/kernel/drivers/staging/rtl8723bs/r8723bs.ko'
}
