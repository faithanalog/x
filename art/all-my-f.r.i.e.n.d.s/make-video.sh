#!/bin/sh

set -ev

# apt install imagemagick
convert allmyfriends.png allmyfriends.ppm

# however you wanna install youtube-dl
youtube-dl -f bestvideo 'https://www.youtube.com/watch?v=Xs-HbHCcK58'

gcc -O3 -Wno-unused-result -o plt-rotate-anim plt-rotate-anim.c -lm

# TODO automate generating audio (its manual right now)

# apt install ffmpeg
ffmpeg \
    -loglevel fatal \
    -i Friends\ Original\ Intro\ in\ HIGH\ DEFINITION-Xs-HbHCcK58.mp4 \
    -t 44 \
    -f rawvideo -pix_fmt gray -y - < /dev/null \
    | ./plt-rotate-anim \
    | ffmpeg \
        -loglevel fatal \
        -r '26.767676767676768' -f rawvideo -pix_fmt argb -s 1280x720 -i - \
        -i ./all_my_f.r.i.e.n.d.s_audio.mp3 \
        -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p \
        -c:a copy \
        -r '26.767676767676768' -movflags +faststart -t 40 \
        'all_my_f.r.i.e.n.d.s.mp4' -y



