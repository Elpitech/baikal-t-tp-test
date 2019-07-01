#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

STORAGE_DEPENDS="sleep sed lsscsi hdparm"

#
# Check storage library environment prerequisite
#
storage_check_prerequisite() {
	test_commands $STORAGE_DEPENDS
}

#
# Find device name by given transport/port pair
#
# $1 ... Interface name (either of sata, usb, mmc)
# $2 ... Interface port
storage_getdev() {
	local _trans="$1"
	local _port="$2"
	local _dev
	local _pattern

	case "$_trans" in
	"sata")
		_pattern="^\[${_port}:[0-9]:[0-9]:[0-9]\]\ *disk\ *sata:[0-9a-fA-F:\.\-]*\ *\(\/dev\/[a-z]\+\) $"
		;;
	"usb")
		_pattern="^\[[0-9]:[0-9]:[0-9]:[0-9]\]\ *disk\ *usb:${_port}\ *\(\/dev\/[a-z]\+\) $"
		;;
	"mmc")
		_dev="/dev/mmcblk$_port"
		;;
	*)
		return $FAILURE
		;;
	esac

	if [ -z "$_dev" ]; then
		local _cnt

		_cnt="$((${TPTEST_TIMEOUT:-0} / 5000))"
		while :; do
			_dev="$(lsscsi -t | sed -n "s/${_pattern}/\1/p")"
			[ -n "$_dev" ] && break

			[ $((--_cnt)) -gt 0 ] || return $FAILURE
			sleep 1
		done
	fi
	[ ! -b "$_dev" ] && return $FAILURE

	printf "%s" "$_dev"

	return $SUCCESS
}

#
# Get block device buffered read performance
#
# $1 ... Device path name (/dev/...)
storage_get_buffered_timings() {
	local _dev="$1"
	local _timings

	_timings="$(hdparm -t "$_dev" | sed -n 's/^ Timing buffered disk reads:.*=\ *\([0-9]\+\.\?[0-9]*\) MB\/sec/\1/p')"
	[ -z "$_timings" ] && return $FAILURE

	printf "%s" "$_timings"

	return $SUCCESS
}

#
# Get block device cached read performance
#
# $1 ... Device path name (/dev/...)
storage_get_cached_timings() {
	local _dev="$1"
	local _timings

	_timings="$(hdparm -T "$_dev" | sed -n 's/^ Timing cached reads:.*=\ *\([0-9]\+\.\?[0-9]*\) MB\/sec/\1/p')"
	[ -z "$_timings" ] && return $FAILURE

	printf "%s" "$_timings"

	return $SUCCESS
}

storage_check_prerequisite
