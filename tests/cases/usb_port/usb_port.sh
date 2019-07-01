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
# Perform a USB port test by simply checking whether the corresponding
# sysfs node exist when any device is connected to it.
#
# $1 ... Port (scsi host for sata, device id for usb and interface number for mmc)
USB_ARG1_PORT=${1:-"1-1"}

prologue() {
	info "=== Storage timings test prologue ===\n"

	info "Test parameters: port='%s'\n" "$USB_ARG1_PORT"

	info "Load USB TP-test library\n"
	action load_library usb

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console NOTICE (%d) loglevel\n" "$LOGLEVEL_NOTICE"
	action set_loglevel $LOGLEVEL_NOTICE
}

work() {
	info "=== USB port test work procedure ===\n"

	info "Check whether the USB port '%s' exists\n" "$USB_ARG1_PORT"
	action usb_check_port "$USB_ARG1_PORT"
}

epilogue() {
	info "=== USB port test epilogue ===\n"

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
