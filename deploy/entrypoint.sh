#!/bin/sh
# Renders the configs from templates, then runs whichever server was asked for.
#
# The configs are rendered at start rather than baked into the image so the
# WireGuard address is a runtime setting. Nobody has to commit their friend's
# IP to the repo, and changing it is an edit to .env plus a restart.
set -e

: "${SERVER_ADDRESS:?SERVER_ADDRESS is not set - put the servers WireGuard IP in deploy/.env}"
: "${REDIS_HOST:=redis}"
export SERVER_ADDRESS REDIS_HOST

mkdir -p /data
for name in server wServer; do
    if [ -f "/templates/${name}.json.template" ]; then
        envsubst < "/templates/${name}.json.template" > "/data/${name}.json"
    fi
done

case "$1" in
    app)
        # CoreService reads /data/server.json when IS_DOCKER is set.
        cd /app/app
        exec dotnet App.dll
        ;;
    world)
        # GameServer takes its config path as the first argument.
        cd /app/world
        exec dotnet WorldServer.dll /data/wServer.json
        ;;
    *)
        exec "$@"
        ;;
esac
