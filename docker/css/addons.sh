#!/bin/bash

# Set Debug
source config.cfg
if [[ $DEBUG_SHELL = true ]]; then
    echo "> Addons Shell Debug on"
    set -x
else
    echo "> Addons Shell Debug off"
fi

# Define destination paste
SERVER_DIR="${HOME}/css/cstrike"
ADDONS_INSTALLED_LOCK_FILE="${SERVER_DIR}/addons/addons.lock"
source $SERVER_DIR/addons/sourcemod/sourcemod.cfg
source $SERVER_DIR/addons/metamod/metamod.cfg

# Define the version variables and urls of downloads
sourcemod_version=$1
metamod_version=$1
sourcemod_url="https://www.sourcemod.net/latest.php?version=${sourcemod_version}&os=linux"
metamod_url="https://www.sourcemm.net/latest.php?version=${metamod_version}&os=linux"

# Sourcemod get latest version
sourcemod_latest_version=$(curl -sL -o /dev/null -w %{url_effective} "$sourcemod_url" | awk -F/ '{print $5}')
sourcemod_latest_gitcommit=$(curl -sL -o /dev/null -w %{url_effective} "$sourcemod_url" | grep -oP '\d+\.\d+\.\d+-(\K\w+)')

# Metamod get latest version
metamod_latest_version=$(curl -sL -o /dev/null -w %{url_effective} "$metamod_url" | awk -F/ '{print $5}')
metamod_latest_gitcommit=$(curl -sL -o /dev/null -w %{url_effective} "$metamod_url" | grep -oP '\d+\.\d+\.\d+-(\K\w+)')

# Function to verify that there are updates
function check_update {
    local current_version=$1
    local current_gitcommit=$2
    local url=$3

    local latest_version=$(curl -sL -o /dev/null -w %{url_effective} "$url" | awk -F/ '{print $5}')
    local latest_gitcommit=$(curl -sL -o /dev/null -w %{url_effective} "$url" | grep -oP '\d+\.\d+\.\d+-(\K\w+)')

    if
        [[ "$latest_version" != "$current_version" ]]
        [[ "$latest_gitcommit" != "$current_gitcommit" ]]
    then
        echo "> There is a new version available: $latest_version-$latest_gitcommit"
        return 1
    fi
    return 0
}

# Function to extract files
function extract_files {
    local file=$1
    local destination=$2

    tar -xzvf "$file" -C "$destination" $SOURCEMOD_TAR_ARG >>extract.log
    if [ $? -eq 0 ]; then
        echo "> Completed extraction."
    else
        echo "> Error by extracting the files."
    fi
}

# Check the installed version of Sourcemod
echo "> Checking the installed version of Sourcemod..."
if [ "$installed_sourcemod_version" ]; then
    echo "> Installed version of Sourcemod: $installed_sourcemod_version-$installed_sourcemod_gitcommit"
else
    echo "> Sourcemod Not found in the destination folder."
    echo "> Installing the Sourcemod..."
    wget -q "$sourcemod_url" -O sourcemod-latest.tar.gz
    extract_files "sourcemod-latest.tar.gz" "$SERVER_DIR"
    echo installed_sourcemod_version="$sourcemod_latest_version" >"$SERVER_DIR/addons/sourcemod/sourcemod.cfg"
    echo installed_sourcemod_gitcommit="$sourcemod_latest_gitcommit" >>"$SERVER_DIR/addons/sourcemod/sourcemod.cfg"
fi

# Check the installed version of the Metamod
echo "> Checking the installed version of the Metamod..."
if [ "$installed_metamod_version" ]; then
    echo "> Installed version of Metamod: $installed_metamod_version-$installed_metamod_gitcommit"
else
    echo "> Metamod Not found in the destination folder."
    echo "> Installing the Metamod..."
    wget -q "$metamod_url" -O metamod-latest.tar.gz
    extract_files "metamod-latest.tar.gz" "$SERVER_DIR"
    echo installed_metamod_version="$metamod_latest_version" >"$SERVER_DIR/addons/metamod/metamod.cfg"
    echo installed_metamod_gitcommit="$metamod_latest_gitcommit" >>"$SERVER_DIR/addons/metamod/metamod.cfg"
fi

# Check if there are updates of the Sourcemod
if [ -f "$ADDONS_INSTALLED_LOCK_FILE" ]; then
    echo "> Checking updates Sourcemod..."
    if check_update "$installed_sourcemod_version" "$installed_sourcemod_gitcommit" "$sourcemod_url"; then
        echo "> Sourcemod is up to date."
    else
        echo "> Downloading the new version of Sourcemod: $sourcemod_latest_version-$sourcemod_latest_gitcommit"
        wget -q "$sourcemod_url" -O sourcemod-latest.tar.gz
        extract_files "sourcemod-latest.tar.gz" "$SERVER_DIR"
        echo installed_sourcemod_version="$sourcemod_latest_version" >"$SERVER_DIR/addons/sourcemod/sourcemod.cfg"
        echo installed_sourcemod_gitcommit="$sourcemod_latest_gitcommit" >>"$SERVER_DIR/addons/sourcemod/sourcemod.cfg"
    fi
fi

# Check if there are updates of the Metamod
if [ -f "$ADDONS_INSTALLED_LOCK_FILE" ]; then
    echo ">  Checking updates Metamod..."
    if check_update "$installed_metamod_version" "$installed_metamod_gitcommit" "$metamod_url"; then
        echo "> Metamod is up to date."
    else
        echo "> Downloading the new version of Metamod: $metamod_latest_version-$metamod_latest_gitcommit"
        wget -q "$metamod_url" -O metamod-latest.tar.gz
        extract_files "metamod-latest.tar.gz" "$SERVER_DIR"
        echo installed_metamod_version="$metamod_latest_version" >"$SERVER_DIR/addons/metamod/metamod.cfg"
        echo installed_metamod_gitcommit="$metamod_latest_gitcommit" >>"$SERVER_DIR/addons/metamod/metamod.cfg"
    fi
fi
touch $ADDONS_INSTALLED_LOCK_FILE
