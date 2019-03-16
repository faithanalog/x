#!/bin/sh

set -ev

# Requires curl and jq
(
    missingDependencies=no
    for dependency in curl jq; do
        if ! which "$dependency" > /dev/null; then
            echo "Missing required dependency $dependency"
            missingDependencies=yes
        fi
    done
    [ "$missingDependencies" = yes ]
    exit $?
) && exit 1

# TODO add checking for env variables existing
if [ -f "./env" ]; then
    . ./env
fi

# makeAPICall makes a discord API call to path $1 with data "$2"
# and stdin as the body. makeAPICall also takes care of discord
# rate limiting and authorization.
makeAPICall() {(
    verb="$1"
    path="$2"
    shift 2
    
    if [ "$verb" = "GET" ]; then
        verb="-G"
    else
        verb="-X $verb"
    fi

    # Convert the rest of the args to data-urlencode flags
    args=""

    while [ $# -gt 0 ]; do
        args="$args"$'\n'"--data-urlencode"$'\n'"$1"
    done

    # TODO why does this give "error malformed url"
    echo "$args" \
        | tr '\n' '\0' \
        | xargs -0 curl \
            -vvv \
            $verb \
            -H "Authorization: Bot $DISCORD_CLIENT_TOKEN" \
            -H "User-Agent: DiscordBot (https://github.com/faithanalog/x/blob/master/discord-channel-archive/discord-channel-archive.sh, v0.0.1)" \
            "https://discordapp.com/api/v6$path"
)}

get() {
    makeAPICall GET "$@"
}

put() {
    makeAPICall PUT "$@"
}

patch() {
    makeAPICall PATCH "$@"
}

# echo "Bot running... invite with the following link:"
# echo "https://discordapp.com/oauth2/authorize?client_id=$DISCORD_CLIENT_ID&scope=bot&permissions=66560"

get "/channels/513791425557823493"
echo
#get "/channels/513791425557823493/messages" "after=515211394992308234"
echo
