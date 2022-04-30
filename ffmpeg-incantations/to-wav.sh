#!/bin/sh


infile="$1"
otfile="$(printf '%s' "$infile" | sed 's/\.[^.]\+$/.wav/')"

# shift $1 out so we can do a $@ splat in the ffmpeg command for extra args
shift

ffmpeg -i "$infile" -sample_fmt s16 "$@" "$otfile"
