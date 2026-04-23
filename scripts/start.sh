#!/bin/bash

# shellcheck source=scripts/functions.sh
source "/home/steam/server/functions.sh"

SERVER_FILES="/home/steam/enshrouded"
SERVER_EXEC="$SERVER_FILES/enshrouded_server.exe"
SERVER_CONFIG="$SERVER_FILES/enshrouded_server.json"

LogAction "Starting Enshrouded Dedicated Server"

if [ ! -f "$SERVER_EXEC" ]; then
    LogError "Could not find server executable at: $SERVER_EXEC"
    LogError "Directory contents:"
    ls -laR "$SERVER_FILES/" 2>/dev/null
    exit 1
fi

if [ "${GENERATE_SETTINGS:-true}" != "false" ]; then
    # If the config file doesn't exist yet (first boot)
    if [ ! -f "$SERVER_CONFIG" ]; then
        LogInfo "Creating default server configuration..."
        echo '{"userGroups":[{"name":"Default","password":"","canKickBan":false,"canAccessInventories":true,"canEditWorld":true,"canEditBase":true,"canExtendBase":true,"reservedSlots":0}]}' > "$SERVER_CONFIG"
    fi

    LogAction "Patching server config"

    tr -d '\r' < "$SERVER_CONFIG" | jq \
        --arg   name     "${SERVER_NAME}" \
        --arg   password "${SERVER_PASSWORD:-}" \
        --argjson qport  "${QUERY_PORT:-15637}" \
        --argjson slots  "${MAX_PLAYERS:-12}" \
        '
        .name = $name |
        (if $password != "" then .password = $password else del(.password) end) |
        .queryPort = $qport |
        .slotCount = $slots |
        .saveDirectory = "/home/steam/enshrouded/saves" |
        .userGroups[0].password = $password
        ' > "${SERVER_CONFIG}.tmp" && mv "${SERVER_CONFIG}.tmp" "$SERVER_CONFIG"

    LogSuccess "Server config patched"
fi

LogInfo "Server is starting..."

LOG_FILE="$SERVER_FILES/logs/enshrouded_server.log"

if [ "${ENGINE:-wine}" = "proton" ]; then
    LogInfo "Engine: Proton GE"

    export STEAM_COMPAT_DATA_PATH="/home/steam/enshrouded/saves/proton-prefix"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/steamcmd"
    export STEAM_COMPAT_APP_ID="2278520"
    export WINEDLLOVERRIDES="mscoree,mshtml="
    export DISPLAY=:99

    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
    sleep 2

    mkdir -p "$STEAM_COMPAT_DATA_PATH"

    python3 /opt/proton/proton run "$SERVER_EXEC" >/dev/null 2>&1 &
else
    LogInfo "Engine: Wine"

    export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
    export WINEARCH="${WINEARCH:-win64}"
    export WINEDEBUG="${WINEDEBUG:-fixme-all}"
    export WINEDLLOVERRIDES="mscoree,mshtml="

    xvfb-run --auto-servernum wine "$SERVER_EXEC" &
fi

LogInfo "Waiting for server log..."
timeout=30
while [ ! -f "$LOG_FILE" ] && [ "$timeout" -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
done

if [ -f "$LOG_FILE" ]; then
    tail -n +1 -f "$LOG_FILE" &
else
    LogWarn "Log file not found after 30s: $LOG_FILE"
fi

while pgrep -f "enshrouded_server" > /dev/null; do
    sleep 5
done
