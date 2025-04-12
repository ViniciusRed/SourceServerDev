#!/bin/bash

# Defina o caminho para o arquivo de controle
CONTROL_FILE="${HOME}/.ads/update.lock"

# Defina o intervalo de uma semana em segundos
WEEK_IN_SECONDS=$((7 * 24 * 60 * 60))

# Função system() copiada do arquivo server.sh
system() {
    echo "> Updating System"
    pacman -Syu --noconfirm >/dev/null
    echo "> System Updated"
    pacman -Scc --noconfirm >/dev/null
    echo "> System Cleaned"
    sleep 2
}

# Verifique se o arquivo de controle existe
if [ -f "$CONTROL_FILE" ]; then
    # Calcule a diferença de tempo desde a última modificação do arquivo
    TIME_DIFF=$(($(date +%s) - $(stat -c %Y "$CONTROL_FILE")))

    # Se a diferença de tempo for maior ou igual a uma semana
    if [ "$TIME_DIFF" -ge "$WEEK_IN_SECONDS" ]; then
        # Execute o código de atualização do sistema
        system
        # Atualize a data de modificação do arquivo de controle
        touch "$CONTROL_FILE"
    fi
else
    # Se o arquivo de controle não existir, crie-o e execute o código de atualização do sistema
    system
    touch "$CONTROL_FILE"
fi
