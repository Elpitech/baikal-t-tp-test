#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

: ${SUCCESS:=0} ${FAILURE:=1}
: ${LOGLEVEL_EMERG:=0} ${LOGLEVEL_ALERT:=1} ${LOGLEVEL_CRIT:=2} ${LOGLEVEL_ERR:=3}
: ${LOGLEVEL_WARNING:=4} ${LOGLEVEL_NOTICE:=5} ${LOGLEVEL_INFO:=6} ${LOGLEVEL_DEBUG:=7}
: ${LOGLEVEL:=$LOGLEVEL_DEBUG}

CORE_DEPENDS="sleep awk lsof modprobe"

#
# Check core library environment prerequisite
#
core_check_prerequisite() {
	test_commands $CORE_DEPENDS
}

#
# Print informational message
#
# $@ ... Formatted set of strings to print
info() {
	printf "$@" >&1
}

#
# Print debug message (though printed as info)
#
# $@ ... Formatted set of strings to print
debug() {
	if bool "true" "${TPTEST_DEBUG:-n}"; then
		printf "$@" >&1
	fi
}

#
# Print error message
#
# $@ ... Formatted set of strings to print
error() {
	printf "$@" >&2
	sync
}

#
# Perform critical command
#
# $@ ... Command and it' parameters
action() {
	local _ret

	eval "$@"
	_ret=$?
	if [ $_ret -ne 0 ]; then
		error "Error in '%s' command\n" "$*"
		exit $_ret
	fi
}

#
# Arithmetic calculation using awk (support floating point)
#
# $1 ... Arithmetic expression
calc() {
	awk "BEGIN {print ( $1 )}"
}

#
# Boolean arguments parse. Y, y, yes, true cause the true return.
# N, n, no, false are considered as false.
#
# $1 ... First boolean argument
# $2 ... Second boolean argument
bool() {
	local _val1="$1"
	local _val2="$2"

	case "$_val1" in
	'Y'|'y'|'yes'|'true')
		_val1='true'
		;;
	'N'|'n'|'no'|'false')
		_val1='false'
		;;
	*)
		_val1='false'
		;;
	esac

	case "$_val2" in
	'Y'|'y'|'yes'|'true')
		_val2='true'
		;;
	'N'|'n'|'no'|'false')
		_val2='false'
		;;
	*)
		_val2='false'
		;;
	esac

	[ "$_val1" == "$_val2" ]
}

#
# Check whether the file is opened by the process with pid
#
# $1 ... Process ID
# $2 ... File name
# $3 ... Timeout (ms)
file_opened() {
	local _pid="$1"
	local _file="$2"
	local _tout="$3"

	while :; do
		lsof | awk -v PID="$_pid" -v FNAME="$_file" '{
			if ($1 == PID && $3 == FNAME)
				exit 1
		}' || return $SUCCESS

		[ $((--_tcnt)) -gt 0 ] || return $FAILURE

		sleep 0.001
	done
}

#
# Load shell library
#
# $1 ... Library name
load_library() {
	local _ret

	. "${TPTEST_ROOT:-/etc/tp-test}/lib/shell/$1".sh
	_ret=$?
	if [ $_ret -ne 0 ]; then
		error "Failed to load '%s' shell-library\n" "$1"
		return $_ret
	fi

	return $SUCCESS
}

#
# Set console log level
#
# $1 ... Log level
set_loglevel() {
	local _ll="$1"

	LOGLEVEL="$(cat '/proc/sys/kernel/printk' | awk '{print $1}')"

	printf "%d" "$_ll" > '/proc/sys/kernel/printk'

	return $SUCCESS
}

#
# Reset console log level
#
reset_loglevel() {
	printf "%d" "$LOGLEVEL" > '/proc/sys/kernel/printk'

	return $SUCCESS
}

#
# Set main signals handler to cleanup in case of termination
#
# $1 ... Handler name
set_cleanup_method() {
	local _name="$1"

	trap "$_name" EXIT || return $?
	trap 'exit $?' HUP QUIT ABRT PIPE INT TERM || return $?
}

#
# Delete main signals handler
#
del_cleanup_method() {
	trap - EXIT HUP QUIT ABRT PIPE INT TERM
}

#
# Test whether commands exist in path
#
# $@ ... List of commands to test
test_commands() {
	local _t

	for _t in "$@"; do
		command -v "$_t" >/dev/null || return $FAILURE
	done

	return $SUCCESS
}

#
# Install passed kernel modules
#
# $@ ... Set of modules
install_modules() {
	local _mod _ret

	for _mod in "$@"; do
		modprobe $_mod
		if [ $_ret -ne 0 ]; then
			return $_ret
		fi
	done

	return $SUCCESS
}

#
# Remove passed kernel modules
#
# $@ ... Set of modules
remove_modules() {
	local _mod _ret

	for _mod in "$@"; do
		modprobe -r $_mod
		_ret=$?
		if [ $_ret -ne 0 ]; then
			return $_ret
		fi
	done

	return $SUCCESS
}

core_check_prerequisite
