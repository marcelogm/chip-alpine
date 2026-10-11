setenv bootargs "${chip_bootargs} chip.slot=ram"
bootm 0x42000000
reset
