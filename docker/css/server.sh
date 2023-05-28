#!/bin/bash

source config.cfg

set -e

shopt -s extglob

SERVER_DIR="${HOME}/css"
SERVER_INSTALLED_LOCK_FILE="${SERVER_DIR}/installed.lock"

install_or_update() {
    if [ -f "$SERVER_INSTALLED_LOCK_FILE" ]; then
        update
    else
        install
    fi
}

update()
{
    echo ""
}

install() 
{
    echo '> Installing Server'

    steamcmd \
    +force_install_dir $SERVER_DIR \
    +login anonymous \
    +app_update 232330 validate \
    +quit


    mv $SERVER_DIR/bin/steamclient.so $SERVER_DIR/bin/steamclient_valve.so

    cp -ar $HOME/nonsteam/* $SERVER_DIR

    touch $SERVER_INSTALLED_LOCK_FILE
}

crackserver() {
    start
}

start()
{
    echo '> Starting Server ...'

    additionalParams=""

    if [ "${DEBUG}" = "true" ]; then
       additionalParams+=" -debug"
    fi

    if [ "${ENABLE_INSECURE}" = "true" ]; then
        additionalParams+=" -insecure"
    fi

    if [ "${SERVER_LAN}" = "1" ]; then
        additionalParams+=" +sv_lan ${SERVER_LAN}"
    fi

    if [ -n "${SERVER_PASSWORD}" ]; then
        additionalParams+=" +sv_password ${SERVER_PASSWORD}"
    fi

    if [ -n "${SERVER_HOSTNAME}" ]; then
        additionalParams+=" +hostname \"$SERVER_HOSTNAME\""
    fi

    if [ -n "${SERVER_PORT}" ]; then
        additionalParams+=" +port ${SERVER_PORT}"
    fi

    if [ -n "${SOURCETV_PORT}" ]; then
        additionalParams+=" +tv_port ${SOURCETV_PORT}"
    fi

    if [ -n "${RCON_PASSWORD}" ]; then
        additionalParams+=" +rcon_password ${RCON_PASSWORD}"
    fi

    if [ -n "${SERVER_MAP}" ]; then
        additionalParams+=" +map ${SERVER_MAP}"
    fi

    if [ -n "${MAX_PLAYERS}" ]; then
        additionalParams+=" +maxplayers ${MAX_PLAYERS}"
    fi

    set -x

    $SERVER_DIR/srcds_run \
    -game cstrike \
    -console \
    $additionalParams

}


if [ ! -z $1 ]; then
    $1
else
    if [ "${SERVER_NONSTEAM}" = "true" ]; then
        crackserver
    else
        install_or_update
        start
    fi
fi