setup() {
	CONFIGFS=$(mktemp -d)
	UDC_CLASS=$(mktemp -d)
	touch "$UDC_CLASS/musb-hdrc.1.auto"
	initramfs/rootfs/usr/sbin/chip-usb-gadget "$CONFIGFS" "$UDC_CLASS"
	G=$CONFIGFS/usb_gadget/chip
}

teardown() {
	rm -rf "$CONFIGFS" "$UDC_CLASS"
}

@test "gadget binds to the first udc" {
	[ "$(cat "$G/UDC")" = musb-hdrc.1.auto ]
}

@test "serial console function is in the configuration" {
	[ "$(readlink "$G/configs/c.1/acm.usb0")" = "$G/functions/acm.usb0" ]
}

@test "ethernet function is in the configuration" {
	[ "$(readlink "$G/configs/c.1/ncm.usb0")" = "$G/functions/ncm.usb0" ]
}

@test "gadget identifies itself as chip-alpine" {
	[ "$(cat "$G/strings/0x409/product")" = chip-alpine ]
}
