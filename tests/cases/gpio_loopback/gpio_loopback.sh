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
# Perform loopback connectivity test of two GPIOs wired one to another.
# It is done unidirectionally, so a value !ini->ini is set to out_* GPIO and
# expected to be detected on the in_* GPIO.
#
# $1 ... Output GPIO adapter bus (i2c, soc, spi, etc)
# $2 ... Output GPIO adapter address
# $3 ... Output GPIO HW ID
# $4 ... Input GPIO adapter bus (i2c, soc, spi, etc)
# $5 ... Input GPIO adapter address
# $6 ... Input GPIO HW ID
# $7 ... Inverted value flag
GPIO_ARG1_OUT_BUS=${1:-"undefined"}
GPIO_ARG2_OUT_ADDR=${2:-""}
GPIO_ARG3_OUT_HWID=${3:-"0"}
GPIO_ARG4_IN_BUS=${4:-"undefined"}
GPIO_ARG5_IN_ADDR=${5:-""}
GPIO_ARG6_IN_HWID=${6:-"0"}
GPIO_ARG7_INVERTED=${7:-"no"}

GPIO_OUT_BASE=""
GPIO_OUT_ID=""
GPIO_OUT_DIR=""
GPIO_OUT_VAL=""
GPIO_IN_BASE=""
GPIO_IN_ID=""
GPIO_IN_DIR=""

prologue() {
	info "=== GPIO loopback test prologue ===\n"

	info "Test parameters: out_bus='%s', out_addr='%s', out_hwid='%u'\n" \
		"$GPIO_ARG1_OUT_BUS" "$GPIO_ARG2_OUT_ADDR" "$GPIO_ARG3_OUT_HWID"
	info "Test parameters: in_bus='%s', in_addr='%s', in_hwid='%u'\n" \
		"$GPIO_ARG4_IN_BUS" "$GPIO_ARG5_IN_ADDR" "$GPIO_ARG6_IN_HWID"
	info "Test parameters: inverted='%s'\n" "$GPIO_ARG7_INVERTED"

	info "Load GPIO TP-test library\n"
	action load_library gpio

	info "Find base ID of the input GPIO adapter '%s %s'\n" \
		"$GPIO_ARG4_IN_BUS" "$GPIO_ARG5_IN_ADDR"
	action 'GPIO_IN_BASE=$(gpio_getbase "$GPIO_ARG4_IN_BUS" "$GPIO_ARG5_IN_ADDR")'
	info "GPIO adapter '%s %s' corresponds to 'gpiochip%u'\n" \
		"$GPIO_ARG4_IN_BUS" "$GPIO_ARG5_IN_ADDR" "$GPIO_IN_BASE"

	info "Find base ID of the output GPIO adapter '%s %s'\n" \
		"$GPIO_ARG1_OUT_BUS" "$GPIO_ARG2_OUT_ADDR"
	action 'GPIO_OUT_BASE=$(gpio_getbase "$GPIO_ARG1_OUT_BUS" "$GPIO_ARG2_OUT_ADDR")'
	info "GPIO adapter '%s %s' corresponds to 'gpiochip%u'\n" \
		"$GPIO_ARG1_OUT_BUS" "$GPIO_ARG2_OUT_ADDR" "$GPIO_OUT_BASE"

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console WARNING (%d) loglevel\n" "$LOGLEVEL_WARNING"
	action set_loglevel $LOGLEVEL_WARNING

	info "Request input GPIO HW %u from 'gpiochip%u'\n" \
		"$GPIO_ARG6_IN_HWID" "$GPIO_IN_BASE"
	action 'GPIO_IN_ID=$(gpio_request "$GPIO_IN_BASE" "$GPIO_ARG6_IN_HWID")'

	info "Request output GPIO HW %u from 'gpiochip%u'\n" \
		"$GPIO_ARG3_OUT_HWID" "$GPIO_OUT_BASE"
	action 'GPIO_OUT_ID=$(gpio_request "$GPIO_OUT_BASE" "$GPIO_ARG3_OUT_HWID")'

	info "Get input GPIO %u direction\n" "$GPIO_IN_ID"
	action 'GPIO_IN_DIR=$(gpio_get_direction "$GPIO_IN_ID")'
	info "Input GPIO %u direction is '%s'\n" "$GPIO_IN_ID" "$GPIO_IN_DIR"

	if [ "$GPIO_IN_DIR" != 'in' ]; then
		info "Set input GPIO %u direction\n" "$GPIO_IN_ID"
		action gpio_set_direction "$GPIO_IN_ID" 'in'
	fi

	info "Get output GPIO %u direction\n" "$GPIO_OUT_ID"
	action 'GPIO_OUT_DIR=$(gpio_get_direction "$GPIO_OUT_ID")'
	info "Output GPIO %u direction is '%s'\n" "$GPIO_OUT_ID" "$GPIO_OUT_DIR"

	if [ "$GPIO_OUT_DIR" != 'out' ]; then
		info "Set output GPIO %u direction\n" "$GPIO_OUT_ID"
		action gpio_set_direction "$GPIO_OUT_ID" 'out'
	fi

	info "Store output GPIO %u initial value\n" "$GPIO_OUT_ID"
	action 'GPIO_OUT_VAL=$(gpio_get_value "$GPIO_OUT_ID")'
}

work() {
	local _out _in

	info "=== GPIO loopback test work procedure ===\n"

	for _out in "$((! GPIO_OUT_VAL))" "$((!! GPIO_OUT_VAL))"; do
		info "Set value '%u' to the output GPIO %u\n" "$_out" "$GPIO_OUT_ID"
		action gpio_set_value "$GPIO_OUT_ID" "$_out"

		info "Get value from the input GPIO %u\n" "$GPIO_IN_ID"
		action '_in=$(gpio_get_value "$GPIO_IN_ID")'

		if bool "$GPIO_ARG7_INVERTED" 'yes'; then
			_in=$((! _in))
			info "Make sure the output '%u' and inverted input values '%u' match\n" \
				"$_out" "$_in"
		else
			info "Make sure the output '%u' and input values '%u' match\n" \
				"$_out" "$_in"
		fi
		action test "$_out" -eq "$_in"
	done
}

epilogue() {
	info "=== GPIO loopback test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	if [ -n "$GPIO_OUT_VAL" ]; then
		info "Restore output GPIO %u initial value '%u'\n" \
			"$GPIO_OUT_ID" "$GPIO_OUT_VAL"
		gpio_set_value "$GPIO_OUT_ID" "$GPIO_OUT_VAL"
	fi

	if [ -n "$GPIO_OUT_DIR" -a "$GPIO_OUT_DIR" != "out" ]; then
		info "Restore output GPIO %u direction '%s'\n" \
			"$GPIO_OUT_ID" "$GPIO_OUT_DIR"
		gpio_set_direction "$GPIO_OUT_ID" "$GPIO_OUT_DIR"
	fi

	if [ -n "$GPIO_OUT_ID" ]; then
		info "Free output GPIO %u\n" "$GPIO_OUT_ID"
		gpio_free "$GPIO_OUT_ID"
	fi

	if [ -n "$GPIO_IN_DIR" -a "$GPIO_IN_DIR" != "in" ]; then
		info "Restore input GPIO %u direction '%s'\n" "$GPIO_IN_ID" "$GPIO_IN_DIR"
		gpio_set_direction "$GPIO_IN_ID" "$GPIO_IN_DIR"
	fi

	if [ -n "$GPIO_IN_ID" ]; then
		info "Free input GPIO %u\n" "$GPIO_IN_ID"
		gpio_free "$GPIO_IN_ID"
	fi

	info "Restore previous system console loglevel\n"
	reset_loglevel
}

main() {
	prologue

	work	

	epilogue

	exit $SUCCESS
}

main "$@"
