#!/bin/sh

input="$1"
if [ "$#" -eq 0 ]; then
    gui=yes
fi

if [ $gui = yes ]; then
    input="$(yad --center --title 'slides-to-ipod' --file --width 700 --height 480)"
    if [ $? -ne 0 ]; then
        exit 0
    fi
    term="xterm -hold -e"
else
    input="$1"
    term=""
fi

output="$(printf '%s' "$input" | sed 's/\..*$/.mkv/')"

if [ -f "$output" ]; then
    if [ $gui = yes ]; then
        if yad --center --button=gtk-no:1 --button=gtk-yes:0 --text "$output already exists. should we delete it?"; then
            rm "$output"
        else
            yad --center --text "Ok, exiting..."
            exit 0
        fi
    fi
fi

escape() {
    printf "'"'%s'"'" "$(printf '%s' "$1" | sed "s/'/'\"'\"'/g")"
}

$term ffmpeg -i "$(escape "$input")" -c:v libx264 -crf 21 -vf 'scale=1136:640,setsar=1:1' -tune stillimage -c:a copy "$(escape "$output")"

if [ $gui = yes ]; then
    yad --center --title 'slides-to-ipod' --text="Done! If everything went ok, file should be at $(realpath "$output")"
fi
