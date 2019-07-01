#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

SENSORS_DEPENDS="cd cat awk"

#
# Check sensors library environment prerequisite
#
sensors_check_prerequisite() {
	test_commands $SENSORS_DEPENDS
}

#
# Find hwmon device by given bus/address pair
#
# $1 ... Device bus (i2c, spi, pci, soc, etc)
# $2 ... Device address
sensors_gethwmon() {
	local _bus="$1"
	local _addr="$2"
	local _path="/sys/bus/${_bus}/devices/${_addr}/hwmon"
	local _dev

	_dev="$( (cd "$_path" && echo *) | awk '{print $1}')" || return $?
	[ ! -d "/sys/class/hwmon/$_dev" ] && return $FAILURE

	printf "/sys/class/hwmon/%s" "$_dev"

	return $SUCCESS
}

#
# Get hwmonX input of the specified type
#
# $1 ... Hwmon path
# $2 ... Hwmon type
sensors_getinput() {
	local _dev="$1"
	local _type="$2"
	local _file
	local _input

	if [ -f "${_dev}/${_type}_input" ]; then
		_file="${_dev}/${_type}_input"
	elif [ -f "${_dev}/device/${_type}_input" ]; then
		_file="${_dev}/device/${_type}_input"
	else
		return $FAILURE
	fi

	_input="$(cat "$_file")" || return $FAILURE
	[ -z "$_input" ] && return $FAILURE

	calc "$_input / 1000" || return $FAILURE

	return $SUCCESS
}

sensors_check_prerequisite
