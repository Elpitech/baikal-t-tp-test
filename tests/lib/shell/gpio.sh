#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

GPIO_DEPENDS="cd cat sed awk"

#
# Check GPIO library environment prerequisite
#
# NOTE! In kernel since 4.8 sysfs interface is marked as deprecated so all
# the GPIO subsystem user-land users are encouraged to move to the new
# character-device based GPIO interface. In case when we completely port our
# projects to kernel 4.9 and abandon kernel 4.4, this library should be
# modified to use the libgpiod utilities. Until then we have to stay with
# the obsolete sysfs interface.
#
gpio_check_prerequisite() {
	test_commands $RTC_DEPENDS
}

#
# Find GPIO device base number by given bus/addr pair
#
# $1 ... Device bus (i2c, soc, spi, etc)
# $2 ... Device address
gpio_getbase() {
	local _bus="$1"
	local _addr="$2"
	local _path="/sys/bus/${_bus}/devices/${_addr}/gpio"
	local _chip _base

	_chip="$( (cd "$_path" && echo gpiochip*) | awk '{print $1}')" || return $?
	[ -z "$_chip" ] && return $FAILURE

	_base=$(printf '%s' "$_chip" | sed -n 's/^gpiochip\([0-9]\+\)$/\1/p')
	[ -z "$_base" ] && return $FAILURE

	printf '%s' "$_base"

	return $SUCCESS
}

#
# Find number of GPIO per device with passed base
#
# $1 ... Base number
gpio_getnum() {
	local _base="$1"
	local _path="/sys/class/gpio/gpiochip${_base}/ngpio"

	cat "$_path"
}

#
# Request GPIO from the chip with specified base number
#
# $1 ... Base number
# $2 ... Pin hardware ID
gpio_request() {
	local _base="$1"
	local _hwid="$2"
	local _path="/sys/class/gpio/export"
	local _ngpio="/sys/class/gpio/gpiochip${_base}/ngpio"
	local _id

	_ngpio=$(cat "$_ngpio") || return $?
	[ "$_hwid" -ge "$_ngpio" ] && return $FAILURE

	_id=$((_base + _hwid))
	printf '%s' "$_id" > "$_path" || return $?
	printf '%u' "$_id"

	return $SUCCESS
}

#
# Free GPIO with the specified global ID
#
# $1 ... Global GPIO ID
gpio_free() {
	local _id="$1"
	local _path="/sys/class/gpio/unexport"

	printf '%s' "$_id" > "$_path"
}

#
# Get direction of GPIO with the specified global ID
#
# $1 ... Global GPIO ID
gpio_get_direction() {
	local _id="$1"
	local _dir="$2"
	local _path="/sys/class/gpio/gpio${_id}/direction"

	cat "$_path"
}

#
# Set direction of GPIO with the specified global ID
#
# $1 ... Global GPIO ID
# $2 ... Direction (in, out, low, high)
gpio_set_direction() {
	local _id="$1"
	local _dir="$2"
	local _path="/sys/class/gpio/gpio${_id}/direction"

	printf '%s' "$_dir" > "$_path"
}

#
# Get value of GPIO with the specified global ID
#
# $1 ... Global GPIO ID
gpio_get_value() {
	local _id="$1"
	local _path="/sys/class/gpio/gpio${_id}/value"
	local _val

	cat "$_path"
}

#
# Set value of GPIO with the specified global ID
#
# $1 ... Global GPIO ID
# $2 ... Value (0 - low, others - high)
gpio_set_value() {
	local _id="$1"
	local _val="$2"
	local _path="/sys/class/gpio/gpio${_id}/value"

	printf '%s' "$_val" > "$_path"
}

#
# Wait for GPIO to have the specified value
#
# $1 ... Global GPIO ID
# $2 ... Value (0 or 1)
gpio_wait_value() {
	local _id="$1"
	local _expval="$2"
	local _curval _cnt

	_cnt=$((${TPTEST_TIMEOUT:-0} - 1000))

	while :; do
		_curval=$(gpio_get_value "$_id") || return $?
		[ "$_curval" -eq "$_expval" ] && return $SUCCESS

        [ $((--_cnt)) -gt 0 ] || return $FAILURE
        sleep 0.001
    done
}

#
# Place a pulse if the specified period on GPIO with passed ID
#
# $1 ... Global GPIO ID
# $2 ... Pulse period (ms)
gpio_generate_pulse() {
	local _id="$1"
	local _period="$2"
	local _duration _delay _cnt
	local _curval _expval

	_duration=$((${TPTEST_TIMEOUT:-0} - 1000))
	_cnt=$((2 * (_duration / _period)))
	_delay=$(calc "${_duration} / (2 * ${_period})") || return $?

	_expval="1"
	while :; do
		gpio_set_value "$_id" "$_expval" || return $?
		_curval=$(gpio_get_value "$_id") || return $?
		[ "$_curval" -ne "$_expval" ] && return $FAILURE
		_expval=$((! _expval))

		sleep $_delay

        [ $((--_cnt)) -gt 0 ] || break
    done

	return $SUCCESS
}

gpio_check_prerequisite
