#!/bin/bash

set -euo pipefail

# Source configuration
source config.cfg

# Set Debug
if [[ ${DEBUG_SHELL:-false} = true ]]; then
    echo "> Addons Shell Debug on"
    set -x
else
    echo "> Addons Shell Debug off"
fi

# Define constants
SERVER_DIR="${HOME}/css/cstrike"
ADDONS_INSTALLED_LOCK_FILE="${HOME}/.ads/addons.lock"
SOURCEMOD_CFG="$SERVER_DIR/addons/sourcemod/sourcemod.cfg"
METAMOD_CFG="$SERVER_DIR/addons/metamod/metamod.cfg"
is_update_orgn=false

# Source existing configurations if they exist
[[ -f $SOURCEMOD_CFG ]] && source $SOURCEMOD_CFG
[[ -f $METAMOD_CFG ]] && source $METAMOD_CFG

# Define version variables and URLs
if [ "$ADDONS_VER" = false ]; then
    sourcemod_version=$1
    metamod_version=$1
else
    sourcemod_version=$1
    metamod_version=$2
fi
sourcemod_url="https://www.sourcemod.net/latest.php?version=${sourcemod_version}&os=linux"
metamod_url="https://www.metamodsource.net/latest.php?version=${metamod_version}&os=linux"

# Function to get latest version and git commit
get_latest_info() {
    local url=$1
    local version=$(curl -sL -o /dev/null -w %{url_effective} "$url" | awk -F/ '{print $5}')
    local gitcommit=$(curl -sL -o /dev/null -w %{url_effective} "$url" | grep -oP '\d+\.\d+\.\d+-(\K\w+)')

    if [[ -z "$version" || -z "$gitcommit" ]]; then
        echo "> Failed to get version info from $url. Trying previous version..."
        local previous_version=$(echo $version | awk -F. '{print $1"."$2"."$3-1}')
        local previous_url=$(echo $url | sed "s/$version/$previous_version/")
        version=$(curl -sL -o /dev/null -w %{url_effective} "$previous_url" | awk -F/ '{print $5}')
        gitcommit=$(curl -sL -o /dev/null -w %{url_effective} "$previous_url" | grep -oP '\d+\.\d+\.\d+-(\K\w+)')
    fi

    if [[ -z "$version" || -z "$gitcommit" ]]; then
        echo "> Failed to get version info from $previous_url. Skipping installation..."
        return 1
    fi

    echo "$version $gitcommit"
    return 0
}

# Function to check for updates
check_update() {
    local current_version=$1
    local current_gitcommit=$2
    local latest_version=$3
    local latest_gitcommit=$4

    if [[ "$latest_version" != "$current_version" || "$latest_gitcommit" != "$current_gitcommit" ]]; then
        echo "> There is a new version available: $latest_version-$latest_gitcommit"
        return 1
    fi
    return 0
}

# Function to extract files
extract_files() {
    local file=$1
    local destination=$2
    local is_update=$3
    local notchange=(
        "addons/sourcemod/configs/databases.cfg"
        "addons/sourcemod/configs/admins_simple.ini"
    )

    if [ "$is_update" = true ]; then
        # Create backup directory if it doesn't exist
        local backup_dir="$destination/addons/sourcemod/configs/backups"
        mkdir -p "$backup_dir"

        # Backup files in notchange array before update with timestamp
        local timestamp=$(date +%Y%m%d_%H%M%S)
        for file_to_backup in "${notchange[@]}"; do
            if [ -f "$destination/$file_to_backup" ]; then
                cp "$destination/$file_to_backup" "$backup_dir/$(basename $file_to_backup).$timestamp"
            fi
        done

        # Construir os argumentos de exclusão como uma array
        local exclude_args=("--wildcards")
        for file_pattern in "${notchange[@]}"; do
            exclude_args+=("--exclude=$file_pattern")
        done

        # Usar a array para passar os argumentos
        tar -xzvf "$file" -C "$destination" "${exclude_args[@]}" >/dev/null
    else
        tar -xzvf "$file" -C "$destination" >/dev/null
    fi

    if [ $? -eq 0 ]; then
        echo "> Completed extraction."
    else
        echo "> Error extracting the files."
        exit 1
    fi
}

# Function to install or update addon
install_or_update_addon() {
    local addon_name=$1
    local url=$2
    local cfg_file=$3

    echo "> Checking the installed version of $addon_name..."
    if ! read -r latest_version latest_gitcommit <<<$(get_latest_info "$url"); then
        echo "> Skipping installation of $addon_name due to version retrieval failure."
        return
    fi

    local is_update=false
    if [[ ! -d "$SERVER_DIR/addons/$addon_name" ]]; then
        echo "> $addon_name not found in the destination folder."
        echo "> Installing $addon_name..."
    elif [[ ! -f "$cfg_file" ]]; then
        if [[ "$addon_name" == "metamod" ]]; then
            echo "> Metamod folder exists but config is missing. Installing..."
        else
            echo "> Config file for $addon_name not found. Updating..."
        fi
    else
        source "$cfg_file"
        echo "> Installed version of $addon_name: $(eval echo \$installed_${addon_name}_version)-$(eval echo \$installed_${addon_name}_gitcommit)"
        if check_update "$(eval echo \$installed_${addon_name}_version)" "$(eval echo \$installed_${addon_name}_gitcommit)" "$latest_version" "$latest_gitcommit"; then
            echo "> $addon_name is up to date."
            return
        fi
        echo "> Updating $addon_name..."
        is_update=true
        is_update_orgn=true
    fi

    wget -4 -q "$url" -O "/tmp/${addon_name}-latest.tar.gz"
    extract_files "/tmp/${addon_name}-latest.tar.gz" "$SERVER_DIR" "$is_update"
    {
        echo "installed_${addon_name}_version=$latest_version"
        echo "installed_${addon_name}_gitcommit=$latest_gitcommit"
    } >"$cfg_file"
}

organize_sourcemod_plugins() {
    local sourcemod_plugins_dir="$SERVER_DIR/addons/sourcemod/plugins"
    local custom_folder="sourcemod_plugins"
    local disabled_folder="disabled"
    local plugins_state_file="$HOME/.ads/plugins_state.json"
    local is_update=${1:-false} # Parâmetro para indicar se é uma atualização

    # Lista de plugins padrão do SourceMod que sempre devem ir para sourcemod_plugins
    local sourcemod_plugins=(
        "admin-flatfile.smx"
        "adminhelp.smx"
        "adminmenu.smx"
        "antiflood.smx"
        "basebans.smx"
        "basechat.smx"
        "basecomm.smx"
        "basecommands.smx"
        "basetriggers.smx"
        "basevotes.smx"
        "clientprefs.smx"
        "funcommands.smx"
        "funvotes.smx"
        "nextmap.smx"
        "playercommands.smx"
        "reservedslots.smx"
        "sounds.smx"
    )

    # Criar diretórios necessários
    mkdir -p "$sourcemod_plugins_dir/$custom_folder"
    mkdir -p "$sourcemod_plugins_dir/$disabled_folder"

    # Array associativo para armazenar estados dos plugins
    declare -A plugin_states

    # Ativar opção 'nounset' somente após a declaração do array
    set +u # Temporariamente desativar erro em variáveis não definidas

    # Primeiro, verificar se existe o arquivo de estado
    if [ -f "$plugins_state_file" ]; then
        echo "> Loading previous plugin states"
        # Carregar estados anteriores dos plugins
        while IFS= read -r line; do
            # Extrair nome do plugin e estado
            if [[ "$line" =~ \"([^\"]+\.smx)\"\:\ \"([^\"]+)\" ]]; then
                plugin_name="${BASH_REMATCH[1]}"
                state="${BASH_REMATCH[2]}"
                plugin_states["$plugin_name"]="$state"
            fi
        done <"$plugins_state_file"
    fi

    # Verificar a localização física dos plugins para atualizar os estados
    # Isso garante que plugins movidos manualmente tenham seus estados atualizados
    echo "> Checking plugin locations to update states"

    # Listar todos os plugins encontrados (para detectar novos plugins)
    echo "> Scanning for plugins"

    # Hash maps para rastrear caminhos dos plugins
    declare -A plugin_paths
    declare -A plugin_timestamps

    # Verificar plugins na raiz
    for plugin in "$sourcemod_plugins_dir"/*.smx; do
        if [ -f "$plugin" ]; then
            plugin_name=$(basename "$plugin")

            # Se é um plugin padrão do SourceMod, sempre vai para custom_folder como ativo
            if [[ " ${sourcemod_plugins[@]} " =~ " ${plugin_name} " ]]; then
                plugin_paths["$plugin_name"]="$plugin"
                plugin_timestamps["$plugin_name"]=$(stat -c %Y "$plugin")
                plugin_states["$plugin_name"]="active"
                echo "> Default plugin found: $plugin_name (will be active)"
            else
                # Apenas rastrear o caminho do plugin sem alterar o estado
                plugin_paths["$plugin_name"]="$plugin"
                plugin_timestamps["$plugin_name"]=$(stat -c %Y "$plugin")
                # Se não estiver na lista de plugins padrão,
                # o estado permanece como estava antes ou não definido
                echo "> Non-default plugin found in root: $plugin_name (state unchanged)"
            fi
        fi
    done

    # Verificar plugins em custom_folder
    for plugin in "$sourcemod_plugins_dir/$custom_folder"/*.smx; do
        if [ -f "$plugin" ]; then
            plugin_name=$(basename "$plugin")

            # Verificar se já encontramos esse plugin em outro lugar
            if [[ -n "${plugin_paths[$plugin_name]:-}" ]]; then
                # Se estamos em modo de atualização, verificar qual é mais recente
                if [ "$is_update" = true ]; then
                    current_timestamp=$(stat -c %Y "$plugin")

                    if ((current_timestamp > plugin_timestamps["$plugin_name"])); then
                        echo "> Found newer version of $plugin_name in $custom_folder"
                        plugin_paths["$plugin_name"]="$plugin"
                        plugin_timestamps["$plugin_name"]=$current_timestamp
                    else
                        echo "> Keeping newer version of $plugin_name from root directory"
                    fi
                fi
            else
                # Primeira vez que encontramos este plugin
                plugin_paths["$plugin_name"]="$plugin"
                plugin_timestamps["$plugin_name"]=$(stat -c %Y "$plugin")
            fi

            # Atualizar estado para ativo
            plugin_states["$plugin_name"]="active"
            echo "> Plugin found in $custom_folder: $plugin_name (set as active)"
        fi
    done

    # Verificar plugins em disabled_folder
    for plugin in "$sourcemod_plugins_dir/$disabled_folder"/*.smx; do
        if [ -f "$plugin" ]; then
            plugin_name=$(basename "$plugin")

            # Verificar se já encontramos esse plugin em outro lugar
            if [[ -n "${plugin_paths[$plugin_name]:-}" ]]; then
                # Se estamos em modo de atualização, verificar qual é mais recente
                if [ "$is_update" = true ]; then
                    current_timestamp=$(stat -c %Y "$plugin")

                    if ((current_timestamp > plugin_timestamps["$plugin_name"])); then
                        echo "> Found newer version of $plugin_name in $disabled_folder"
                        plugin_paths["$plugin_name"]="$plugin"
                        plugin_timestamps["$plugin_name"]=$current_timestamp
                        # Se o mais recente está em disabled, atualizar o estado
                        plugin_states["$plugin_name"]="disabled"
                    else
                        # Manter o estado original já que estamos mantendo a versão mais recente
                        echo "> Keeping newer version of $plugin_name with original state"
                    fi
                fi
            else
                # Primeira vez que encontramos este plugin
                plugin_paths["$plugin_name"]="$plugin"
                plugin_timestamps["$plugin_name"]=$(stat -c %Y "$plugin")
                # Atualizar estado para desativado
                plugin_states["$plugin_name"]="disabled"
                echo "> Plugin found in $disabled_folder: $plugin_name (set as disabled)"
            fi
        fi
    done

    # Se estamos em modo de atualização, remover plugins duplicados
    # (manter apenas a versão mais recente de cada plugin)
    if [ "$is_update" = true ]; then
        echo "> Update mode: removing duplicate plugins, keeping newest versions"

        # Lista de arquivos a remover (duplicados mais antigos)
        declare -a files_to_remove

        # Verificar duplicados na raiz
        for plugin in "$sourcemod_plugins_dir"/*.smx; do
            if [ -f "$plugin" ]; then
                plugin_name=$(basename "$plugin")
                if [[ "$plugin" != "${plugin_paths[$plugin_name]}" ]]; then
                    files_to_remove+=("$plugin")
                    echo "> Will remove duplicate: $plugin (keeping ${plugin_paths[$plugin_name]})"
                fi
            fi
        done

        # Verificar duplicados em custom_folder
        for plugin in "$sourcemod_plugins_dir/$custom_folder"/*.smx; do
            if [ -f "$plugin" ]; then
                plugin_name=$(basename "$plugin")
                if [[ "$plugin" != "${plugin_paths[$plugin_name]}" ]]; then
                    files_to_remove+=("$plugin")
                    echo "> Will remove duplicate: $plugin (keeping ${plugin_paths[$plugin_name]})"
                fi
            fi
        done

        # Verificar duplicados em disabled_folder
        for plugin in "$sourcemod_plugins_dir/$disabled_folder"/*.smx; do
            if [ -f "$plugin" ]; then
                plugin_name=$(basename "$plugin")
                if [[ "$plugin" != "${plugin_paths[$plugin_name]}" ]]; then
                    files_to_remove+=("$plugin")
                    echo "> Will remove duplicate: $plugin (keeping ${plugin_paths[$plugin_name]})"
                fi
            fi
        done

        # Remover duplicados
        for file in "${files_to_remove[@]}"; do
            rm "$file"
            echo "> Removed duplicate: $file"
        done
    fi

    # Agora organize todos os plugins com base nos estados atualizados
    echo "> Organizing plugins"

    for plugin_name in "${!plugin_states[@]}"; do
        state="${plugin_states[$plugin_name]}"

        # Localizar o plugin atual (após remoção de duplicados)
        local current_plugin_path="${plugin_paths[$plugin_name]:-}"

        # Se encontramos o plugin, movê-lo para o lugar correto de acordo com o estado
        if [ -n "$current_plugin_path" ] && [ -f "$current_plugin_path" ]; then
            if [ "$state" = "active" ]; then
                # Plugins ativos vão para custom_folder
                if [[ "$current_plugin_path" != "$sourcemod_plugins_dir/$custom_folder/$plugin_name" ]]; then
                    mv "$current_plugin_path" "$sourcemod_plugins_dir/$custom_folder/"
                    echo "> Moved to active: $plugin_name"
                fi
            elif [ "$state" = "disabled" ]; then
                # Plugins desativados vão para disabled_folder
                if [[ "$current_plugin_path" != "$sourcemod_plugins_dir/$disabled_folder/$plugin_name" ]]; then
                    mv "$current_plugin_path" "$sourcemod_plugins_dir/$disabled_folder/"
                    echo "> Moved to disabled: $plugin_name"
                fi
            fi
        else
            echo "> Warning: Plugin $plugin_name listed in state file but not found"
            # Remover do array de estados se o plugin não existe mais
            unset plugin_states["$plugin_name"]
        fi
    done

    # Salvar estado atual dos plugins apenas se não for uma atualização
    # Isso previne que estados sejam sobrescritos durante atualizações
    if [ "$is_update" != true ]; then
        echo "> Saving plugin states"
        echo "{" >"$plugins_state_file"
        echo "  \"plugins\": {" >>"$plugins_state_file"

        # Escrever estados no arquivo JSON
        local first=true
        for plugin_name in "${!plugin_states[@]}"; do
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >>"$plugins_state_file"
            fi
            echo "    \"$plugin_name\": \"${plugin_states[$plugin_name]}\"" >>"$plugins_state_file"
        done

        echo "  }" >>"$plugins_state_file"
        echo "}" >>"$plugins_state_file"
        echo "> Plugin states saved to: $plugins_state_file"
    else
        echo "> Update mode: plugin states not saved to preserve user configuration"
    fi

    # Reativar opção 'nounset' se necessário
    set -u

    echo "> SourceMod plugins organized successfully"
}

# Main execution
install_or_update_addon "sourcemod" "$sourcemod_url" "$SOURCEMOD_CFG"
if [ "$is_update_orgn" = true ]; then
    organize_sourcemod_plugins true
else
    organize_sourcemod_plugins
fi
install_or_update_addon "metamod" "$metamod_url" "$METAMOD_CFG"

touch $ADDONS_INSTALLED_LOCK_FILE

echo "> Addons installation and update process completed successfully."
