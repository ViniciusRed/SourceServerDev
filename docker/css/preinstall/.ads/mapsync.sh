#!/bin/bash

SERVER_DIR="${HOME}/css/cstrike"
MAPSYNC_DIR="${SERVER_DIR}/download/maps"
MAPSYNC_MAPCYCLE="${SERVER_DIR}/cfg/mapcycle.txt"
MAPSYNC_MAPCYCLE_BACKUP="${SERVER_DIR}/cfg/mapcycle.txt.bak"
MAPSYNC_MAPCYCLE_DEFAULT="${HOME}/default_mapcycle.txt"
SERVER_CFG="${SERVER_DIR}/cfg/server.cfg"
LOG_FILE="${HOME}/.ads/mapsync.log"
MAPS_CONTROL="${HOME}/.ads/maps_control.json"
LOG_LEVEL="${MAPSYNC_LOG_LEVEL:-info}" # Níveis: debug, info, warn, error

# Função para logging com níveis
log_message() {
    local level="$1"
    local message="$2"

    # Só registrar mensagens do nível apropriado
    case "${LOG_LEVEL}" in
    debug)
        # Registra todos os níveis
        ;;
    info)
        # Não registra debug
        if [ "$level" = "debug" ]; then return; fi
        ;;
    warn)
        # Não registra debug nem info
        if [ "$level" = "debug" ] || [ "$level" = "info" ]; then return; fi
        ;;
    error)
        # Só registra erros
        if [ "$level" != "error" ]; then return; fi
        ;;
    *)
        # Default para info
        if [ "$level" = "debug" ]; then return; fi
        ;;
    esac

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] $message" >>"${LOG_FILE}"
}

create_mapsync_structure() {
    if [ ! -d "${MAPSYNC_DIR}" ]; then
        mkdir -p "${MAPSYNC_DIR}"
        log_message "info" "Created maps directory: ${MAPSYNC_DIR}"
    fi

    if [ ! -f "${MAPSYNC_MAPCYCLE_DEFAULT}" ]; then
        echo "de_dust2
de_inferno
de_nuke" >"${MAPSYNC_MAPCYCLE_DEFAULT}"
        log_message "info" "Created default mapcycle"
    fi

    if [ ! -f "${MAPSYNC_MAPCYCLE}" ]; then
        if [ -f "${MAPSYNC_MAPCYCLE_BACKUP}" ]; then
            cp "${MAPSYNC_MAPCYCLE_BACKUP}" "${MAPSYNC_MAPCYCLE}"
            log_message "info" "Restored mapcycle from backup"
        else
            update_mapcycle
            log_message "info" "Created new mapcycle"
        fi
    fi
}

# Função para inicializar/atualizar o arquivo de controle
update_maps_control() {
    local map_name="$1"
    local last_modified="$2"
    local map_size="$3"

    # Criar arquivo se não existir
    if [ ! -f "${MAPS_CONTROL}" ]; then
        echo '{"maps":{}}' >"${MAPS_CONTROL}"
    fi

    # Verificar se houve mudança antes de atualizar
    local current_data=$(jq --arg map "$map_name" '.maps[$map] // empty' "${MAPS_CONTROL}")
    if [ -n "$current_data" ]; then
        local current_modified=$(echo "$current_data" | jq -r '.last_modified')
        local current_size=$(echo "$current_data" | jq -r '.size')

        if [ "$current_modified" = "$last_modified" ] && [ "$current_size" = "$map_size" ]; then
            return 0 # Sem mudanças, retorna sem logar
        fi
    fi

    # Atualizar informações do mapa somente se houver mudança
    local tmp_file=$(mktemp)
    jq --arg map "$map_name" \
        --arg time "$last_modified" \
        --arg size "$map_size" \
        '.maps[$map] = {"last_modified": $time, "size": $size}' \
        "${MAPS_CONTROL}" >"$tmp_file" && mv "$tmp_file" "${MAPS_CONTROL}"

    log_message "info" "Map ${map_name} updated (modified: ${last_modified})"
}

# Função para remover mapas ausentes da API
clean_missing_maps() {
    local api_maps="$1"
    local removed=0

    # Verificar se o arquivo de controle existe
    if [ ! -f "${MAPS_CONTROL}" ]; then
        return 0
    fi

    # Obter lista de mapas do arquivo de controle
    local control_maps=$(jq -r '.maps | keys[]' "${MAPS_CONTROL}")

    while read -r map_name; do
        # Verificar se o mapa está na lista da API
        if echo "${api_maps}" | jq -e --arg map "${map_name}" '.maps[] | select(.name == $map)' >/dev/null; then
            continue
        else
            # Mapa não está na API, vamos removê-lo
            log_message "info" "Map ${map_name} not found in API, removing..."

            # Remover arquivo do mapa
            if [ -f "${MAPSYNC_DIR}/${map_name}.bsp" ]; then
                rm "${MAPSYNC_DIR}/${map_name}.bsp"
            fi

            # Remover do mapcycle
            if [ -f "${MAPSYNC_MAPCYCLE}" ]; then
                sed -i "/^${map_name}$/d" "${MAPSYNC_MAPCYCLE}"
            fi

            # Remover do arquivo de controle
            local tmp_file=$(mktemp)
            jq --arg map "$map_name" 'del(.maps[$map])' "${MAPS_CONTROL}" >"$tmp_file" && mv "$tmp_file" "${MAPS_CONTROL}"

            removed=1
        fi
    done <<<"${control_maps}"

    return $removed
}

update_mapcycle() {
    # Fazer backup do mapcycle atual antes de limpar
    [ -f "${MAPSYNC_MAPCYCLE}" ] && cp "${MAPSYNC_MAPCYCLE}" "${MAPSYNC_MAPCYCLE_BACKUP}"

    # Limpar mapcycle atual
    >"${MAPSYNC_MAPCYCLE}"

    # Primeiro adicionar mapas default
    if [ -f "${MAPSYNC_MAPCYCLE_DEFAULT}" ]; then
        while read -r map; do
            if [ ! -z "$map" ]; then
                echo "${map}" >>"${MAPSYNC_MAPCYCLE}"
            fi
        done <"${MAPSYNC_MAPCYCLE_DEFAULT}"
    fi

    # Adicionar mapas existentes
    shopt -s nullglob # Previne erro quando não há arquivos .bsp
    for map_file in "${MAPSYNC_DIR}"/*.bsp; do
        if [ -f "$map_file" ]; then
            map_name=$(basename "$map_file" .bsp)
            # Evitar duplicatas
            if ! grep -q "^${map_name}$" "${MAPSYNC_MAPCYCLE}"; then
                echo "${map_name}" >>"${MAPSYNC_MAPCYCLE}"
            fi
        fi
    done
    shopt -u nullglob # Restaura configuração original
}

check_mapcycle() {
    local needs_update=0

    # Verificar se os mapas default estão presentes
    if [ -f "${MAPSYNC_MAPCYCLE_DEFAULT}" ]; then
        while read -r map; do
            if [ ! -z "$map" ] && ! grep -q "^${map}$" "${MAPSYNC_MAPCYCLE}"; then
                needs_update=1
                break
            fi
        done <"${MAPSYNC_MAPCYCLE_DEFAULT}"
    fi

    # Se já precisa atualizar, não verificar mais mapas
    if [ $needs_update -eq 1 ]; then
        return 1
    fi

    # Verificar se todos os mapas .bsp estão no mapcycle
    shopt -s nullglob
    for map_file in "${MAPSYNC_DIR}"/*.bsp; do
        if [ -f "$map_file" ]; then
            map_name=$(basename "$map_file" .bsp)
            if ! grep -q "^${map_name}$" "${MAPSYNC_MAPCYCLE}"; then
                needs_update=1
                break
            fi
        fi
    done
    shopt -u nullglob

    return $needs_update
}

# Source configuration
source config.cfg

# Criar estrutura básica
create_mapsync_structure

# Função para obter a URL de download do server.cfg
get_download_url() {
    if [ -f "${SERVER_CFG}" ]; then
        DOWNLOAD_URL=$(grep "^sv_downloadurl" "${SERVER_CFG}" | cut -d '"' -f2)
        if [ -z "${DOWNLOAD_URL}" ]; then
            echo "http://localhost:27020" # URL padrão se não encontrar
        else
            echo "${DOWNLOAD_URL}"
        fi
    else
        echo "http://localhost:27020" # URL padrão se não existir server.cfg
    fi
}

sync_maps() {
    local last_sync=0
    local current_time=0
    local changes_detected=0
    local iteration_count=0

    BASE_URL=$(get_download_url)
    mkdir -p "${MAPSYNC_DIR}"

    # Verificar se o mapcycle precisa ser atualizado
    check_mapcycle
    if [ $? -eq 1 ]; then
        log_message "info" "Mapcycle needs update, regenerating..."
        update_mapcycle
    fi

    # Log para indicar o modo de execução
    if [ "${MAPSYNC_AUTOMATIC:-false}" = "false" ]; then
        log_message "info" "Running in single execution mode"
    else
        log_message "info" "Running in continuous mode with interval: ${MAPSYNC_INTERVAL:-60} seconds"
    fi

    while true; do
        iteration_count=$((iteration_count + 1))
        log_message "debug" "Starting iteration #${iteration_count}"

        current_time=$(date +%s)

        # Verificar se passou tempo suficiente desde última sincronização
        if [ $((current_time - last_sync)) -lt "${MAPSYNC_INTERVAL:-60}" ]; then
            sleep 5
            continue
        fi

        log_message "debug" "Checking for map updates..."

        # Obter lista de mapas da API
        MAPS_JSON=$(curl -s -H "X-API-Key: ${MAPSYNC_APIKEY}" \
            -H "Content-Type: application/json" \
            --connect-timeout "${MAPSYNC_TIMEOUT:-30}" \
            "${BASE_URL}/api-listmaps")

        if [ $? -ne 0 ]; then
            log_message "error" "Failed to connect to API"

            # Se não for automático, continuar mesmo com erro
            if [ "${MAPSYNC_AUTOMATIC:-false}" = "false" ]; then
                log_message "error" "API connection failure in single execution mode, continuing server startup"
                return 0
            fi

            sleep "${MAPSYNC_INTERVAL:-60}"
            continue
        fi

        if ! echo "${MAPS_JSON}" | jq -e . >/dev/null 2>&1; then
            log_message "error" "Invalid JSON response from API"

            # Se não for automático, continuar mesmo com erro
            if [ "${MAPSYNC_AUTOMATIC:-false}" = "false" ]; then
                log_message "error" "Invalid JSON in single execution mode, continuing server startup"
                return 0
            fi

            sleep "${MAPSYNC_INTERVAL:-60}"
            continue
        fi

        # Verificar se o JSON tem a estrutura esperada
        if ! echo "${MAPS_JSON}" | jq -e '.maps' >/dev/null 2>&1; then
            log_message "error" "JSON missing 'maps' array"

            # Se não for automático, continuar mesmo com erro
            if [ "${MAPSYNC_AUTOMATIC:-false}" = "false" ]; then
                log_message "error" "Malformed JSON in single execution mode, continuing server startup"
                return 0
            fi

            sleep "${MAPSYNC_INTERVAL:-60}"
            continue
        fi

        changes_detected=0

        # Usar processo mais eficiente para lidar com mapas
        maplist=$(echo "${MAPS_JSON}" | jq -r '.maps[] | "\(.name)|\(.size)|\(.last_modified)"')

        while IFS="|" read -r MAP_NAME MAP_SIZE MAP_MODIFIED; do
            # Pular linhas vazias
            [ -z "$MAP_NAME" ] && continue

            # Atualizar arquivo de controle sem logar cada alteração
            update_maps_control "${MAP_NAME}" "${MAP_MODIFIED}" "${MAP_SIZE}"

            if [ ! -f "${MAPSYNC_DIR}/${MAP_NAME}.bsp" ] ||
                [ "${MAPSYNC_FORCE:-false}" = "true" ] ||
                [ $(stat -c %s "${MAPSYNC_DIR}/${MAP_NAME}.bsp" 2>/dev/null || echo 0) -ne "${MAP_SIZE}" ]; then

                log_message "info" "Downloading map: ${MAP_NAME}"
                wget -q --header="X-API-Key: ${MAPSYNC_APIKEY}" \
                    -O "${MAPSYNC_DIR}/${MAP_NAME}.bsp" \
                    "${BASE_URL}/maps/${MAP_NAME}.bsp"

                if [ $? -eq 0 ]; then
                    log_message "info" "Map ${MAP_NAME} downloaded successfully"
                    if ! grep -q "^${MAP_NAME}$" "${MAPSYNC_MAPCYCLE}"; then
                        echo "${MAP_NAME}" >>"${MAPSYNC_MAPCYCLE}"
                    fi
                    changes_detected=1
                else
                    log_message "error" "Failed to download map: ${MAP_NAME}"
                fi
            fi
        done <<<"$maplist"

        # Limpar mapas ausentes da API
        clean_missing_maps "${MAPS_JSON}"
        if [ $? -eq 1 ]; then
            changes_detected=1
            log_message "info" "Removed maps no longer in API"
        fi

        # Verificar novamente se o mapcycle está atualizado após downloads
        if [ $changes_detected -eq 1 ]; then
            check_mapcycle
            if [ $? -eq 1 ]; then
                log_message "info" "Updating mapcycle after changes"
                update_mapcycle
            fi
        fi

        last_sync=${current_time}

        if [ ${changes_detected} -eq 0 ]; then
            log_message "debug" "No changes detected"
        fi

        # Verificar se deve continuar executando ou encerrar
        if [ "${MAPSYNC_AUTOMATIC:-false}" = "false" ]; then
            log_message "info" "Single execution completed, exiting..."
            break
        fi

        # Usar sleep mais eficiente para intervalos longos
        log_message "debug" "Sleeping for ${MAPSYNC_INTERVAL:-60} seconds before next check"
        sleep "${MAPSYNC_INTERVAL:-60}"
    done

    log_message "info" "Map synchronization completed"
    return 0
}

# Executar verificação inicial só quando necessário
check_mapcycle
if [ $? -eq 1 ]; then
    log_message "info" "Initial mapcycle needs update"
    update_mapcycle
fi

# Execução principal
if [ "${MAPSYNC_AUTOMATIC:-false}" = "true" ]; then
    log_message "info" "Starting automatic map sync service"
    (sync_maps &) # Executa em background
else
    log_message "info" "Running single map sync"
    sync_maps
fi
