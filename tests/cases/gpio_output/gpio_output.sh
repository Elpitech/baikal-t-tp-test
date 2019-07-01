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
# Generate a pulse of the specified period on the GPIO pin of
# ID with bus/addr/hwid triple.
#
# $1 ... Output GPIO adapter bus (i2c, soc, spi, etc)
# $2 ... Output GPIO adapter address
# $3 ... Output GPIO HW ID
# $4 ... Pulse period (ms)
GPIO_ARG1_BUS=${1:-"undefined"}
GPIO_ARG2_ADDR=${2:-""}
GPIO_ARG3_HWID=${3:-"0"}
GPIO_ARG4_PERIOD=${4:-"1000"}

GPIO_BASE=""
GPIO_ID=""
GPIO_DIR=""
GPIO_VAL=""

prologue() {
	info "=== GPIO-based pulse generator test prologue ===\n"

	info "Test parameters: bus='%s', addr='%s', hwid='%u', period='%u'\n" \
		"$GPIO_ARG1_BUS" "$GPIO_ARG2_ADDR" "$GPIO_ARG3_HWID" "$GPIO_ARG4_PERIOD"

	info "Load GPIO TP-test library\n"
	action load_library gpio

	info "Find base ID of the GPIO adapter '%s %s'\n" \
		"$GPIO_ARG1_BUS" "$GPIO_ARG2_ADDR"
	action 'GPIO_BASE=$(gpio_getbase "$GPIO_ARG1_BUS" "$GPIO_ARG2_ADDR")'
	info "GPIO adapter '%s %s' corresponds to 'gpiochip%u'\n" \
		"$GPIO_ARG1_BUS" "$GPIO_ARG2_ADDR" "$GPIO_BASE"

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console WARNING (%d) loglevel\n" "$LOGLEVEL_WARNING"
	action set_loglevel $LOGLEVEL_WARNING

	info "Request GPIO HW %u from 'gpiochip%u'\n" \
		"$GPIO_ARG3_HWID" "$GPIO_BASE"
	action 'GPIO_ID=$(gpio_request "$GPIO_BASE" "$GPIO_ARG3_HWID")'

	info "Get GPIO %u direction\n" "$GPIO_ID"
	action 'GPIO_DIR=$(gpio_get_direction "$GPIO_ID")'
	info "GPIO %u direction is '%s'\n" "$GPIO_ID" "$GPIO_DIR"

	if [ "$GPIO_DIR" != 'out' ]; then
		info "Set GPIO %u direction to 'out'\n" "$GPIO_ID"
		action gpio_set_direction "$GPIO_ID" 'out'
	fi

	info "Store GPIO %u initial value\n" "$GPIO_ID"
	action 'GPIO_VAL=$(gpio_get_value "$GPIO_ID")'
}

work() {
	info "=== GPIO-based pulse generator test work procedure ===\n"

	info "Generate pulse with period '%u' ms on GPIO %u\n" "$GPIO_ARG4_PERIOD" "$GPIO_ID"
	action gpio_generate_pulse "$GPIO_ID" "$GPIO_ARG4_PERIOD"
}

epilogue() {
	info "=== GPIO-based pulse generator test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	if [ -n "$GPIO_VAL" ]; then
		info "Restore GPIO %u initial value '%u'\n" "$GPIO_ID" "$GPIO_VAL"
		gpio_set_value "$GPIO_ID" "$GPIO_VAL"
	fi

	if [ -n "$GPIO_DIR" -a "$GPIO_DIR" != "out" ]; then
		info "Restore GPIO %u direction '%s'\n" "$GPIO_ID" "$GPIO_DIR"
		gpio_set_direction "$GPIO_ID" "$GPIO_DIR"
	fi

	if [ -n "$GPIO_ID" ]; then
		info "Free GPIO %u\n" "$GPIO_ID"
		gpio_free "$GPIO_ID"
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
