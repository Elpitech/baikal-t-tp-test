#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

FLASH_DEPENDS="cd awk nandtest"

#
# Check flash library environment prerequisite
#
flash_check_prerequisite() {
	test_commands $FLASH_DEPENDS
}

#
# Find MTD device name by given bus/address pair
#
# $1 ... Device bus (i2c, spi, pci, etc)
# $2 ... Device address
flash_getmtd() {
	local _bus="$1"
	local _addr="$2"
	local _path="/sys/bus/${_bus}/devices/${_addr}/mtd"
	local _dev

	_dev="$( (cd "$_path" && echo *) | awk '{print $1}')" || return $?
	[ ! -c "/dev/$_dev" -a ! -b "/dev/$_dev" ] && return $FAILURE

	printf "/dev/%s" "$_dev"

	return $SUCCESS
}

#
# Perform nandtest over the passed device with the specified parameters
#
# $1 ... Device path (/dev/mtdX)
# $2 ... Size of block to test
# $3 ... Number of passes
# $4 ... Number of read/check circles
flash_nandtest() {
	local _dev="$1"
	local _size="$2"
	local _passes="$3"
	local _checks="$4"

	nandtest -k -o 0 -l "$_size" -p "$_passes" -r "$_checks" "$_dev"
}

flash_check_prerequisite
