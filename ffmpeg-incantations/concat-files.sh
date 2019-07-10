#!/bin/sh

if [ $# -lt 2 ]; then
    printf '%s\n' "Usage: $0 <output> <inputs...>"
    printf 'This will probably break horrible if your files contain\n'
    printf 'newlines\n'
    exit 0
fi

output="$1"
shift
list="$(mktemp)"

while [ $# -gt 0 ]; do
    printf "file '%s'\\n" "$(readlink -fn "$1" | sed "s/'/'"'\\'"''/g")"
    shift
done >> "$list"

ffmpeg -f concat -safe 0 -i "$list" -c copy "$output" < /dev/null

rm "$list"
