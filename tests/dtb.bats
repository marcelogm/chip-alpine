DTB=build/out/sun5i-r8-chip-alpine.dtb
NAND=/soc/nand-controller@1c03000

@test "nand controller is enabled" {
	[ "$(fdtget -t s $DTB $NAND status)" = okay ]
}

@test "whole nand is a single read-only partition" {
	[ "$(fdtget -t s $DTB $NAND/nand@0/partitions/partition@0 label)" = nand ]
	fdtget $DTB $NAND/nand@0/partitions/partition@0 read-only
}

@test "kernel never writes a bad block table to the nand" {
	run fdtget $DTB $NAND/nand@0 nand-on-flash-bbt
	[ "$status" -ne 0 ]
}

@test "usb otg port is a peripheral" {
	[ "$(fdtget -t s $DTB /soc/usb@1c13000 dr_mode)" = peripheral ]
}
