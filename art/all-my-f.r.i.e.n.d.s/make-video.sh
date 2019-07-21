#!/bin/sh

set -v

mkdir in-frames
mkdir ot-frames

set -e

# apt install imagemagick
convert allmyfriends.png allmyfriends.ppm

# however you wanna install youtube-dl
youtube-dl -f bestvideo 'https://www.youtube.com/watch?v=Xs-HbHCcK58'

# apt install ffmpeg
ffmpeg -i Friends\ Original\ Intro\ in\ HIGH\ DEFINITION-Xs-HbHCcK58.mp4 -t 44 -f image2 'in-frames/image%06d.ppm' -y

gcc -O3 -Wno-unused-result -o plt-rotate-anim plt-rotate-anim.c -lm

./plt-rotate-anim

ffmpeg \
    -r '26.767676767676768' -f image2 -i 'ot-frames/image-%06d.ppm' \
    -i ./all_my_f.r.i.e.n.d.s_audio.mp3 \
    -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p \
    -c:a copy \
    -r '26.767676767676768' -movflags +faststart -t 40 \
    'all_my_f.r.i.e.n.d.s.mp4' -y

rm -rv ./in-frames ./ot-frames ./plt-rotate-anim

# TODO automate generating audio (its manual right now)


