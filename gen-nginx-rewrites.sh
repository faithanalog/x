#!/bin/sh

cat redirects.conf | awk -F ' -> ' '
    /^[^# ]/ {
        if ($1 == "/") {
            print "rewrite ^" $1 "$" " " $2 " redirect;"
        } else {
            print "rewrite ^" $1 "$" " " $2 " permanent;"
        }
    }
' > nginx-rewrites.conf
