#!/bin/sh

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input> <output.ico>"
    exit 1
fi

input="$1"
output="$2"

convert "$1" -resize 256x256 -transparent white "$output-256.png"
convert "$output-256.png" -resize 16x16 "$output-16.png"
convert "$output-256.png" -resize 32x32 "$output-32.png"
convert "$output-256.png" -resize 64x64 "$output-64.png"
convert "$output-256.png" -resize 128x128 "$output-128.png"
convert "$output-16.png" "$output-32.png" "$output-64.png" "$output-128.png" "$output-256.png" -colors 256 "$output"

rm -v "$output-16.png" "$output-32.png" "$output-64.png" "$output-128.png" "$output-256.png"
