#!/bin/sh

curl -s 'https://lapfoxarchive.com/music/' \
    | grep -o 'href="[^"]\+"' \
    | grep -o '%5B.\+%5D\.zip' \
    | sed 's/%20/ /g; s/%5B/[/g; s/%5D/]/g; s/%2B/+/g' \
    | grep -o '\[[^]]\+\]\.zip' \
    | sort -u
