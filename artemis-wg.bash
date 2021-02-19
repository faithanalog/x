#!/bin/bash

# script similar to wg-quick for configuring wireguard interfaces.
# wg-quick modifies my firewall and I don't like that, so I have my own.

# Supported OSes
# - Linux
#
# Supported wg-quick Directives
# - ipv4 Address
# - PreUp
# - PreDown
# - PostUp
# - PostDown

die() {
    printf >&2 "$@"
    exit 1
}

if [ $# != 2 ] || ( [ "$1" != "up" ] && [ "$1" != "down" ] ); then
    die 'usage: %s (up|down) <path/to/config.conf>\n' "$0"
fi

action="$1"
config="$(realpath "$2")"
device="$(basename "$2" ".conf")"

printf 'resolved %s to %s\n' "$2" "$config"

if ! [ -f "$config" ]; then
    die 'error: %s does not exist or is not a normal file.\n' "$config"
fi

# Test for unsupported directives
if grep -iE '^ *(DNS|MTU|Table|SaveConfig)' "$config"; then   
    exit 1
fi | sed 's/^/unsupported directive: /' >&2

cat "$config" \
    | awk -F ' *= *' '
        /^ *#/ { next }

        { directive[tolower($1)] = $2 }

        END {
            print directive["preup"]
            print directive["predown"]
            print directive["postup"]
            print directive["postdown"]
            print directive["address"]
        }
    ' \
    | (
        read -r preup
        read -r predown
        read -r postup
        read -r postdown
        read -r address

        if [ "$action" = "up" ]; then
            ip link add "$device" type wireguard
            if [ -n "$preup" ]; then eval $preup; fi
            ip -4 address add "$address" dev "$device"
            ip link set mtu 1420 up dev "$device"
            wg setconf "$device" <(grep -Evi '^ *(PreUp|PreDown|PostUp|PostDown|Address)' "$config")
            if [ -n "$postup" ]; then eval $postup; fi
        fi

        if [ "$action" = "down" ]; then
            if [ -n "$predown" ]; then eval $predown; fi
            ip link delete dev "$device"
            if [ -n "$postdown" ]; then eval $postdown; fi
        fi
    )
