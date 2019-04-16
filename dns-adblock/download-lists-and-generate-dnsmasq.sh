#!/bin/sh

set -e

adlists='
# The below list amalgamates several lists we used previously.
# See `https://github.com/StevenBlack/hosts` for details
##StevenBlack`s list
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

##MalwareDomains
https://mirror1.malwaredomains.com/files/justdomains

##Cameleon
http://sysctl.org/cameleon/hosts

##Zeustracker
https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist

##Disconnect.me Tracking
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt

##Disconnect.me Ads
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt

##Hosts-file.net
https://hosts-file.net/ad_servers.txt

# Fakenews
https://raw.githubusercontent.com/marktron/fakenews/master/fakenews
'

dl_file="$(mktemp)"
aggregate_file="$(mktemp)"
output_file=./adblock.list

download_list() {
    url="$1"
    # Get just the domain from the URL
    domain=$(echo "${url}" | cut -d'/' -f3)

    agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36"

    # Use a case statement to download lists that need special cURL commands
    # to complete properly and reset the user agent when required
    case "$domain" in
        "adblock.mahakala.is")
        agent='Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
        cmd_ext="-e http://forum.xda-developers.com/"
        ;;

        "adaway.org")
        agent='Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
        ;;

        "pgl.yoyo.org")
        cmd_ext="-d mimetype=plaintext -d hostformat=hosts"
        ;;

        # Default is a simple request
        *) cmd_ext=""
    esac
    curl -sS "$url" $cmd_ext -A "$agent" >> "$dl_file"
}

printf '%s' "$adlists" | grep '^[^# ]' | while read -r url; do
    download_list "$url"
done

cat "$dl_file" \
    | sed '
        # Remove comments
        s/#.*$//g

        # Remove leading spaces
        s/^[ \t]*//

        # Remove trailing spaces
        s/[ \t]*$//

        # Remove DOS newlines
        s/\r//g
    ' \
    | awk '/./ { print $2 }' \
    | grep -v \
        -e '^localhost$' \
        -e '^localhost\.localdomain$' \
        -e '^local$' \
        -e '^broadcasthost$' \
        -e '^0.0.0.0$' \
    | sed 's/^/0.0.0.0 /' \
    | sort \
    | uniq \
    > "$aggregate_file"

mv "$aggregate_file" "$output_file"
chmod 644 "$output_file"
rm "$dl_file"
