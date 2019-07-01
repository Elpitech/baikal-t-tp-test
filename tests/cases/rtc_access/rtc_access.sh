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
# Set/get/restore date of rtcX device with specified bus/address pair.
# Date is supposed to be presented in full-format: %F, like %+4Y-%m-%d.
#
# $1 ... Device bus (i2c, spi, pci, etc)
# $2 ... Device address
# $3 ... Date in full-format (%F: %+4Y-%m-%d)
RTC_ARG1_BUS=${1:-"i2c"}
RTC_ARG2_ADDR=${2:-"0-0000"}
RTC_ARG3_DATE=${3:-"2000-01-01"}

RTC_ACCESS_DEPENDS="hwclock date"
RTC_ACCESS_TIMESTAMP=""

prologue() {
	info "=== RTC hardware test prologue ===\n"

	info "Test parameters: bus='%s', addr='%s', date='%s'\n" \
		"$RTC_ARG1_BUS" "$RTC_ARG2_ADDR" "$RTC_ARG3_DATE"

	info "Check test dependencies: %s\n" "$RTC_ACCESS_DEPENDS"
	action test_commands $RTC_ACCESS_DEPENDS

	info "Load RTC TP-test library\n"
	action load_library rtc

	info "Save current system time stamp\n"
	action "RTC_ACCESS_TIMESTAMP=$(date +%s)"

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console NOTICE (%d) loglevel\n" "$LOGLEVEL_NOTICE"
	action set_loglevel $LOGLEVEL_NOTICE
}

work() {
	local _dev

	info "=== RTC hardware test work procedure ===\n"

	info "Retrieve character device of '%s %s' rtc\n" \
		"$RTC_ARG1_BUS" "$RTC_ARG2_ADDR"
	action '_dev=$(rtc_getdev "$RTC_ARG1_BUS" "$RTC_ARG2_ADDR")'
	info "Character device '%s' detected for '%s %s'\n" \
		"$_dev" "$RTC_ARG1_BUS" "$RTC_ARG2_ADDR"

	info "Set system hardware clocks to be '%s'\n" "$_dev"
	action hwclock -f "$_dev"

	info "Update the system date to '%s'\n" "$RTC_ARG3_DATE"
	action date -s "$RTC_ARG3_DATE" +%F

	info "Update the rtc date with system timespec\n"
	action hwclock -w

	info "Make sure the specified and rtc dates match\n"
	action test "$(rtc_getdate "$_dev")" == "$RTC_ARG3_DATE"
}

epilogue() {
	info "=== RTC hardware test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	info "Restore the system timestamp '%s' (+1s for tp-test timer sanity)\n" \
		"$RTC_ACCESS_TIMESTAMP"
	date -s "@$(($RTC_ACCESS_TIMESTAMP + 1))" +%s
	hwclock -w

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
