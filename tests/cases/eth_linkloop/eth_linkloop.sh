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
# Perform loopbacked low-level (level 2) ping procedure from source interface
# to the destination one. Arguments can be set to the same port. In this case
# the ethernet wire is supposed to be just a stub of loopbacked RX/TX lanes.
#
# $1 ... Linkloop source interface bus
# $2 ... Linkloop source interface physical address
# $3 ... Linkloop destination interface bus
# $4 ... Linkloop destination interface physical address
ETH_ARG1_SRC_BUS=${1:-"soc"}
ETH_ARG2_SRC_ADDR=${2:-"soc0/axi/1f05e000.eth1"}
ETH_ARG3_DST_BUS=${3:-"soc"}
ETH_ARG4_DST_ADDR=${4:-"soc0/axi/1f060000.eth2"}

ETH_LINKLOOP_DEPENDS="linkloop"
ETH_SRC_IFACE=""
ETH_DST_IFACE=""

prologue() {
	info "=== Ethernet loopback test prologue ===\n"

	info "Test parameters: src_bus='%s', src_addr='%s'\n" \
		"$ETH_ARG1_SRC_BUS" "$ETH_ARG2_SRC_ADDR"
	info "Test parameters: dst_bus='%s', dst_addr='%s'\n" \
		"$ETH_ARG3_DST_BUS" "$ETH_ARG4_DST_ADDR"

	info "Check test dependencies: %s\n" "$ETH_LINKLOOP_DEPENDS"
	action test_commands $ETH_LINKLOOP_DEPENDS

	info "Load Ethernet TP-test library\n"
	action load_library eth

	info "Find interface of the source '%s %s' device\n" \
		"$ETH_ARG1_SRC_BUS" "$ETH_ARG2_SRC_ADDR"
	action 'ETH_SRC_IFACE=$(eth_getiface "$ETH_ARG1_SRC_BUS" "$ETH_ARG2_SRC_ADDR")'
	info "Device '%s %s' corresponds to '%s' interface\n" \
		"$ETH_ARG1_SRC_BUS" "$ETH_ARG2_SRC_ADDR" "$ETH_SRC_IFACE"

	info "Find interface of the destination '%s %s' device\n" \
		"$ETH_ARG3_DST_BUS" "$ETH_ARG4_DST_ADDR"
	action 'ETH_DST_IFACE=$(eth_getiface "$ETH_ARG3_DST_BUS" "$ETH_ARG4_DST_ADDR")'
	info "Device '%s %s' corresponds to '%s' interface\n" \
		"$ETH_ARG3_DST_BUS" "$ETH_ARG4_DST_ADDR" "$ETH_DST_IFACE"

	info "Retrieve MAC-address of '%s' interface\n" "$ETH_DST_IFACE"
	action 'ETH_DST_IFACE_MAC=$(eth_getmac ${ETH_DST_IFACE})'
	info "Interface '%s' has MAC %s\n" "$ETH_DST_IFACE" "$ETH_DST_IFACE_MAC"

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console NOTICE (%d) loglevel\n" "$LOGLEVEL_NOTICE"
	action set_loglevel $LOGLEVEL_NOTICE
}

work() {
	info "=== Ethernet loopback test work procedure ===\n"

	info "Set source interface '%s' link up\n" "$ETH_SRC_IFACE"
	action eth_set_link_up $ETH_SRC_IFACE "false"

	info "Set destination interface '%s' link up\n" "$ETH_DST_IFACE"
	action eth_set_link_up $ETH_DST_IFACE "false"

	info "Make sure source '%s' and destination '%s' interfaces link is up\n"
		"$ETH_SRC_IFACE" "$ETH_DST_IFACE"
	action eth_set_link_up $ETH_SRC_IFACE "true"
	action eth_set_link_up $ETH_DST_IFACE "true"

	info "Perform link-layer ping of '%s' via '%s' interface\n" \
		"$ETH_DST_IFACE_MAC" "$ETH_SRC_IFACE"
	action linkloop -i "$ETH_SRC_IFACE" "$ETH_DST_IFACE_MAC"
}

epilogue() {
	info "=== Ethernet loopback test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	info "Disable source '%s' and destination '%s' interfaces\n" \
		 "$ETH_SRC_IFACE" "$ETH_DST_IFACE"
	eth_set_link_down $ETH_DST_IFACE
	eth_set_link_down $ETH_SRC_IFACE

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
