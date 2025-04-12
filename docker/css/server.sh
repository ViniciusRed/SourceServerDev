#!/bin/bash

source .ads/preset.sh

set -e

shopt -s extglob

GIT=https://github.com/ViniciusRed/SourceServerDev.git
SERVER_DIR="${HOME}/css"
NONSTEAM_DIR="${HOME}/.ads/nonsteam/"
SERVER_INSTALLED_LOCK_FILE="${HOME}/.ads/installed.lock"
SERVER_NONSTEAM_LOCK_FILE="${HOME}/.ads/nonsteam.lock"
SERVER_PRESET_LOCK_FILE="${HOME}/.ads/preset.lock"
ADDONS_INSTALLED_LOCK_FILE="${HOME}/.ads/addons.lock"
APP_ID=232330
STEAMCLIENT=$SERVER_DIR/bin/steamclient.so
RENAME_STEAMCLIENT=$SERVER_DIR/bin/steamclient_valve.so

generate_config() {
    declare -A config_table
    local lock_file="${HOME}/.ads/config.lock"
    local config_file="${HOME}/config.cfg"

    # Define expected variables and their defaults
    declare -A default_values=(
        ["RCON_PASSWORD"]="yourkey"
        ["ADDONS_VER"]="false"
        ["PRESET"]="none"
        ["PRESET_REPO"]="none"
        ["PRESET_BRANCH"]="main"
        ["PRESET_NOGIT"]="none"
        ["PRESET_PRIVATE"]="false"
        ["PRESET_REPO_TOKEN"]="none"
        ["SOURCEMOD_VERSION"]="1.12"
        ["METAMOD_VERSION"]="1.12"
        ["SERVER_TOKEN"]='""'
        ["SERVER_HOSTNAME"]="SourceServerDev"
        ["SERVER_PASSWORD"]='""'
        ["SERVER_PORT"]="27015"
        ["TICKRATE"]="66"
        ["FASTSTART"]="false"
        ["DISABLEADDONSUPDATE"]="false"
        ["DISABLE_HLTV"]="false"
        ["SERVER_MAP"]="de_dust2"
        ["SERVER_LAN"]="0"
        ["SERVER_NONSTEAM"]="false"
        ["MAX_PLAYERS"]="10"
        ["ENABLE_INSECURE"]="false"
        ["DEBUG"]="false"
        ["USE_GDB_DEBUG"]="false"
        ["DEBUG_SHELL"]="false"
        ["NOTRAP"]="false"
        ["NOWATCHDOG"]="false"
        ["IGNORESIGINT"]="false"
        ["NORESTART"]="false"
        ["MAPSYNC_AUTOMATIC"]="false"
        ["MAPSYNC_APIKEY"]="none"
        ["MAPSYNC_TIMEOUT"]="10"
        ["MAPSYNC_INTERVAL"]="60"
        ["MAPSYNC_FORCE"]="false"
    )

    # Check if config needs to be generated
    if [ ! -f "$lock_file" ] || [ ! -f "$config_file" ]; then
        # Generate new config
        for key in "${!default_values[@]}"; do
            config_table[$key]=${!key:-${default_values[$key]}}
            echo "$key=${config_table[$key]}" >>"$config_file"
        done
        touch "$lock_file"
    else
        # Ler configuração existente
        while IFS='=' read -r key value; do
            # Remover possíveis espaços em branco
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            if [ ! -z "$key" ]; then
                config_table[$key]=$value
            fi
        done <"$config_file"

        # Verificar valores ausentes e usar defaults apenas para eles
        local config_updated=false
        local temp_file=$(mktemp)

        for key in "${!default_values[@]}"; do
            if [ -z "${config_table[$key]}" ]; then
                config_table[$key]=${!key:-${default_values[$key]}}
                config_updated=true
            fi
            echo "$key=${config_table[$key]}" >>"$temp_file"
        done

        # Se houve atualização, substituir arquivo antigo
        if [ "$config_updated" = true ]; then
            mv "$temp_file" "$config_file"
            touch "$lock_file"
        else
            rm "$temp_file"
        fi
    fi
}

install_or_update() {
    if [ -f "$SERVER_INSTALLED_LOCK_FILE" ]; then
        update
    else
        install
    fi
}

function update {
    echo "> Checking for updates for App ID $APP_ID..."

    local TEMP_FILE=$(mktemp)

    steamcmd +login anonymous +app_info_update 1 +app_info_print "$APP_ID" +quit >"$TEMP_FILE" 2>&1

    # Check if server directory exists and has files
    if [ ! -d "$SERVER_DIR" ] || [ -z "$(ls -A "$SERVER_DIR" 2>/dev/null)" ]; then
        echo "> Server directory empty or non-existent. Performing initial installation..."
        NEEDS_UPDATE=true
    elif grep -q "state.*updating" "$TEMP_FILE"; then
        echo "> Update available detected on Steam."
        NEEDS_UPDATE=true
    elif grep -q "missing executable" "$TEMP_FILE"; then
        echo "> Executable missing. Reinstallation needed."
        NEEDS_UPDATE=true
    else
        # Quick check - if server is running, assume it's up to date
        if [ -n "$(pgrep -f "$SERVER_DIR")" ]; then
            echo "> Server is already running. Assuming it's up to date."
            NEEDS_UPDATE=false
        else
            echo "> Performing quick update check..."
            # Run a simple update without validation (faster)
            steamcmd +login anonymous +force_install_dir "$SERVER_DIR" +app_update "$APP_ID" +quit >"$TEMP_FILE" 2>&1

            if grep -q "already up to date" "$TEMP_FILE"; then
                echo "> App ID $APP_ID is already up to date."
                NEEDS_UPDATE=false
            else
                echo "> Possible update available."
                NEEDS_UPDATE=true
            fi
        fi
    fi

    # If update needed, run the full process
    if [ "$NEEDS_UPDATE" = true ]; then
        echo "> Running update..."
        steamcmd +login anonymous +force_install_dir "$SERVER_DIR" +app_update "$APP_ID" +quit >"$TEMP_FILE" 2>&1

        # Check if update was successful
        if grep -q "Success" "$TEMP_FILE" || grep -q "fully installed" "$TEMP_FILE"; then
            echo "> Update completed successfully."
            rm "$TEMP_FILE"
            return 0
        else
            echo "> Update failed. Running with full validation..."
            # If it fails, try one last time with full validation
            steamcmd +login anonymous +force_install_dir "$SERVER_DIR" +app_update "$APP_ID" validate +quit

            if [ $? -eq 0 ]; then
                echo "> Update with validation completed successfully."
                return 0
            else
                echo "> Update failed even with full validation."
                return 1
            fi
        fi
    else
        echo "> Server is already up to date."
        rm "$TEMP_FILE"
        return 0
    fi
}

install() {
    echo '> Installing Server'

    steamcmd \
        +login anonymous \
        +force_install_dir $SERVER_DIR \
        +app_update $APP_ID validate \
        +quit >/dev/null

    touch $SERVER_INSTALLED_LOCK_FILE
}

start() {
    while true; do
        .ads/sync-config.sh

        if [ "$MAPSYNC_AUTOMATIC" = "true" ]; then
            .ads/mapsync.sh &
        else
            .ads/mapsync.sh
        fi

        find $HOME -type d,f -exec chown SourceServerDev:SourceServerDev {} \;
        if [ -d "$SERVER_DIR/cstrike/download/user_custom" ]; then
            rm -r $SERVER_DIR/cstrike/download/user_custom >/dev/null
        fi

        if [ -n "$(find $SERVER_DIR/cstrike/logs/ -maxdepth 1 -name '*.log')" ]; then
            rm -r $SERVER_DIR/cstrike/logs/*.log >/dev/null
        fi

        if [ $DISABLEADDONSUPDATE = false ]; then
            if [ $ADDONS_VER = true ]; then
                .ads/addons.sh $SOURCEMOD_VERSION $METAMOD_VERSION
            else
                .ads/addons.sh $SOURCEMOD_VERSION
            fi
        fi

        echo '> Starting Server ...'
        additionalParams=""

        if [ $DEBUG = true ]; then
            additionalParams+=" -debug"
            additionalParams+=" -dev"
            additionalParams+=" -dumplongticks"
        fi

        if [ $USE_GDB_DEBUG = true ]; then
            additionalParams+=" -gdb /bin/gdb"
        fi

        if [ $NOWATCHDOG = true ]; then
            additionalParams+=" -nowatchdog"
        fi

        if [ $NOTRAP = true ]; then
            additionalParams+=" -notrap"
        fi

        if [ $DISABLE_HLTV = true ]; then
            additionalParams+=" -nohltv"
        fi

        if [ $IGNORESIGINT = true ]; then
            additionalParams+=" -ignoresigint"
        fi

        if [ $ENABLE_INSECURE = true ]; then
            additionalParams+=" -insecure"
        fi

        if [ $NORESTART = true ]; then
            additionalParams+=" -norestart"
        fi

        if [ "${SERVER_LAN}" = "1" ]; then
            additionalParams+=" +sv_lan $SERVER_LAN"
        fi

        if [ ! -z "${RCON_PASSWORD}" ]; then
            additionalParams+=" +rcon_password \"$RCON_PASSWORD\""
        fi

        if [ ! -z "${SERVER_HOSTNAME}" ]; then
            additionalParams+=" +hostname \"$SERVER_HOSTNAME\""
        fi

        if [ ! -z "${SERVER_MAP}" ]; then
            additionalParams+=" +map $SERVER_MAP"
        fi

        if [ ! -z "${SERVER_PASSWORD}" ]; then
            additionalParams+=" +sv_password $SERVER_PASSWORD"
        fi

        if [ ! -z "${SERVER_TOKEN}" ]; then
            additionalParams+=" +sv_setsteamaccount $SERVER_TOKEN"
        fi

        if [ ! -z "${TICKRATE}" ]; then
            additionalParams+=" -tickrate $TICKRATE"
        fi

        # Run the server
        if [ $DEBUG = true ]; then
            $SERVER_DIR/srcds_run \
                -game cstrike \
                -console \
                +ip 0.0.0.0 \
                -port "$SERVER_PORT" \
                +maxplayers "$MAX_PLAYERS" \
                $additionalParams
        else
            sudo -u SourceServerDev $SERVER_DIR/srcds_run \
                -game cstrike \
                -console \
                +ip 0.0.0.0 \
                -port "$SERVER_PORT" \
                +maxplayers "$MAX_PLAYERS" \
                $additionalParams
        fi

        echo "> Server exited, restarting in 5 seconds..."
        sleep 5
    done
}

toggle_server_crack() {

    if [ "$SERVER_NONSTEAM" = true ] && [ ! -f "$SERVER_NONSTEAM_LOCK_FILE" ]; then
        echo '> Cracking Server'

        if [ -f "$STEAMCLIENT" ]; then
            mv "$STEAMCLIENT" "$RENAME_STEAMCLIENT"
            if [ -d "$NONSTEAM_DIR" ]; then
                cp -ar "$NONSTEAM_DIR"* "$SERVER_DIR"
                touch "$SERVER_NONSTEAM_LOCK_FILE"
                echo '> Done'
            else
                echo '> Error: NONSTEAM_DIR not found'
                mv "$RENAME_STEAMCLIENT" "$STEAMCLIENT"
            fi
        else
            echo '> Error: STEAMCLIENT not found'
        fi
    elif [ "$SERVER_NONSTEAM" = false ] && [ -f "$SERVER_NONSTEAM_LOCK_FILE" ]; then
        echo '> Removing Cracked Server'

        if [ -f "rev.ini" ]; then
            rm -f "rev.ini"
        fi
        if [ -f "rev-client.log" ]; then
            rm -f "rev-client.log"
        fi
        if [ -f "$RENAME_STEAMCLIENT" ]; then
            rm -f "$STEAMCLIENT"
            mv "$RENAME_STEAMCLIENT" "$STEAMCLIENT"
            rm -f "$SERVER_NONSTEAM_LOCK_FILE"
            echo '> Done'
        else
            echo '> Error: Backup steamclient not found'
        fi
    fi
    sleep 2

}

preset_or_update() {
    if [ -f "$ADDONS_INSTALLED_LOCK_FILE" ]; then
        if [ -f "$SERVER_PRESET_LOCK_FILE" ]; then
            update_preset
        else
            preset
        fi
    else
        echo "> Addons not installed. install preset will not be executed"
    fi
}

generate_config
source config.cfg
export SERVER_PORT=$SERVER_PORT

if [[ $DEBUG_SHELL = true ]]; then
    echo "> Server Shell Debug on"
    set -x
else
    echo "> Server Shell Debug off"
fi

if [ $FASTSTART = false ]; then
    install_or_update
    preset_or_update
fi
.ads/system.sh
toggle_server_crack
start
