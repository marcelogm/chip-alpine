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

@test "data writer is included" {
	listing | grep -qx 'usr/sbin/chip-data-write'
}

@test "ubi formatter and its tools are included" {
	listing | grep -qx 'usr/sbin/chip-ubi-format'
	listing | grep -qE '(^|/)ubiformat$'
	listing | grep -qE '(^|/)ubidetach$'
	listing | grep -qE '(^|/)ubimkvol$'
}

@test "init stays in the rescue shell when booted from ram" {
	gzip -dc $CPIO | cpio -i --to-stdout --quiet init | grep -q 'chip.slot=ram'
}

@test "init switches to the diskless system from the data volume" {
	gzip -dc $CPIO | cpio -i --to-stdout --quiet init | grep -q 'switch_root /sysroot /sbin/init'
	listing | grep -qx 'usr/sbin/chip-diskless-root'
	listing | grep -qE '(^|/)sbin/apk$'
}

@test "init keeps the root and /run of the diskless system closed to other users" {
	gzip -dc $CPIO | cpio -i --to-stdout --quiet init | grep -qx 'mount -t tmpfs -o mode=0755,nosuid,nodev tmpfs /run'
	gzip -dc $CPIO | cpio -i --to-stdout --quiet init | grep -q 'mount -t tmpfs -o mode=0755 tmpfs /sysroot'
}
