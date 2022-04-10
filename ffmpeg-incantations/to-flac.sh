#!/bin/sh

# ffmpeg's flac encoder defaults to 24 bit audio for some reason when
# transcoding from a lossy format. We do this a fair bit because flac is
# more battery efficient on our sansa clip+ than decoding mp3 or opus or w/e.
# anyway, 24 bit also doesn't make any sense on that thing so this is just
# a shortcut for 16 bit flac

infile="$1"
otfile="$(printf '%s' "$infile" | sed 's/\.[^.]\+$/.flac/')"

# shift $1 out so we can do a $@ splat in the ffmpeg command for extra args
shift

ffmpeg -i "$infile" -sample_fmt s16 "$@" "$otfile"
