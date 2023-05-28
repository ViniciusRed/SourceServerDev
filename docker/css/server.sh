#!/bin/bash

source config.cfg

set -e

shopt -s extglob

SERVER_DIR="${HOME}/css"
NONSTEAM_DIR="${HOME}/nonsteam/"
SERVER_INSTALLED_LOCK_FILE="${SERVER_DIR}/installed.lock"
SERVER_NONSTEAM_LOCK_FILE="${SERVER_DIR}/nonsteam.lock"

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

    set -x

    steamcmd \
    +force_install_dir $SERVER_DIR \
    +login anonymous \
    +app_update 232330 validate \
    +quit

    set +x

    touch $SERVER_INSTALLED_LOCK_FILE
}

start()
{
    echo '> Starting Server ...'

    set -x

    additionalParams=""

    if [ $DEBUG ]; then
        additionalParams+=" -debug"
    fi

    if [ $ENABLE_INSECURE = true ]; then
        additionalParams+=" -insecure"
    fi

    if [ "${SERVER_LAN}" = "1" ]; then
        additionalParams+=" +sv_lan $SERVER_LAN"
    fi

    if [ ! -z "${SERVER_HOSTNAME}" ]; then
        additionalParams+=" +hostname \"$SERVER_HOSTNAME\""
        additionalParams+=
    fi

    if [ ! -z "${SERVER_MAP}" ]; then
        additionalParams+=" +map $SERVER_MAP"
    fi

    if [ ! -z "${SOURCETV_PORT}" ]; then
        additionalParams+=" +tv_port $SOURCETV_PORT"
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
        if [ $SERVER_NONSTEAM ]; then
            sleep 2
            echo '> Cracking Server';
            mv $SERVER_DIR/bin/steamclient.so $SERVER_DIR/bin/steamclient_valve.so
            cp -ar $HOME/nonsteam/* $SERVER_DIR
            echo '> Done';
            rm -r $NONSTEAM_DIR
            touch $SERVER_NONSTEAM_LOCK_FILE
            sleep 2
        fi
    fi
}

if [ ! -z $1 ]; then
    $1
else
    install_or_update
    crackserver_if_needs
    start
fi