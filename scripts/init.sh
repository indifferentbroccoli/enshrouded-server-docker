#!/bin/bash

# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

LogAction "Set file permissions"

if [ -z "${PUID}" ] || [ -z "${PGID}" ]; then
    LogError "PUID and PGID not set. Please set these in the environment variables."
    exit 1
else
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
fi

# Fake a Linux machine ID so Proton doesn't panic
if [ "${ENGINE:-wine}" = "proton" ] && [ ! -f /etc/machine-id ]; then
    LogInfo "Generating missing machine-id for Proton..."
    cat /proc/sys/kernel/random/uuid > /etc/machine-id
fi

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

mkdir -p /home/steam/enshrouded
chown -R steam:steam /home/steam/

cat /branding

if [ "${UPDATE_ON_START:-true}" = "true" ]; then
    install
else
    LogWarn "UPDATE_ON_START is set to false, skipping server update"
fi

chown -R steam:steam /home/steam/enshrouded

# shellcheck disable=SC2317
term_handler() {
    if ! shutdown_server; then
        local pid
        pid=$(pgrep -f "enshrouded_server" | head -1)
        if [ -n "$pid" ]; then
            kill -SIGTERM "$pid"
        fi
    fi
    sleep 2
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

export SERVER_NAME="${SERVER_NAME:-Indifferent Broccoli Enshrouded Server}"
export QUERY_PORT="${QUERY_PORT:-15637}"
export MAX_PLAYERS="${MAX_PLAYERS:-12}"
export SERVER_PASSWORD="${SERVER_PASSWORD:-}"
export UPDATE_ON_START="${UPDATE_ON_START:-true}"
export GENERATE_SETTINGS="${GENERATE_SETTINGS:-true}"

# Start the server as the steam user, passing through all required environment variables
su - steam -w "ENGINE,SERVER_NAME,QUERY_PORT,MAX_PLAYERS,SERVER_PASSWORD,GENERATE_SETTINGS" \
    -c "cd /home/steam/server && ./start.sh" &

killpid="$!"
wait "$killpid"
