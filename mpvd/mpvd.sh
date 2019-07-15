#!/bin/sh

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf 'Usage: %s <queuefifo> [mpv flags]\n' "$0"
    exit 1
fi

fifo="$1"
shift


queue="$(mktemp)"
lockfile="$(mktemp)"

quit() {
    lock
    rm "$queue"
    rm "$lockfile"
    exit 0
}
trap quit SIGINT

lock() {
    lk="$(cat /dev/urandom | head -c+16 | base64)"
    lkcontents="$(cat "$lockfile")"
    while [ "$lkcontents" != "$lk" ]; do
        if [ -z "$lkcontents" ]; then
            printf '%s\n' "$lk" > "$lockfile"
        else
            sleep 0.1
        fi
        lkcontents="$(cat "$lockfile")"
    done
}

unlock() {
    printf '' > "$lockfile"
}

enque() {
    lock
    printf '%s\n' "$1" >> "$queue"
    unlock
}

deque() {
    lock
    next="$(head -n1 "$queue")"
    printf '%s' "$(tail -n+2 "$queue")" > "$queue"
    unlock
}

while true; do
    cat "$fifo" | while read -r ln; do
        enque "$ln"
    done
done &

while true; do
    deque
    if [ -z "$next" ]; then
        sleep 1
    else
        mpv "$@" "$next"
    fi
done
