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
# Perform the timing test of the storage with specified interface and
# port. Cached and buffered disk performance is retieved by means of
# hdparm utility.
#
# $1 ... Device interface (sata, usb, mmc)
# $2 ... Port (scsi host for sata, device id for usb and interface number for mmc)
# $3 ... Lowest limit of cached read timings
# $4 ... Lowest limit of buffered disk read timings
STORAGE_ARG1_IFACE=${1:-"sata"}
STORAGE_ARG2_PORT=${2:-"0"}
STORAGE_ARG3_CACHED=${3:-"0.0"}
STORAGE_ARG4_BUFFERED=${4:-"0.0"}

STORAGE_TIMINGS_DEPENDS="lsscsi hdparm"

prologue() {
	info "=== Storage timings test prologue ===\n"

	info "Test parameters: iface='%s', port='%s', cached='%f', buffered='%f'\n" \
		"$STORAGE_ARG1_IFACE" "$STORAGE_ARG2_PORT" \
		"$STORAGE_ARG3_CACHED" "$STORAGE_ARG4_BUFFERED"

	info "Check test dependencies: %s\n" "$STORAGE_TIMINGS_DEPENDS"
	action test_commands $STORAGE_TIMINGS_DEPENDS

	info "Load Storage TP-test library\n"
	action load_library storage

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console NOTICE (%d) loglevel\n" "$LOGLEVEL_NOTICE"
	action set_loglevel $LOGLEVEL_NOTICE
}

work() {
	local _buffered
	local _cached
	local _dev

	info "=== Storage timings test work procedure ===\n"

	info "Retrieve device name of storage on '%s %s' port\n" \
		"$STORAGE_ARG1_IFACE" "$STORAGE_ARG2_PORT"
	action '_dev=$(storage_getdev $STORAGE_ARG1_IFACE $STORAGE_ARG2_PORT)'
	info "Device '%s' detected on the '%s %s' port\n" "$_dev" \
		"$STORAGE_ARG1_IFACE" "$STORAGE_ARG2_PORT"

	info "Retrieve deivce '%s' cached and disk buffered timings\n" "$_dev"
	action "_cached=$(storage_get_cached_timings ${_dev})"
	action "_buffered=$(storage_get_buffered_timings ${_dev})"
	info "Device '%s' timings: cached %s MB/s and buffered %s MB/s\n" \
		"$_dev" "$_cached" "$_buffered"

	info "Check the calculated timings limits\n"
	action test '$(calc "$_cached >= $STORAGE_ARG3_CACHED")' -eq "1"
	action test '$(calc "$_buffered >= $STORAGE_ARG4_BUFFERED")' -eq "1"
}

epilogue() {
	info "=== Storage timings test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

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
