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
# Find PCI device address by given VID/DID pair.
#
# $1 ... Vendor ID (in hex, with or without 0x prefix)
# $2 ... Device ID (in hex, with or without 0x prefix)
PCI_ARG1_VID=${1:-"0x1d39"}
PCI_ARG2_DID=${2:-"0x8060"}

prologue() {
	info "=== PCI device detection test prologue ===\n"

	info "Test parameters: vid='%s', did='%s'\n" "$PCI_ARG1_VID" "$PCI_ARG2_DID"

	info "Load PCI TP-test library\n"
	action load_library pci

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue
}

work() {
	local _dbsf

	info "=== PCI device detection test work procedure ===\n"

	info "Retrieve DOMAIN:BUS:SLOT.func of '%s:%s'\n" \
		"$PCI_ARG1_VID" "$PCI_ARG2_DID"
	action '_dbsf=$(pci_getdev "$PCI_ARG1_VID" "$PCI_ARG2_DID")'
	info "Device '%s:%s' detected on '%s'\n" \
		"$PCI_ARG1_VID" "$PCI_ARG2_DID" "$_dbsf"

	info "Device '%s' info:\n" "$_dbsf"
	action pci_getinfo "$_dbsf"
}

epilogue() {
	info "=== PCI device detection test epilogue ===\n"

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
