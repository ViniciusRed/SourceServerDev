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
ADDONS_INSTALLED_LOCK_FILE="${SERVER_DIR}/cstrike/addons/addons.lock"

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
    local type1=$(basename "$file" .zip)
    local type2=$(basename "$file" .tar.gz | sed 's/\.tar\.xz$//;s/\.tar\.bz2$//')

    # Loop through the found files and perform the corresponding extraction
    for file in $file; do
        way_complete="$dir/$file"
        case "$file" in
        *.zip)
            echo "> Extracting $file..."
            extract_zip "$way_complete"
            cd $type1
            echo "> Copying Files"
            cp -r . "$dir" && cd ..
            rm -r $type1
            ;;
        *.tar.gz | *.tar.xz | *.tar.bz2)
            echo "> Extracting $file..."
            extract_tar "$way_complete"
            cd $type2
            echo "> Copying Files"
            cp -r . "$dir" && cd ..
            rm -r $type2
            ;;
        *)
            echo "> Unknown extension for the file $file. Ignoring..."
            ;;
        esac
        rm -r $way_complete
    done
}

# Function to update the repository
update_git_repo() {
    git pull origin $branch
}

update_preset() {
    source "$SERVER_DIR/preset.cfg"

    # Nome do branch que será atualizado
    branch="main"

    # Check if the directory is a valid git repository
    if [ -d "$PRESET_FOLDER/.git" ]; then
        # Navega para o diretório do repositório
        cd "$PRESET_FOLDER"

        # Check if the branch exists in the Git repository
        if git rev-parse --verify "origin/$branch" &>/dev/null; then
            # Check if there are updates in the Git repository
            git fetch origin "$branch"
            LOCAL=$(git rev-parse "$branch")
            REMOTE=$(git rev-parse "origin/$branch")

            if [ "$LOCAL" = "$REMOTE" ]; then
                echo "> The preset $PRESET is already up to date. No necessary update."
                cd ..
            else
                echo "> There are updates available for the preset $PRESET. Updating the Preset ..."
                update_git_repo
                echo "> Successfully updated preset $PRESET!"
                echo '> Updating Preset'
                cp -r "PresetsServer/css/$PRESET/." "$SERVER_DIR/cstrike" && cd ..
            fi
        else
            echo "> The branch $branch does not exist in this repository."
            cd ..
        fi
    else
        echo "> Invalid directory or not a git repository."
        cd ..
    fi
}

preset_install() {
    local folder_git=$(basename "$1" .git)
    if [ "$PRESET_NOGIT" = "none" ]; then
        git clone --no-checkout $1 && cd "$folder_git" && echo PRESET_FOLDER=$folder_git >$SERVER_DIR/preset.cfg
        git sparse-checkout init --cone
        git sparse-checkout set $2
        git checkout @
        echo "> Copying Files"
        cp -r PresetsServer/css/$PRESET/. "$SERVER_DIR/cstrike" && cd ..
        echo "> Preset Installed"
    else
        echo "> Using the external preset"
        wget "$PRESET_NOGIT"
        echo "> Extracting the files"
        preset_extract
        echo "> External Preset Installed"
    fi
    touch $SERVER_PRESET_LOCK_FILE
}

preset() {
    if [ -z "$PRESET_NOGIT" ] || [ "$PRESET_NOGIT" != "none" ]; then
        preset_install $PRESET_NOGIT
    elif [ "$PRESET" = "none" ]; then
        echo "> Preset not chosen"
    elif [ -f "$SERVER_PRESET_LOCK_FILE" ]; then
        echo "> Preset already installed"
    else
        echo "> Installing Preset server"

        if [ "$PRESET_REPO" = "none" ]; then
            echo "> Using the Repo SourceServerDev"
            preset_install "$GIT" "PresetsServer/css/$PRESET"
        else
            echo "> Using the Repo $PRESET_REPO"
            preset_install "$PRESET_REPO" "$PRESET"
        fi
    fi
}

if [ ! -z $1 ]; then
    $1
else
    install_or_update
    crackserver_if_needs
    preset_or_update
    start
fi
