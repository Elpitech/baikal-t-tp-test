#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

RTC_DEPENDS="cd basename cat awk"

#
# Check rtc library environment prerequisite
#
rtc_check_prerequisite() {
	test_commands $RTC_DEPENDS
}

#
# Find device name by given bus/address pair
#
# $1 ... Device bus (i2c, spi, pci, etc)
# $2 ... Device address
rtc_getdev() {
	local _bus="$1"
	local _addr="$2"
	local _path="/sys/bus/${_bus}/devices/${_addr}/rtc"
	local _dev

	_dev="$( (cd "$_path" && echo *) | awk '{print $1}')" || return $?
	[ ! -c "/dev/$_dev" ] && return $FAILURE

	printf "/dev/%s" "$_dev"

	return $SUCCESS
}

#
# Get date from the passed hardware clocks
#
# $1 ... Device path
rtc_getdate() {
	local _dev="$1"
	local _date

	_dev="$(basename "$_dev")" || return $?

	_date="$(cat "/sys/class/rtc/${_dev}/date")" || return $FAILURE
	[ -z "$_date" ] && return $FAILURE

	printf "%s" "$_date"

	return $SUCCESS
}

#
# Get time from the passed hardware clocks
#
# $1 ... Device path
rtc_gettime() {
	local _dev="$1"
	local _time

	_dev="$(basename "$_dev")" || return $?

	_time="$(cat "/sys/class/rtc/${_dev}/time")" || return $FAILURE
	[ -z "$_time" ] && return $FAILURE

	printf "%s" "$_time"

	return $SUCCESS
}

rtc_check_prerequisite
