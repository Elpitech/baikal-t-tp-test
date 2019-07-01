#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

USB_DEPENDS="sleep"

#
# Check USB library environment prerequisite
#
usb_check_prerequisite() {
	test_commands $USB_DEPENDS
}

#
# Check USB port existence
#
# $1 ... port ID
usb_check_port() {
	local _port="$1"
	local _dir="/sys/bus/usb/devices/${_port}/"

	_cnt=$((${TPTEST_TIMEOUT:-0} / 1000 - 1))

	while :; do
		[ -d "$_dir" ] && return $SUCCESS

		[ $((--_cnt)) -gt 0 ] || return $FAILURE
		sleep 1
	done
}

usb_check_prerequisite
