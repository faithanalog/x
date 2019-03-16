#!/bin/sh

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
)

if [ $? = 0 ]; then
    exit 1
fi

# TODO add checking for env variables existing
if [ -f "./env" ]; then
    source ./env
fi

# makeAPICall makes a discord API call to path $1 with data "$2"
# and stdin as the body. makeAPICall also takes care of discord
# rate limiting and authorization.
makeAPICall() {(
    verb="$1"
    path="$2"
    curl \
        -G \
        -H "Authorization: bot $DISCORD_CLIENT_TOKEN" \
        -H "User-Agent: DiscordBot (TODO, v0.0.1)" \
        --data "$3"
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


get "/channels/513791425557823493"
