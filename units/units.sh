#!/bin/sh

if [ $# -lt 3 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 <number> <units> [to|in|as] <units>"
    exit 1
fi

n0="$1"
u0="$2"
if [ "$3" = "to" ] || [ "$3" = "in" ] || [ "$3" = "as" ]; then
    u1="$4"
else
    u1="$3"
fi

printf '%s %s %s\n' "$n0" "$u0" "$u1" | awk '
    function addTimeMapping(unit, nSeconds) {
        toSeconds[unit] = nSeconds
        fromSeconds[unit] = 1 / nSeconds
        toSeconds[unit "s"] = nSeconds
        fromSeconds[unit "s"] = 1 / nSeconds
    }
    BEGIN {
        # Time conversions
        addTimeMapping("second", 1)
        addTimeMapping("minute", 60)
        addTimeMapping("hour", toSeconds["minute"] * 60)
        addTimeMapping("day", toSeconds["hour"] * 24)
        addTimeMapping("week", toSeconds["hour"] * 7)
        addTimeMapping("year", toSeconds["week"] * 52)
        addTimeMapping("month", toSeconds["year"] / 12)
        addTimeMapping("millisecond", 1/1000)
        addTimeMapping("microsecond", toSeconds["millisecond"] / 1000)
        addTimeMapping("nanosecond", toSeconds["microsecond"] / 1000)

        addTimeMapping("milli", toSeconds["milliseconds"])
        addTimeMapping("micro", toSeconds["microseconds"])
        addTimeMapping("nano", toSeconds["nanoseconds"])
    }
    {
        value = $1
        unitStart = $2
        unitEnd = $3

        if (toSeconds[unitStart] != "" && fromSeconds[unitEnd] != "") {
            print (value * toSeconds[unitStart] * fromSeconds[unitEnd]) " " unitEnd
        } else {
            print "I can'"'"'t convert " $2 " to " $3
        }
    }
'

