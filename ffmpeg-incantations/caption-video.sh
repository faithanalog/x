#!/bin/bash

# modify as needed

mkcaption() {
    # You need to go grab a font to use
    convert -font ./Fira_Sans/FiraSans-Bold.ttf -depth 8 -background black -fill white -size 1320x240 -pointsize 70 -gravity Center caption:"$1" "$2"
}

mkcaption "Caption 1" frames/1.rgb
mkcaption "Caption 2" frames/2.rgb
mkcaption "Caption 3" frames/3.rgb
mkcaption "Caption 4" frames/4.rgb

# The original script had a start and ending image added around the video
convert start.png -depth 8 start.rgb
convert end.png -depth 8 end.rgb
mkfifo frames/sfifo
mkfifo frames/efifo

yes start.rgb | head -n $((4 * 60)) | xargs cat > frames/sfifo &
yes end.rgb | head -n $((4 * 60)) | xargs cat > frames/efifo &


# Notice that -i gets used with two different mp4 files.
# This actually concatenated two separate videos I think
(
    yes frames/1.rgb | head -n $((10)) | xargs cat
    yes frames/2.rgb | head -n $((14)) | xargs cat
    yes frames/3.rgb | head -n $((6)) | xargs cat
    yes frames/4.rgb | head -n $((60)) | xargs cat
) | ffmpeg \
    -f rawvideo \
    -pixel_format rgb24 \
    -r 1 \
    -video_size 1320x240 \
    -i - \
    -i input1.mp4 \
    -i input2.mp4 \
    -f rawvideo -pixel_format rgb24 -video_size 1920x1080 -r 60 -i frames/sfifo \
    -f rawvideo -pixel_format rgb24 -video_size 1920x1080 -r 60 -i frames/efifo \
    -filter_complex '
        color=c=black:s=1920x1080 [black];
        [0:v] setpts=(PTS-STARTPTS)*2.0 [captions];
        [1:v] crop=421:368:1161:216, scale=960:840, select=gte(pts\, 2/TB), setpts=PTS-STARTPTS+20/TB [right];
        [1:v] crop=421:368:6:707, scale=960:840, select=gte(pts\, 2/TB), setpts=PTS-STARTPTS+20/TB [left];
        [2:v] crop=1920:840:0:0, setpts=(PTS-STARTPTS)*2.0 [prefix];
        [3:v] scale=1920:1080, setpts=(PTS-STARTPTS) [start];
        [4:v] scale=1920:1080, setpts=(PTS-STARTPTS) [end];
        [black][prefix] overlay=eof_action=pass [base];
        [base][left] overlay=shortest=1 [tmp1];
        [tmp1][right] overlay=shortest=1:x=960 [tmp2];
        [tmp2][captions] overlay=shortest=1:x=(1920/2)-(1320/2):y=840, setpts=0.5*(PTS-STARTPTS) [body];
        [start][body][end] concat=n=3:v=1:a=0
    ' \
    -an \
    -crf 18 \
    -r 30 \
    -preset slow \
    -c:v libx264 \
    -y output.mp4


rm frames/sfifo
rm frames/efifo
