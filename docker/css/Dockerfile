FROM archlinux

# Definição de argumentos (raramente mudam)
ARG USER=SourceServerDev
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG PKG="base-devel git wget tar unzip gdb lib32-zlib lib32-curl curl gcc gcc-libs lib32-glibc lib32-gcc-libs lib32-ncurses sdl2 lib32-sdl2 lib32-gnutls sudo diffutils inotify-tools jq"

# Configuração inicial do sistema (raramente muda)
COPY pacman.conf /etc/
RUN rm -f /etc/pacman.d/mirrorlist && \
    echo 'Server = http://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist && \
    pacman -Syy \
    && pacman-key --init \
    && pacman -Syu $PKG --noconfirm \
    && groupadd --gid $USER_GID $USER \
    && useradd --uid $USER_UID --gid $USER_GID -m $USER \
    && echo $USER ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

ENV HOME=/home/SourceServerDev \
    RCON_PASSWORD=${RCON_PASSWORD:-yourkey} \
    PRESET=${PRESET:-none} \
    PRESET_REPO=${PRESET_REPO:-none} \
    PRESET_BRANCH=${PRESET_BRANCH:-main} \
    PRESET_NOGIT=${PRESET_NOGIT:-none} \
    PRESET_PRIVATE=${PRESET_PRIVATE:-false} \
    PRESET_REPO_TOKEN=${PRESET_REPO_TOKEN:-none} \
    SOURCEMOD_VERSION=${SOURCEMOD_VERSION:-1.12} \
    METAMOD_VERSION=${METAMOD_VERSION:-1.12} \
    SERVER_TOKEN="${SERVER_TOKEN}" \
    SERVER_HOSTNAME="${SERVER_HOSTNAME:-SourceServerDev}" \
    SERVER_PASSWORD="${SERVER_PASSWORD}" \
    SERVER_PORT=${SERVER_PORT:-27015} \
    TICKRATE=${TICKRATE:-66} \
    FASTSTART=${FASTSTART:-false} \
    DISABLEADDONSUPDATE=${DISABLEADDONSUPDATE:-false} \
    DISABLE_HLTV=${DISABLE_HLTV:-false} \
    SERVER_MAP=${SERVER_MAP:-de_dust2} \
    SERVER_LAN=${SERVER_LAN:-0} \
    SERVER_NONSTEAM=${SERVER_NONSTEAM:-false} \
    MAX_PLAYERS=${MAX_PLAYERS:-10} \
    ENABLE_INSECURE=${ENABLE_INSECURE:-false} \
    DEBUG=${DEBUG:-false} \
    USE_GDB_DEBUG=${USE_GDB_DEBUG:-false} \
    DEBUG_SHELL=${DEBUG_SHELL:-false} \
    NOTRAP=${NOTRAP:-false} \
    IGNORESIGINT=${IGNORESIGINT:-false} \
    NORESTART=${NORESTART:-false} \
    ADDONS_VER=${ADDONS_VER:-false} \
    NOWATCHDOG=${NOWATCHDOG:-false} \
    MAPSYNC_AUTOMATIC=${MAPSYNC_AUTOMATIC:-false} \
    MAPSYNC_APIKEY=${MAPSYNC_APIKEY:-none} \
    MAPSYNC_TIMEOUT=${MAPSYNC_TIMEOUT:-10} \
    MAPSYNC_INTERVAL=${MAPSYNC_INTERVAL:-60} \
    MAPSYNC_FORCE=${MAPSYNC_FORCE:-false}

# Configuração do diretório de trabalho
WORKDIR $HOME

# Copia e instala pacotes específicos (raramente mudam)
COPY packages/*pkg.tar.zst $HOME/
RUN pacman -U *.pkg.tar.zst --noconfirm \
    && pacman -Scc --noconfirm \
    && rm -r *.pkg.tar.zst \
    && chown SourceServerDev /tmp \
    && mkdir -p ${HOME}/debug \
    && ln -s /tmp ${HOME}/debug

# Copia arquivos de pré-instalação que raramente mudam
COPY preinstall/.ads/ $HOME/.ads
COPY preinstall/.steam/ $HOME/.steam
RUN chmod +x .ads/*.sh

# Copia arquivos de configuração que podem mudar com mais frequência
COPY preinstall/cfg/*.cfg $HOME/css/cstrike/cfg/

# Copia script principal (provavelmente muda com mais frequência)
COPY ./server.sh server.sh
RUN chmod +x server.sh

# Configuração de porta e volume
EXPOSE 3306
EXPOSE ${SERVER_PORT}/udp
EXPOSE ${SERVER_PORT}/tcp

VOLUME [ "$HOME" ]

ENTRYPOINT ["./server.sh"]
SHELL [ "./server.sh" ]