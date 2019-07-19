#!/bin/sh

ffmpeg -r 205 -f image2 -i 'frames/%03d.png' -filter_complex loop=loop=10:510:0 -vcodec libx264 -crf 25 -an -preset slow -r 60 -pix_fmt yuv420p -movflags faststart ./drug.mp4
