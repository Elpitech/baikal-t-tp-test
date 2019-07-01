#!/bin/sh
# vi: set ts=4 sw=4 cindent :
#
# $Id$
#
# Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
#

if ! source "${TPTEST_ROOT:-/etc/tp-test}/lib/shell/core.sh"; then
	printf "Failed to load core library" >&2
	exit 1
fi

#
# Perform serial ports loopback test sending a pattern from source
# to destination interface with the specified baud rate.
#

# $1 ... Source serial interface bus
# $2 ... Source serial interface physical address
# $3 ... Source serial interface device port
# $4 ... Destination serial interface bus
# $5 ... Destination serial interface physical address
# $6 ... Destination serial interface device port
# $7 ... Baud rate of communications
# $8 ... RS485 mode flag
SERIAL_ARG1_SRC_BUS=${1:-"soc"}
SERIAL_ARG2_SRC_ADDR=${2:-"soc0/apb/1f04b000.serial1"}
SERIAL_ARG3_SRC_PORT=${3:-"0"}
SERIAL_ARG4_DST_BUS=${4:-"soc"}
SERIAL_ARG5_DST_ADDR=${5:-"soc0/apb/1f04b000.serial1"}
SERIAL_ARG6_DST_PORT=${6:-"0"}
SERIAL_ARG7_BAUD=${7:-"9600"}
SERIAL_ARG8_RS485=${8:-"no"}

SERIAL_LOOPBACK_DEPENDS="mktemp cat kill rm sleep"
SERIAL_TEMP=""
SERIAL_SRC_DEV=""
SERIAL_SRC_CFG=""
SERIAL_DST_DEV=""
SERIAL_DST_CFG=""
SERIAL_DST_PID=""
SERIAL_PATTERN="DEADBEEFBAADF00D"

prologue() {
	info "=== Serial ports loopback test prologue ===\n"

	info "Test parameters: src_bus='%s', src_addr='%s', src_port='%u'\n" \
		"$SERIAL_ARG1_SRC_BUS" "$SERIAL_ARG2_SRC_ADDR" "$SERIAL_ARG3_SRC_PORT"
	info "Test parameters: dst_bus='%s', dst_addr='%s', dst_port='%u'\n" \
		"$SERIAL_ARG4_DST_BUS" "$SERIAL_ARG5_DST_ADDR" "$SERIAL_ARG6_DST_PORT"
	info "Test parameters: baud='%u', rs485='%s'\n" \
		"$SERIAL_ARG7_BAUD" "$SERIAL_ARG8_RS485"

	info "Check test dependencies: %s\n" "$SERIAL_LOOPBACK_DEPENDS"
	action test_commands $SERIAL_LOOPBACK_DEPENDS

	info "Load serial TP-test library\n"
	action load_library serial

	info "Setup test cleanup method\n"
	action set_cleanup_method epilogue

	info "Set system console WARNING (%d) loglevel\n" "$LOGLEVEL_WARNING"
	action set_loglevel $LOGLEVEL_WARNING

	info "Find char-device of the source '%s %s' port %u\n" \
		"$SERIAL_ARG1_SRC_BUS" "$SERIAL_ARG2_SRC_ADDR" "$SERIAL_ARG3_SRC_PORT"
	action 'SERIAL_SRC_DEV=$(serial_getdev "$SERIAL_ARG1_SRC_BUS" "$SERIAL_ARG2_SRC_ADDR" "$SERIAL_ARG3_SRC_PORT")'
	info "Port %u of '%s %s' corresponds to '%s' device\n" \
		"$SERIAL_ARG3_SRC_PORT" "$SERIAL_ARG1_SRC_BUS" "$SERIAL_ARG2_SRC_ADDR" \
		"$SERIAL_SRC_DEV"

	info "Save the source device '%s' settings\n" "$SERIAL_SRC_DEV"
	action 'SERIAL_SRC_CFG=$(serial_getsettings "$SERIAL_SRC_DEV")'

	info "Find char-device of the destination '%s %s' port %u\n" \
		"$SERIAL_ARG4_DST_BUS" "$SERIAL_ARG5_DST_ADDR" "$SERIAL_ARG6_DST_PORT"
	action 'SERIAL_DST_DEV=$(serial_getdev "$SERIAL_ARG4_DST_BUS" "$SERIAL_ARG5_DST_ADDR" "$SERIAL_ARG6_DST_PORT")'
	info "Port %u of '%s %s' corresponds to '%s' device\n" \
		"$SERIAL_ARG6_DST_PORT" "$SERIAL_ARG4_DST_BUS" "$SERIAL_ARG5_DST_ADDR" \
		"$SERIAL_DST_DEV"

	info "Save the destination device '%s' settings\n" "$SERIAL_DST_DEV"
	action 'SERIAL_DST_CFG=$(serial_getsettings "$SERIAL_DST_DEV")'
}

work() {
	local _pattern

	info "=== Serial ports loopback test work procedure ===\n"

	info "Create a temporary file to save the retrieved pattern\n"
	action 'SERIAL_TEMP=$(mktemp)'
	info "The temporary file is '%s'\n" "$SERIAL_TEMP"

	info "Set the source device '%s' raw mode with baud '%u'\n" "$SERIAL_SRC_DEV" \
		"$SERIAL_ARG7_BAUD"
	action serial_setraw "$SERIAL_SRC_DEV" "$SERIAL_ARG7_BAUD"

	info "Set the destination device '%s' raw mode with baud '%u'\n" "$SERIAL_DST_DEV" \
		"$SERIAL_ARG7_BAUD"
	action serial_setraw "$SERIAL_DST_DEV" "$SERIAL_ARG7_BAUD"

	if bool "$SERIAL_ARG8_RS485" true; then
		info "Enable rs485 mode of the source device '%s'\n" "$SERIAL_SRC_DEV"
		action serial_setrs485 "$SERIAL_SRC_DEV"

		info "Enable rs485 mode of the destination device '%s'\n" "$SERIAL_DST_DEV"
		action serial_setrs485 "$SERIAL_DST_DEV"
	fi

	info "Open the destination device '%s' to receive the pattern\n" "$SERIAL_DST_DEV"
	action 'cat "$SERIAL_DST_DEV" > "$SERIAL_TEMP" &'
	SERIAL_DST_PID=$!
	info "Destination device '%s' data receiver is started with pid '%u'\n" \
		"$SERIAL_DST_DEV" "$SERIAL_DST_PID"

	info "Make sure the file '%s' is opened by '%u'\n" \
		"$SERIAL_DST_DEV" "$SERIAL_DST_PID"
	action file_opened "$SERIAL_DST_PID" "$SERIAL_DST_DEV" 100

	info "Send the pattern '%s' to the source device '%s'\n" "$SERIAL_PATTERN" \
		"$SERIAL_SRC_DEV"
	action 'printf "%s" "$SERIAL_PATTERN" > "$SERIAL_SRC_DEV"'

	info "Shortly read the pattern from the temporary file '%s'\n" "$SERIAL_TEMP"
	sleep 0.1
	action '_pattern=$(cat "$SERIAL_TEMP")'

	info "Make sure the sent and received patterns match\n"
	action test "\"$_pattern\"" == "$SERIAL_PATTERN"
}

epilogue() {
	info "=== Serial ports loopback test epilogue ===\n"

	info "Remove test cleanup method\n"
	del_cleanup_method

	if [ -n "$SERIAL_DST_PID" ]; then
		info "Terminate the destination port data receiver process '%u'\n" \
			"$SERIAL_DST_PID"
		kill -TERM $SERIAL_DST_PID
		wait $SERIAL_DST_PID
	fi

	if [ -n "$SERIAL_DST_CFG" ]; then
		info "Restore the destination device '%s' settings\n" "$SERIAL_DST_DEV"
		serial_setsettings "$SERIAL_DST_DEV" "$SERIAL_DST_CFG"
	fi

	if [ -n "$SERIAL_SRC_CFG" ]; then
		info "Restore the source device '%s' settings\n" "$SERIAL_SRC_DEV"
		serial_setsettings "$SERIAL_SRC_DEV" "$SERIAL_SRC_CFG"
	fi

	if [ -n "$SERIAL_TEMP" ]; then
		info "Remove the temporary file '%s'\n" "$SERIAL_TEMP"
		rm -rf "$SERIAL_TEMP"
	fi

	info "Restore previous system console loglevel\n"
	reset_loglevel
}

main() {
	prologue

	work	

	epilogue

	exit $SUCCESS
}

main "$@"
