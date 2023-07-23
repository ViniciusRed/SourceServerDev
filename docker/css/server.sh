#!/bin/bash

source config.cfg

set -e

shopt -s extglob

if [[ $DEBUG_SHELL = true ]]; then
    echo "> Server Shell Debug on"
    set -x
else
    echo "> Server Shell Debug off"
fi
GIT=https://github.com/ViniciusRed/SourceServerDev.git
SERVER_DIR="${HOME}/css"
NONSTEAM_DIR="${HOME}/nonsteam/"
SERVER_INSTALLED_LOCK_FILE="${SERVER_DIR}/installed.lock"
SERVER_NONSTEAM_LOCK_FILE="${SERVER_DIR}/nonsteam.lock"
SERVER_PRESET_LOCK_FILE="${SERVER_DIR}/preset.lock"

install_or_update() {
    if [ -f "$SERVER_INSTALLED_LOCK_FILE" ]; then
        update
    else
        install
    fi
}

function update {
    local app_id=232330
    local update_check=$(steamcmd +login anonymous +app_info_update 1 +app_info_print "$app_id" +quit | grep -c "update available")

    if [ "$update_check" -gt 0 ]; then
        echo "> There is an update available for the App ID $app_id. Updating..."
        steamcmd +login anonymous +force_install_dir $SERVER_DIR +app_update "$app_id" +quit >/dev/null
        echo "> The update was completed."
    else
        echo "> App ID $app_id It is already updated."
    fi
}

install() {
    echo '> Installing Server'

    steamcmd \
        +force_install_dir $SERVER_DIR \
        +login anonymous \
        +app_update 232330 validate \
        +quit >/dev/null

    touch $SERVER_INSTALLED_LOCK_FILE
}

start() {

    ./addons.sh $SOURCEMOD_VERSION
    echo '> Starting FastDl ...'
    export FASTDL_PORT=$FASTDL_PORT
    python fastdl.py &
    echo '> Starting Server ...'
    additionalParams=""

    if [ $DEBUG = true ]; then
        additionalParams+=" -debug"
    fi

    if [ $ENABLE_INSECURE = true ]; then
        additionalParams+=" -insecure"
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

    $SERVER_DIR/srcds_run \
        -game cstrike \
        -console \
        +ip 0.0.0.0 \
        -port "$SERVER_PORT" \
        +maxplayers "$MAX_PLAYERS" \
        $additionalParams
}

crackserver_if_needs() {
    if [ ! -f "$SERVER_NONSTEAM_LOCK_FILE" ]; then
        if [ $SERVER_NONSTEAM = true ]; then
            sleep 2

            echo '> Cracking Server'
            mv $SERVER_DIR/bin/steamclient.so $SERVER_DIR/bin/steamclient_valve.so
            cp -ar $HOME/nonsteam/* $SERVER_DIR
            echo '> Done'
            rm -r $NONSTEAM_DIR
            touch $SERVER_NONSTEAM_LOCK_FILE
            sleep 2
        else
            if [ $SERVER_NONSTEAM = false ]; then
                if [ -d $NONSTEAM_DIR ]; then
                    rm -r $NONSTEAM_DIR
                fi
            fi
        fi
    fi
}

function extract_zip {
    unzip "$1"
}

# Function to extract file tar.gz, tar.xz, tar.bz2
function extract_tar {
    tar -xf "$1"
}

preset_extract() {
    # Using the "ls" command to list the files in the directory
    # and "grep" to filter files with the desired extensions
    local dir=$SERVER_DIR/cstrike
    local file=$(ls "$dir" | grep -E '\.zip$|\.tar\.gz$|\.tar\.xz$|\.tar\.bz2$')
    # Loop through the found files and perform the corresponding extraction
    for file in $file; do
        way_complete="$dir/$file"
        case "$file" in
        *.zip)
            echo "Extracting $file..."
            extract_zip "$way_complete"
            cd $(basename "$file" .zip)
            ;;
        *.tar.gz | *.tar.xz | *.tar.bz2)
            echo "Extracting $file..."
            extract_tar "$way_complete"
            cd $(basename "$file" .tar.gz | sed 's/\.tar\.xz$//;s/\.tar\.bz2$//')
            ;;
        *)
            echo "Unknown extension for the file $file. Ignoring..."
            ;;
        esac
        rm -r $way_complete
    done
}

preset_install() {

    if [ "$PRESET_NOGIT" = "none" ]; then
        git clone "$1" && cd "$(basename "$1" .git)"
    else
        echo "> Using the external preset"
        wget "$1"
        if [ "$PRESET_NOGIT" = "none" ]; then
            echo "> Copying Files"
            cp -r . "$SERVER_DIR/cstrike" && cd..
            echo "> Preset Installed"
        else
            echo "> Extracting the files"
            preset_extract
            echo "> Copying Files"
            cp -r . "$SERVER_DIR/cstrike" && cd ..
            echo "> External Preset Installed"
        fi
        touch $SERVER_PRESET_LOCK_FILE
    fi
}

preset() {
    if [ "$PRESET" = "none" ]; then
        echo "> Preset not chosen"
    elif [ -f "$SERVER_PRESET_LOCK_FILE" ]; then
        echo "> Preset already installed"
    elif [ "$PRESET_NOGIT" = "none" ]; then
        echo "> Installing Preset server"

        if [ "$PRESET_REPO" = "none" ]; then
            echo "> Using the Repo SourceServerDev"
            preset_install "$GIT"
        else
            echo "> Using the Repo $PRESET_REPO"
            preset_install "$PRESET_REPO"
        fi
    else
        echo "> Installing Preset server"
        preset_install
    fi
}

if [ ! -z $1 ]; then
    $1
else
    install_or_update
    crackserver_if_needs
    preset
    start
fi
