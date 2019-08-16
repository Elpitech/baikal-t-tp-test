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
# Perform link speed/duplex test procedure for two interfaces, which in particular
# can be either connected to each either, or can be set to the same values.
# In the last case the interface is supposed to be connected to some another
# link partner with link setup.
#
# $1 ... Interface #1 bus
# $2 ... Interface #1 physical address
# $3 ... Interface #2 bus
# $4 ... Interface #2 physical address
# $5 ... Link speed (normally 10|100|1000 Mb/s)
# $6 ... Link duplexity (Full or Half)
ETH_ARG1_IFACE1_BUS=${1:-"soc"}
ETH_ARG2_IFACE1_ADDR=${2:-"soc0/axi/1f05e000.eth1"}
ETH_ARG3_IFACE2_BUS=${3:-"soc"}
ETH_ARG4_IFACE2_ADDR=${4:-"soc0/axi/1f060000.eth2"}
ETH_ARG5_SPEED=${5:-"10"}
ETH_ARG6_DUPLEX=${6:-"Half"}

ETH_LINKSPEED_DEPENDS="ip ethtool"
ETH_IFACE1=""
ETH_IFACE2=""

prologue() {
	info "=== Ethernet linkspeed test prologue ===\n"

	info "Test parameters: iface1_bus='%s', iface1_addr='%s'\n" \
		"$ETH_ARG1_IFACE1_BUS" "$ETH_ARG2_IFACE1_ADDR"
	info "Test parameters: iface2_bus='%s', iface2_addr='%s'\n" \
		"$ETH_ARG3_IFACE2_BUS" "$ETH_ARG4_IFACE2_ADDR"
	info "Test parameters: speed='%s', duplex='%s'\n" \
		"$ETH_ARG5_SPEED" "$ETH_ARG6_DUPLEX"

	info "Check test dependencies: %s\n" "$ETH_LINKSPEED_DEPENDS"
	action test_commands $ETH_LINKSPEED_DEPENDS

	info "Load Ethernet TP-test library\n"
	action load_library eth

	info "Find interface of '%s %s' device #1\n" \
		"$ETH_ARG1_IFACE1_BUS" "$ETH_ARG2_IFACE1_ADDR"
	action 'ETH_IFACE1=$(eth_getiface "$ETH_ARG1_IFACE1_BUS" "$ETH_ARG2_IFACE1_ADDR")'
	info "Device '%s %s' corresponds to '%s' interface\n" \
		"$ETH_ARG1_IFACE1_BUS" "$ETH_ARG2_IFACE1_ADDR" "$ETH_IFACE1"

	info "Find interface of '%s %s' device #2\n" \
		"$ETH_ARG3_IFACE2_BUS" "$ETH_ARG4_IFACE2_ADDR"
	action 'ETH_IFACE2=$(eth_getiface "$ETH_ARG3_IFACE2_BUS" "$ETH_ARG4_IFACE2_ADDR")'
	info "Device '%s %s' corresponds to '%s' interface\n" \
		"$ETH_ARG3_IFACE2_BUS" "$ETH_ARG4_IFACE2_ADDR" "$ETH_IFACE2"

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console NOTICE (%d) loglevel\n" "$LOGLEVEL_NOTICE"
	action set_loglevel $LOGLEVEL_NOTICE
}

work() {
	local _speed
	local _duplex

	info "=== Ethernet linkspeed test work procedure ===\n"

	info "Set interface #1 '%s' link up\n" "$ETH_IFACE1"
	action eth_set_link_up $ETH_IFACE1 "false"

	info "Set interface #2 '%s' link up\n" "$ETH_IFACE2"
	action eth_set_link_up $ETH_IFACE2 "false"

	info "Make sure interfaces #1 '%s' and #2 '%s' link is up\n"
		"$ETH_IFACE1" "$ETH_IFACE2"
	action eth_set_link_up $ETH_IFACE1 "true"
	action eth_set_link_up $ETH_IFACE2 "true"

	info "Retrieve interface #1 '%s' speed and duplex\n" "$ETH_IFACE1"
	action '_speed=$(eth_getspeed ${ETH_IFACE1})'
	action '_duplex=$(eth_getduplex ${ETH_IFACE1})'
	info "'%s' interface speed %s Mbit/s and duplex '%s'\n" "$ETH_IFACE1" \
		"$_speed" "$_duplex"

	info "Check interface #1 '%s' speed and duplex\n" "$ETH_IFACE1"
	action test "$_speed" -eq "$ETH_ARG5_SPEED"
	action test "$_duplex" == "$ETH_ARG6_DUPLEX"

	info "Retrieve interface #2 '%s' speed and duplex\n" "$ETH_IFACE2"
	action '_speed=$(eth_getspeed ${ETH_IFACE2})'
	action '_duplex=$(eth_getduplex ${ETH_IFACE2})'
	info "'%s' interface speed %s Mbit/s and duplex '%s'\n" "$ETH_IFACE2" \
		"$_speed" "$_duplex"

	info "Check interface #2 '%s' speed and duplex\n" "$ETH_IFACE2"
	action test "$_speed" -eq "$ETH_ARG5_SPEED"
	action test "$_duplex" == "$ETH_ARG6_DUPLEX"
}

epilogue() {
	info "=== Ethernet linkspeed test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	info "Disable interfaces #1 '%s' and #2 '%s'\n" "$ETH_IFACE1" "$ETH_IFACE2"
	eth_set_link_down $ETH_IFACE2
	eth_set_link_down $ETH_IFACE1

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
