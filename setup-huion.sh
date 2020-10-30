#!/bin/bash
function tabletDimensions() {
    case "$1" in
        osu)
            echo 0 4170 0 2340
            ;;
        osu2)
            echo 500 3670 281 2060
            ;;
        fast)
            echo 0250 4420 200 2540
            ;;
        faster)
            echo 200 3288 200 1933
            ;;
        mapping)
            echo 0 6255 0 3510
            ;;
        full)
            echo 0 8340 0 4680
            ;;
        *)
            tabletDimensions osu2
            ;;
    esac
}

function transformMatrix() {
    case "$1" in
        right)
            echo 0.584 0 0.416 0 1 0 0 0 1
            ;;
        left)
            echo 0.584 0 0 0 1 0 0 0 1
            ;;
        full)
            echo 1 0 0 0 1 0 0 0 1
            ;;
        *)
            transformMatrix right
            ;;
    esac
}



IDS=(`xinput --list | awk -F '\t' '/HUION/{ print substr($2,4) }'`)
echo ${IDS[@]}
DIMS="$(tabletDimensions $1)"
TRANSFORM="$(transformMatrix $2)"

if [[ ${#IDS[@]} = '0' ]]; then
    echo "Tablet not found."
    exit 1
else
    for id in ${IDS[@]}; do
        echo $DIMS | xargs xinput set-prop "$id" "Evdev Axis Calibration"
        echo $TRANSFORM | xargs xinput set-prop "$id" --type=float "Coordinate Transformation Matrix"
    done
fi
