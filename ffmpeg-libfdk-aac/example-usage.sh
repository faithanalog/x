#!/bin/bash
sudo docker run -it --rm --mount type=bind,source='/mnt/rose/audio/Pony Music Archive 19.03 (Raw Quality),target=/raw,readonly' --mount type=bind,source='/mnt/rose/audio/Pony Music Archive 19.03 (m4a 256k)',target=/m4a sedfox/ffmpeg-libfdk-aac sh -l
