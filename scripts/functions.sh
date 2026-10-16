#!/bin/bash

#================
# Log Definitions
#================
export LINE='\n'                        # Line Break
export RESET='\033[0m'                  # Text Reset
export WhiteText='\033[0;37m'           # White

# Bold
export RedBoldText='\033[1;31m'         # Red
export GreenBoldText='\033[1;32m'       # Green
export YellowBoldText='\033[1;33m'      # Yellow
export CyanBoldText='\033[1;36m'        # Cyan
#================
# End Log Definitions
#================

LogInfo() {
  Log "$1" "$WhiteText"
}

LogWarn() {
  Log "$1" "$YellowBoldText"
}

LogError() {
  Log "$1" "$RedBoldText"
}

LogSuccess() {
  Log "$1" "$GreenBoldText"
}

LogAction() {
  Log "$1" "$CyanBoldText" "====" "===="
}

Log() {
  local message="$1"
  local color="$2"
  local prefix="$3"
  local suffix="$4"
  printf "$color%s$RESET$LINE" "$prefix$message$suffix"
}

# Only the lowest permission user group may be passwordless
CheckUserGroupPasswords() {
  local config="$1"
  [ -f "$config" ] || return 0

  local open_group
  open_group=$(tr -d '\r' < "$config" | jq -r '
    def perms: [.canKickBan, .canAccessInventories, .canEditWorld, .canEditBase, .canExtendBase] | map(select(. == true)) | length;
    (.userGroups // []) | (map(perms) | min) as $lowest
    | first(.[] | select((.password // "") == "" and perms > $lowest) | .name) // empty
    ')

  if [ -n "$open_group" ]; then
    LogError "User group \"$open_group\" has no password, but only the lowest-permission group can be passwordless."
    LogError "The server will not start with this config. Set a password on that group in enshrouded_server.json and restart the container."
    return 1
  fi
}

install() {
  LogAction "Starting server install"
  LogInfo "Updating steam client"
  su steam -s /bin/sh -c "/home/steam/steamcmd/steamcmd.sh +quit"

  LogInfo "Installing Enshrouded Dedicated Server"

  local beta_args=()
  if [ -n "${BETA_BRANCH}" ]; then
    beta_args+=(-beta "${BETA_BRANCH}")
    if [ -n "${BETA_PASSWORD}" ]; then
      beta_args+=(-betapassword "${BETA_PASSWORD}")
    fi
  fi

  local login_args=()
  if [ -n "${STEAM_USERNAME}" ]; then
    login_args+=(-username "${STEAM_USERNAME}" -password "${STEAM_PASSWORD}")
  fi

  /depotdownloader/DepotDownloader \
    -app 2278520 \
    -os windows \
    -dir /home/steam/enshrouded \
    "${login_args[@]}" \
    "${beta_args[@]}" \
    -validate

  LogSuccess "Server install complete"
}

# Attempt to shutdown the server gracefully
# Returns 0 if it is shutdown
# Returns 1 if it is not able to be shutdown
shutdown_server() {
  local return_val=0
  LogAction "Attempting graceful server shutdown"

  local pid
  pid=$(pgrep -f "enshrouded_server.exe" | head -1)

  if [ -n "$pid" ]; then
    kill -SIGTERM "$pid"

    local count=0
    while [ $count -lt 30 ] && kill -0 "$pid" 2>/dev/null; do
      sleep 1
      count=$((count + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
      LogWarn "Server did not shutdown gracefully, forcing shutdown"
      return_val=1
    else
      LogSuccess "Server shutdown gracefully"
    fi
  else
    LogWarn "Server process not found"
    return_val=1
  fi

  return "$return_val"
}
