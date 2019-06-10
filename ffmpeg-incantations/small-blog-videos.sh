#!/bin/sh

if [ $# -ne 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf 'Usage: %s <inputfile> <outputprefix>\n' "$0"
    printf '    This will generate <outputprefix>.mp4 and <outputprefix>.webm\n'
    exit 1
fi

input="$1"
output="$2"
framerate=15
gop=$((framerate * 2))

ffmpeg -y -i "$input" \
    -preset slow \
    -g "$gop" -c:v libx264 -b:v 256k -filter:v fps=fps="$framerate" -pass 1 \
    -an \
    -f mp4 /dev/null && \
ffmpeg -y -i "$input" \
    -preset slow \
    -g "$gop" -c:v libx264 -b:v 256k -filter:v fps=fps="$framerate" -pass 2 \
    -c:a aac -b:a 64k -ac 1 \
    -f mp4 "$output.mp4" && \
ffmpeg -y -i "$input" \
    -g "$gop" -c:v libvpx-vp9 -b:v 256k -filter:v fps=fps="$framerate" -pass 1 \
    -f webm /dev/null && \
ffmpeg -y -i "$input" \
    -g "$gop" -c:v libvpx-vp9 -b:v 256k -filter:v fps=fps="$framerate" -pass 2 \
    -c:a libopus -b:a 64k -ac 1 \
    -f webm "$output.webm"
