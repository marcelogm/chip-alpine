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

@test "gadget waits for the udc to appear" {
	configfs=$(mktemp -d)
	udc_class=$(mktemp -d)
	(sleep 1; touch "$udc_class/musb-hdrc.1.auto") &
	initramfs/rootfs/usr/sbin/chip-usb-gadget "$configfs" "$udc_class"
	[ "$(cat "$configfs/usb_gadget/chip/UDC")" = musb-hdrc.1.auto ]
	rm -rf "$configfs" "$udc_class"
}

@test "gadget asks the host for 500 mA" {
	[ "$(cat "$G/configs/c.1/MaxPower")" = 500 ]
}

@test "usb ethernet addresses are the same on every boot" {
	[ "$(cat "$G/functions/ncm.usb0/host_addr")" = 02:c4:1b:00:00:01 ]
	[ "$(cat "$G/functions/ncm.usb0/dev_addr")" = 02:c4:1b:00:00:02 ]
}
