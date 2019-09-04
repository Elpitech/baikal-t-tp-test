#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

SERIAL_DEPENDS="cd stty"

#
# Check serial library environment prerequisite
#
serial_check_prerequisite() {
	test_commands $SERIAL_DEPENDS
}

#
# Find device path by given bus/address/port turple
#
# $1 ... Device bus (soc, usb, pci, etc)
# $2 ... Device address
# $3 ... Port (most likely ordered number of the interface)
serial_getdev() {
	local _bus="$1"
	local _addr="$2"
	local _port="$3"
	local _path="/sys/bus/${_bus}/devices/${_addr}/tty"
	local _dev

	if [ "$_port" -le "0" ]; then
		_port=1
	else
		_port=$((_port + 1))
	fi

    _dev="$( (cd "$_path" && echo *) | awk -v PORT="$_port" '{print $PORT}')" || return $?
    [ ! -c "/dev/$_dev" ] && return $FAILURE

    printf "/dev/%s" "$_dev"

	return $SUCCESS
}

#
# Get passed tty settings in stty-readable form
#
# $1 ... Device path (/dev/ttyX)
serial_getsettings() {
	local _dev="$1"
	local _settings

	_settings="$(stty -F "$_dev" -g)" || return $?
	[ -z "$_settings" ] && return $FAILURE

	printf "%s" "$_settings"

	return $SUCCESS
}

#
# Set passed stty-readable tty settings (may return an error if some
# ioctl's like rs485 aren't supported).
#
# $1 ... Device path (/dev/ttyX)
# $2 ... Settings
serial_setsettings() {
	local _dev="$1"
	local _settings="$2"

	stty -F "$_dev" "$_settings"
}

#
# Set raw mode with specified baud rate of the passed ttyX
#
# $1 ... Device path (/dev/ttyX)
# $2 ... Baud rate
serial_setraw() {
	local _dev="$1"
	local _baud="$2"

	stty -F "$_dev" "$_baud" raw -echo -echoe -echok
}

#
# Set rs485 mode of the passed ttyX
#
# $1 ... Device path (/dev/ttyX)
serial_setrs485() {
	local _dev="$1"

	stty -F "$_dev" rs485
}

#
# Set full modem mode of the passed ttyX
#
# $1 ... Device path (/dev/ttyX)
serial_setmodem() {
	local _dev="$1"

	stty -F "$_dev" -clocal crtscts
}

serial_check_prerequisite
