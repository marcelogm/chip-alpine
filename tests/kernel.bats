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

@test "kernel mounts an ext4 usb stick" {
	for opt in USB_EHCI_HCD USB_OHCI_HCD USB_STORAGE EXT4_FS; do
		grep -qE "^CONFIG_${opt}=(y|m)$" build/kernel/.config || { echo "missing $opt"; return 1; }
	done
}
