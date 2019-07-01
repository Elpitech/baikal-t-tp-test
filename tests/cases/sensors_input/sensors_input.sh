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
# Get input from hwmonX device with specified bus/address pair
# and test it to be within the defined range.
#
# $1 ... Device bus (i2c, spi, pci, soc, etc)
# $2 ... Device address
# $3 ... Type (temp1, temp2, in1, etc)
# $4 ... Minimum value
# $5 ... Maximum value
SENSORS_ARG1_BUS=${1:-"i2c"}
SENSORS_ARG2_ADDR=${2:-"0-0000"}
SENSORS_ARG3_TYPE=${3:-"temp1"}
SENSORS_ARG4_MIN=${4:-"0"}
SENSORS_ARG5_MAX=${5:-"100"}

prologue() {
	info "=== Sensors input test prologue ===\n"

	info "Test parameters: bus='%s', addr='%s', type='%s', min='%.3f', max='%.3f'\n" \
		"$SENSORS_ARG1_BUS" "$SENSORS_ARG2_ADDR" "$SENSORS_ARG3_TYPE" \
		"$SENSORS_ARG4_MIN" "$SENSORS_ARG5_MAX"

	info "Load sensors TP-test library\n"
	action load_library sensors

	info "Setup test cleanup method\n"
	set_cleanup_method epilogue
}

work() {
	local _dev
	local _input

	info "=== Sensors input test work procedure ===\n"

	info "Find hwmon device of '%s %s' sensor\n" \
		"$SENSORS_ARG1_BUS" "$SENSORS_ARG2_ADDR"
	action '_dev=$(sensors_gethwmon $SENSORS_ARG1_BUS $SENSORS_ARG2_ADDR)'
	info "'%s' hwmon device detected for '%s %s'\n" \
		"$_dev" "$SENSORS_ARG1_BUS" "$SENSORS_ARG2_ADDR"

	info "Read input from the sensor\n"
	action '_input=$(sensors_getinput "$_dev" "$SENSORS_ARG3_TYPE")'
	info "Hwmon '%s' returned '%.3f' input\n" "$_dev" "$_input"

	info "Make sure the input is in the range [%.3f, %.3f]\n" \
		"$SENSORS_ARG4_MIN" "$SENSORS_ARG5_MAX"
	action test '$(calc "$SENSORS_ARG4_MIN <= $_input && $_input <= $SENSORS_ARG5_MAX")' -eq "1"
}

epilogue() {
	info "=== Sensors input test epilogue ===\n"

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
