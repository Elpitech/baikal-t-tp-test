#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

PCI_DEPENDS="cd cat sed lspci"

#
# Check pci library environment prerequisite
#
pci_check_prerequisite() {
	test_commands $RTC_DEPENDS
}

#
# Find device DOMAIN:BUS:SLOT.func by given VID/DID pair
#
# $1 ... Vendor ID (in hex, with or without 0x prefix)
# $2 ... Device ID (in hex, with or without 0x prefix)
pci_getdev() {
	local _vid="$1"
	local _did="$2"
	local _path="/sys/bus/pci/devices"
	local _devs _i _ivid _idid

	_vid=$(printf '%s' "$_vid" | sed -n 's/^\(0x\)\?\([0-9a-fA-F]\{1,4\}\)$/0x\2/p')
	_did=$(printf '%s' "$_did" | sed -n 's/^\(0x\)\?\([0-9a-fA-F]\{1,4\}\)$/0x\2/p')
	[ "$_vid" == "" -o "$_did" == "" ] && return $FAILURE
	_vid=$(printf '%u' "$_vid")
	_did=$(printf '%u' "$_did")

	_devs=$(cd "$_path" && echo *) || return $?
	for _i in $_devs; do
		_ivid=$(cat "${_path}/${_i}/vendor") || return $?
		_idid=$(cat "${_path}/${_i}/device") || return $?
		_ivid=$(printf '%u' "$_ivid")
		_idid=$(printf '%u' "$_idid")

		if [ "$_vid" -eq "$_ivid" -a "$_did" -eq "$_idid" ]; then
			printf '%s' "$_i"
			return $SUCCESS
		fi
	done

	return $FAILURE
}

#
# Get device info by given DOMAIN:BUS:SLOT.func
#
# $1 ... Device address (DOMAIN:BUS:SLOT.func)
pci_getinfo() {
	local _dev="$1"

	lspci -Dnn -s "$_dev"
}

pci_check_prerequisite
