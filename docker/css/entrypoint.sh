#!/bin/bash
cd css && ./srcds_run -debug -game cstrike +exec server.cfg +port "$SERVER_PORT" +tvport "$SOURCETV_PORT" +hostname "$CSS_HOSTNAME" +sv_password "$CSS_PASSWORD" +rcon_password "$RCON_PASSWORD" +map de_dust2
