CPIO=build/out/initramfs.cpio.gz

listing() {
	gzip -dc $CPIO | cpio -t --quiet
}

@test "init interpreter exists at /bin/busybox" {
	dir=$(mktemp -d)
	gzip -dc $CPIO | (cd "$dir" && cpio -id --quiet)
	[ -x "$dir/bin/busybox" ]
	rm -rf "$dir"
}

@test "init is executable" {
	gzip -dc $CPIO | cpio -tv --quiet | grep -qE '^-rwx.* init$'
}

@test "inittab spawns a shell on the usb serial console" {
	gzip -dc $CPIO | cpio -i --to-stdout --quiet etc/inittab | grep -q '^ttyGS0::respawn:'
}

@test "wifi tools are included" {
	listing | grep -qE '(^|/)wpa_supplicant$'
	listing | grep -qE '(^|/)iw$'
}

@test "wifi driver and firmware are included" {
	listing | grep -qE '(^|/)lib/modules/[^/]+/kernel/drivers/staging/rtl8723bs/r8723bs.ko$'
	listing | grep -qE '(^|/)lib/firmware/rtlwifi/rtl8723bs_nic.bin$'
}

@test "usb gadget script is included" {
	listing | grep -qx 'usr/sbin/chip-usb-gadget'
}

@test "boot slot writer and its tools are included" {
	listing | grep -qx 'usr/sbin/chip-boot-write'
	listing | grep -qE '(^|/)ubiattach$'
	listing | grep -qE '(^|/)ubiupdatevol$'
}

@test "ubi formatter and its tools are included" {
	listing | grep -qx 'usr/sbin/chip-ubi-format'
	listing | grep -qE '(^|/)ubiformat$'
	listing | grep -qE '(^|/)ubidetach$'
	listing | grep -qE '(^|/)ubimkvol$'
}
