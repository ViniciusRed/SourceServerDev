preset_extract() {
    # Using the "ls" command to list the files in the directory
    # and "grep" to filter files with the desired extensions
    local dir=$SERVER_DIR/cstrike
    local file=$(ls "$dir" | grep -E '\.zip$|\.tar\.gz$|\.tar\.xz$|\.tar\.bz2$')
    local type1=$(basename "$file" .zip)
    local type2=$(basename "$file" .tar.gz | sed 's/\.tar\.xz$//;s/\.tar\.bz2$//')
    local cp="> Copying Files"

    # Loop through the found files and perform the corresponding extraction
    for file in $file; do
        way_complete="$dir/$file"
        case "$file" in
        *.zip)
            echo "> Extracting $file..."
            extract_zip "$way_complete"
            cd $type1
            echo $cp
            cp -r . "$dir" && cd ..
            rm -r $type1
            ;;
        *.tar.gz | *.tar.xz | *.tar.bz2)
            echo "> Extracting $file..."
            extract_tar "$way_complete"
            cd $type2
            echo $cp
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

recopy_preset() {
    cp -r "PresetsServer/css/$PRESET/." "$SERVER_DIR/cstrike" && cd ..
}

# Function to update the repository
update_git_repo() {
    git pull origin $branch
}

update_preset() {
    source "$SERVER_DIR/preset.cfg"

    # Nome do branch que será atualizado
    branch="$PRESET_BRANCH"

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
    local cp="> Copying Files"
    if [ "$PRESET_PRIVATE" = "true" ]; then
        git clone --no-checkout $1 && cd "$folder_git" && echo PRESET_FOLDER=$folder_git >$SERVER_DIR/preset.cfg
        git sparse-checkout init --cone
        git sparse-checkout set $2
        git checkout @
        echo $cp
        cp -r $PRESET/. "$SERVER_DIR/cstrike" && cd ..
        echo "> Private Preset Installed"
    elif [ "$PRESET_NOGIT" = "none" ]; then
        git clone --no-checkout $1 && cd "$folder_git" && echo PRESET_FOLDER=$folder_git >$SERVER_DIR/preset.cfg
        git sparse-checkout init --cone
        git sparse-checkout set $2
        git checkout @
        echo $cp
        cp -r PresetsServer/css/$PRESET/. "$SERVER_DIR/cstrike" && cd ..
        echo "> Preset Installed"
    else
        echo "> Using the external preset"
        cd "$SERVER_DIR/cstrike" && wget "$PRESET_NOGIT" && cd ${HOME}
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

        if [ "$PRESET_PRIVATE" = "true" ]; then
            echo "> Using the Private Repo $PRESET_REPO"
            preset_install "$PRESET_REPO_TOKEN" "$PRESET"
        elif [ "$PRESET_REPO" = "none" ]; then
            echo "> Using the Repo SourceServerDev"
            preset_install "$GIT" "PresetsServer/css/$PRESET"
        else
            echo "> Using the Public Repo $PRESET_REPO"
            preset_install "$PRESET_REPO" "$PRESET"
        fi
    fi
}
