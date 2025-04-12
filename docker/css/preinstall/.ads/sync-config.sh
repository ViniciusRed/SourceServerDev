#!/bin/bash

CONFIG_FILE="$HOME/config.cfg"

update_config() {
    declare -A config_table

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

    # Load current config values
    while IFS='=' read -r key value; do
        # Remove espaços em branco e aspas
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | sed 's/^"//;s/"$//')
        if [ ! -z "$key" ]; then
            config_table[$key]=$value
        fi
    done <"$CONFIG_FILE"

    # Update only if values are different
    for key in "${!default_values[@]}"; do
        current_value="${config_table[$key]}"
        new_value="${!key:-${default_values[$key]}}"
        
        # Se a variável de ambiente não estiver definida, mantenha o valor atual
        if [ -z "${!key}" ] && [ ! -z "$current_value" ]; then
            continue
        fi
        
        # Remove aspas para comparação
        current_value=$(echo "$current_value" | sed 's/^"//;s/"$//')
        new_value=$(echo "$new_value" | sed 's/^"//;s/"$//')
        
        if [ "$current_value" != "$new_value" ]; then
            config_table[$key]=$new_value
            # Preserva as aspas no arquivo se necessário
            if [[ "$new_value" == *" "* ]]; then
                sed -i "s|^$key=.*|$key=\"$new_value\"|" "$CONFIG_FILE"
            else
                sed -i "s|^$key=.*|$key=$new_value|" "$CONFIG_FILE"
            fi
        fi
    done
}

update_env() {
    while IFS='=' read -r key value; do
        export "$key=$value"
    done <"$CONFIG_FILE"
}

update_config
