#!/bin/bash

set -euo pipefail

check_command() {
    if ! command -v "$1" >/dev/null; then
        echo "ERROR: required command $1 not found." >&2
        return 1
    fi
}

check_command xdotool
check_command dbus-launch
check_command notify-send

TEST_DIR="$(dirname "$(readlink -f "$0")")"

: ${XEPHYR:=Xephyr}
: ${XVFB:=Xvfb}
: ${HEADLESS:=1}
: ${TEST_DISPLAY:=:5}
: ${TEST_DISPLAY_SIZE:=800x600}
: ${TIMEOUT_CMD:=timeout}
: ${TIMEOUT_DURATION:=60s}
: ${LUA:=lua}
export LUA

if [[ -z "${AWESOMEWM_SRC_DIR:-}" ]]; then
    for c in "${TEST_DIR}/../../awesome"; do
        if [[ -d "$c/lib" && -d "$c/tests" ]]; then
            c="$(cd "$c"; pwd)"
            echo "Found AwesomeWM source tree in $c" >&2
            AWESOMEWM_SRC_DIR="$c"
        fi
    done
fi
if [[ -z "${AWESOMEWM_SRC_DIR:-}" ]]; then
    echo "Please set env var AWESOMEWM_SRC_DIR to the AwesomeWM source directory." >&2
    exit 1
fi
export LUA_PATH="${TEST_DIR}/?.lua;${AWESOMEWM_SRC_DIR}/tests/?.lua;$("${LUA}" -e 'print(package.path)')"

if [[ -z "${TEST_LOG_OUTPUT:-}" ]]; then
    TEST_LOG_OUTPUT=/dev/null
else
    echo "Writing test logs to $TEST_LOG_OUTPUT" >&2
    echo "Awexygen tests start at $(date)" >"$TEST_LOG_OUTPUT"
fi

setup_xserver() {
    if (( HEADLESS )); then
        check_command ${XVFB}
        "$XVFB" "$TEST_DISPLAY" -noreset -screen 0 "${TEST_DISPLAY_SIZE}x24" \
                2>>"$TEST_LOG_OUTPUT" &
    else
        check_command ${XEPHYR}
        "$XEPHYR" "$TEST_DISPLAY" -ac -name xephyr_"$TEST_DISPLAY" \
                  -noreset -screen "$TEST_DISPLAY_SIZE" 2>>"$TEST_LOG_OUTPUT" &
    fi
    TEST_XSERVER_PID=$!
    WAIT_DEADLINE=$(( $(date +%s) + 10 ))
    while (( $(date +%s) < WAIT_DEADLINE )); do
        if DISPLAY="$TEST_DISPLAY" xrdb -q 2>>"$TEST_LOG_OUTPUT"; then
            export DISPLAY="$TEST_DISPLAY"
            return
        fi
        sleep 1
    done
    echo "Failed set up test X server." >&2
    return 1
}
cleanup_xserver() {
    kill "$TEST_XSERVER_PID"
}
setup_xserver
trap cleanup_xserver EXIT SIGINT SIGTERM

eval "$(dbus-launch --sh-syntax --exit-with-x11)"

TEST_PATTERN="${1:-*}"
declare -a SELECTED_TESTS
readarray -t SELECTED_TESTS < <(
    cd ${TEST_DIR}; find . -name "test_*.lua" -path "$TEST_PATTERN" | sort)
for test in "${SELECTED_TESTS[@]}"; do
    test="${test#./}"
    echo -n "Running $test ... " >&2
    echo "Running $test ... " >>"$TEST_LOG_OUTPUT"
    result="$(AWESOMEWM_ASSETS_DIR="$AWESOMEWM_SRC_DIR" "$TIMEOUT_CMD" "$TIMEOUT_DURATION" \
        "${TEST_DIR}/../awexygen" "${TEST_DIR}/$test" 2>&1 || echo "Exited with code $?")"
    echo -E "$result" >>"$TEST_LOG_OUTPUT"
    if [[ "$result" != *"Test finished successfully."* ]]; then
        printf "failed with output:\n%s\n" "$result" >&2
    else
        echo "OK" >&2
    fi
done
