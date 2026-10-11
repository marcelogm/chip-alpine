DTB=build/out/sun5i-r8-chip-alpine.dtb
NAND=/soc/nand-controller@1c03000
PARTS=$NAND/nand@0/partitions

@test "nand controller is enabled" {
	[ "$(fdtget -t s $DTB $NAND status)" = okay ]
}

@test "nand is split into boot and UBI partitions" {
	[ "$(fdtget -t s $DTB $PARTS/partition@0 label)" = spl ]
	[ "$(fdtget -t s $DTB $PARTS/partition@400000 label)" = spl-backup ]
	[ "$(fdtget -t s $DTB $PARTS/partition@800000 label)" = uboot ]
	[ "$(fdtget -t s $DTB $PARTS/partition@c00000 label)" = boot-a ]
	[ "$(fdtget -t s $DTB $PARTS/partition@2c00000 label)" = boot-b ]
	[ "$(fdtget -t s $DTB $PARTS/partition@4c00000 label)" = UBI ]
}

@test "linux writes the spl, its backup, the boot slots and UBI" {
	for p in partition@0 partition@400000 partition@c00000 partition@2c00000 partition@4c00000; do
		run fdtget $DTB $PARTS/$p read-only
		[ "$status" -ne 0 ]
	done
}

@test "linux leaves the unused uboot partition read-only" {
	fdtget $DTB $PARTS/partition@800000 read-only
}

@test "linux uses the ecc the spl auto-detects on the nand" {
	[ "$(fdtget $DTB $NAND/nand@0 nand-ecc-strength)" = 40 ]
	[ "$(fdtget $DTB $NAND/nand@0 nand-ecc-step-size)" = 1024 ]
}

@test "UBI partition runs the mlc nand in slc mode" {
	fdtget $DTB $PARTS/partition@4c00000 slc-mode
}

@test "boot slots run the mlc nand in slc mode" {
	fdtget $DTB $PARTS/partition@c00000 slc-mode
	fdtget $DTB $PARTS/partition@2c00000 slc-mode
}

@test "kernel never writes a bad block table to the nand" {
	run fdtget $DTB $NAND/nand@0 nand-on-flash-bbt
	[ "$status" -ne 0 ]
}

@test "usb otg port is a peripheral" {
	[ "$(fdtget -t s $DTB /soc/usb@1c13000 dr_mode)" = peripheral ]
}

@test "status led blinks while the kernel boots" {
	[ "$(fdtget -t s $DTB /leds/led-0 linux,default-trigger)" = heartbeat ]
}
