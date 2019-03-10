#!/bin/sh

curl -s 'https://lapfoxarchive.com/music/' \
    | grep -o 'href="[^"]\+"' \
    | sort \
    | sed '
        # Remove HTML shit
        s/^href="//
        s/"$//
    ' \
    | awk '
        BEGIN {
            formats["FLAC"] = 15
            formats["MP3%20320"] = 14
            formats["MP3%20256+"] = 13
            formats["MP3%20256"] = 12
            formats["MP3%20V0"] = 11
            formats["MP3%20192+"] = 10
            formats["MP3%20192"] = 9
            formats["MP3%20V2"] = 8
            formats["MP3%20V4+"] = 7
            formats["MP3%20V4"] = 6
            formats["MP3%20160+"] = 5
            formats["MP3%20V5"] = 4
            formats["MP3%20128+"] = 3
            formats["MP3%20128"] = 2
            formats["MP3%2096"] = 1
        }
        function getFormatRank(format, rank) {
            rank = formats[format]
            if (rank == "") {
                return 0
            } else {
                return rank
            }
        }
        {
            link = $0
            gsub(/%5B/, "[")
            gsub(/%5D/, "]")
            if (!match($0, /\[[^\]]*\]\.zip$/)) {
                next
            }
            format=substr($0, RSTART + 1, RLENGTH - 6)
            album=substr($0, 1, RSTART - 1)
            if (formats[format] >= albumFormat[album]) {
                albumFormat[album] = formats[format]
                links[album] = link
            }
        }
        END {
            for (album in links) {
                print "https://lapfoxarchive.com/music/" links[album]
            }
        }
    ' \
    | wget -nc -i - 
