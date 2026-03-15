#!/bin/bash

# if the user has not defined a PUID and PGID, throw an error and exit
if [ -z "${PUID}" ] || [ -z "${PGID}" ]; then
    LogError "PUID and PGID not set. Please set these in the environment variables."
    exit 1
else
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
fi

mkdir -p /opt/enshrouded-saves
chown -R steam:steam /opt/enshrouded /opt/enshrouded-saves

echo "Checking for Enshrouded updates via SteamCMD..."

if [ -z "$BETA_BRANCH" ]; then
    BETA_FLAG=""
else
    BETA_FLAG="-beta $BETA_BRANCH"
fi

su - steam -c "/home/steam/steamcmd/steamcmd.sh +force_install_dir /opt/enshrouded +login anonymous +app_update 2278520 $BETA_FLAG validate +quit"

echo "Applying environment variables to configuration..."
cd /opt/enshrouded

# If the config file doesn't exist yet (first boot), create a basic valid JSON skeleton
if [ ! -f "enshrouded_server.json" ]; then
    echo "{}" > enshrouded_server.json
fi

# Surgically inject the core variables into the JSON file
jq --arg name "$SERVER_NAME" \
   --arg port "$SERVER_PORT" \
   --arg qport "$QUERY_PORT" \
   --arg slots "$SLOT_COUNT" \
   '.name = $name | 
    .gamePort = ($port | tonumber) | 
    .queryPort = ($qport | tonumber) | 
    .slotCount = ($slots | tonumber) | 
    .saveDirectory = "/opt/enshrouded-saves"' \
   enshrouded_server.json > temp_config.json && mv temp_config.json enshrouded_server.json

# Give the steam user ownership of the newly edited config
chown steam:steam enshrouded_server.json

# This function catches Docker's "Stop" button and gracefully shuts down Wine
term_handler() {
    echo "Shutdown signal received! Gracefully stopping Enshrouded..."
    su - steam -c "pkill -15 enshrouded_server.exe"
    exit 143
}

# Trap the standard Linux termination signals
trap 'term_handler' SIGTERM SIGINT

echo "Booting Enshrouded Server..."
# Launch the Windows executable using Wine and our invisible monitor (xvfb)
# The '&' puts it in the background so the script can wait for the trap
if [ "$USE_PROTON" = "true" ]; then
    echo "Engine: Proton GE"
    # Proton requires a defined fake C: drive path to run
    export STEAM_COMPAT_DATA_PATH="/opt/enshrouded-saves/proton-prefix"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/steamcmd"
    su - steam -c "xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' python3 /opt/proton/proton run /opt/enshrouded/enshrouded_server.exe" &
else
    echo "Engine: Standard Wine"
    su - steam -c "xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' wine /opt/enshrouded/enshrouded_server.exe" &
fi

# Wait continuously for the process to finish or for a shutdown signal
WAIT_PID=$!
wait $WAIT_PID