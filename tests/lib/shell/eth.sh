#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

ETH_DEPENDS="cd sleep awk sed ip ethtool"

#
# Check eth library environment prerequisite
#
eth_check_prerequisite() {
	test_commands $ETH_DEPENDS
}

#
# Get interface name by given bus/address pair
#
# $1 ... Device bus (soc, usb, pci, etc)
# $2 ... Device address
eth_getiface() {
    local _bus="$1"
	local _addr="$2"
	local _path="/sys/bus/${_bus}/devices/${_addr}/net"
	local _iface

	_iface="$( (cd "$_path" && echo *) | awk '{print $1}')" || return $?
	[ -z "$_iface" ] && return $FAILURE

	printf "%s" "$_iface"

	return $SUCCESS
}

#
# Get interface MAC address
#
# $1 ... Interface name
eth_getmac() {
	local _mac

	_mac=$(ip link show | awk -v IFACE="$1" '{
		if ($2 ~ "^"IFACE":$")
			found = 1
		if (found == 1 && $1 ~ "^link/ether$") {
			printf "%s", $2
			found = 0
		}
	}')
	[ -z "$_mac" ] && return $FAILURE

	printf "%s" "$_mac"

	return $SUCCESS
}

#
# Get interface Speed
#
# $1 ... Interface name
eth_getspeed() {
	local _speed

	_speed="$(ethtool $1 | sed -n 's/^\tSpeed: \([0-9]\+\)Mb\/s$/\1/p')"
	[ -z "$_speed" ] && return $FAILURE

	printf "%s" "$_speed"

	return $SUCCESS
}

#
# Get interface duplex
#
# $1 ... Interface name
eth_getduplex() {
	local _duplex

	_duplex="$(ethtool "$1" | sed -n 's/^\tDuplex: \(Full\|Half\)$/\1/p')"
	[ -z "$_duplex" ] && return $FAILURE

	printf "%s" "$_duplex"

	return $SUCCESS
}

#
# Set interface link up
#
# $1 ... Interface name
# $2 ... Flag whether to wait for the link setting up
eth_set_link_up() {
	local _iface="$1"
	local _wait="$2"
	local _opstate="/sys/class/net/${_iface}/operstate"
	local _state
	local _cnt

	ip link set "$_iface" up || return $?

	bool "$_wait" "false" && return $SUCCESS

	_cnt="$((${TPTEST_TIMEOUT:-0} / 3000))"

	while :; do
		_state="$(cat /sys/class/net/${_iface}/operstate)" || return $?
		[ "$_state" == "up" ] && return $SUCCESS

		[ $((--_cnt)) -gt 0 ] || return $FAILURE
		sleep 1
	done
}

#
# Set interface link down
#
# $1 ... Interface name
eth_set_link_down() {
	local _iface="$1"

	ip link set "$_iface" down
}

eth_check_prerequisite
