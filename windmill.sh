#!/bin/sh

interval=2

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "Usage: %s [-n <seconds> || --interval <seconds>] <command>\n" "$0"
    printf '%s\n' '    Runs <command> every <interval> (default = '$interval') seconds until'
    printf '%s\n' '    it exits with a non-zero exit code.'
    exit
elif [ "$1" = "-n" ] || [ "$1" = "--interval" ]; then
    interval="$2"
    shift
    shift
elif printf '%s\n' "$1" | grep "^-n" 2>&1 >/dev/null; then
    interval="$(printf '%s\n' "$1" | sed 's/^-n//')"
    shift
fi

while ! "$@"; do sleep "$interval"; done
