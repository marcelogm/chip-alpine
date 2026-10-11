DTB=build/out/sun5i-r8-chip-alpine.dtb
NAND=/soc/nand-controller@1c03000
PARTS=$NAND/nand@0/partitions

@test "nand controller is enabled" {
	[ "$(fdtget -t s $DTB $NAND status)" = okay ]
}

@test "nand is split into the spl, its backup, u-boot and UBI" {
	[ "$(fdtget -l $DTB $PARTS | tr '\n' ' ')" = "partition@0 partition@400000 partition@800000 partition@c00000 " ]
	[ "$(fdtget -t s $DTB $PARTS/partition@0 label)" = spl ]
	[ "$(fdtget -t s $DTB $PARTS/partition@400000 label)" = spl-backup ]
	[ "$(fdtget -t s $DTB $PARTS/partition@800000 label)" = uboot ]
	[ "$(fdtget -t s $DTB $PARTS/partition@c00000 label)" = UBI ]
}

@test "spl, its backup and u-boot are 4 MiB each" {
	[ "$(fdtget -t x $DTB $PARTS/partition@0 reg)" = "0 0 0 400000" ]
	[ "$(fdtget -t x $DTB $PARTS/partition@400000 reg)" = "0 400000 0 400000" ]
	[ "$(fdtget -t x $DTB $PARTS/partition@800000 reg)" = "0 800000 0 400000" ]
}

@test "UBI runs from right after u-boot to the end of the 8 GiB nand" {
	[ "$(fdtget -t x $DTB $PARTS/partition@c00000 reg)" = "0 c00000 1 ff400000" ]
}

@test "linux leaves the spl, its backup and u-boot read-only" {
	fdtget $DTB $PARTS/partition@0 read-only
	fdtget $DTB $PARTS/partition@400000 read-only
	fdtget $DTB $PARTS/partition@800000 read-only
}

@test "linux writes UBI" {
	run fdtget $DTB $PARTS/partition@c00000 read-only
	[ "$status" -ne 0 ]
}

@test "linux uses the ecc the spl auto-detects on the nand" {
	[ "$(fdtget $DTB $NAND/nand@0 nand-ecc-strength)" = 40 ]
	[ "$(fdtget $DTB $NAND/nand@0 nand-ecc-step-size)" = 1024 ]
}

@test "UBI partition runs the mlc nand in slc mode" {
	fdtget $DTB $PARTS/partition@c00000 slc-mode
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
