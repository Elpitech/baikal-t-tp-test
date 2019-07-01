#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

if ! source "${TPTEST_ROOT:-/etc/tp-test}/lib/shell/core.sh"; then
	printf "Failed to load core library" >&2
	exit 1
fi

#
# Perfor mtd-test over a flash device with specified bus/address pair.
# The test is performed 'passed' times with 'checks' reads/check cycles
# over the frist 'length' memory region.
#
# $1 ... Device bus (soc, spi, i2c, etc)
# $2 ... Device address
# $3 ... Memory block length to test
# $4 ... Number of tests cycles
# $5 ... Number of read/check cycles
FLASH_ARG1_BUS=${1:-"soc"}
FLASH_ARG2_ADDR=${2:-"soc0/apb/1f04e000.spi0/spi_master/spi0/spi0.0"}
FLASH_ARG3_LENGTH=${3:-"4096"}
FLASH_ARG4_PASSES=${4:-"1"}
FLASH_ARG5_CHECKS=${5:-"1"}

prologue() {
	info "=== MTD flash write/read test prologue ===\n"

	info "Test parameters: bus='%s', addr='%s'\n" \
		"$FLASH_ARG1_BUS" "$FLASH_ARG2_ADDR"
	info "Test parameters: length='%u', passes='%u', checks='%u'\n" \
		"$FLASH_ARG3_LENGTH" "$FLASH_ARG4_PASSES" "$FLASH_ARG5_CHECKS"

	info "Load flash TP-test library\n"
	action load_library flash

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue
}

work() {
	local _mtd

	info "=== MTD flash write/read test work procedure ===\n"

	info "Retrieve MTD device of '%s %s' flash\n" \
		"$FLASH_ARG1_BUS" "$FLASH_ARG2_ADDR"
	action '_mtd=$(flash_getmtd "$FLASH_ARG1_BUS" "$FLASH_ARG2_ADDR")'
	info "MTD block device '%s' detected for '%s %s'\n" \
		"$_mtd" "$FLASH_ARG1_BUS" "$FLASH_ARG2_ADDR"

	info "Launch MTD-test over '%s':\n" "$_mtd"
	action flash_nandtest "$_mtd" "$FLASH_ARG3_LENGTH" "$FLASH_ARG4_PASSES" "$FLASH_ARG5_CHECKS"
}

epilogue() {
	info "=== MTD flash write/read test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method
}

main() {
	prologue

	work	

	epilogue

	exit $SUCCESS
}

main "$@"
