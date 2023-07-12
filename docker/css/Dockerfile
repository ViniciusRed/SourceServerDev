FROM archlinux

ENV USER root
ENV HOME /root/ServerCSS
WORKDIR $HOME

COPY packages/*.pkg.tar.zst $HOME/packages/

ADD ./entrypoint.sh entrypoint.sh

ENV CSS_HOSTNAME Counter-Strike Source Dedicated Server
ENV CSS_PASSWORD ""
ENV SERVER_PORT 27015
ENV SOURCETV_PORT 27020

ENV RCON_PASSWORD mysup3rs3cr3tpassw0rd
ENV NO_STEAM true

EXPOSE $SERVER_PORT
EXPOSE $SOURCETV_PORT

RUN pacman -Sy git wget --noconfirm

RUN pacman -U packages/*.pkg.tar.zst --noconfirm

# steamcmd
RUN steamcmd +force_install_dir $HOME/css +login anonymous +app_update 232330 validate +quit

RUN mv $HOME/css/bin/steamclient.so $HOME/css/bin/steamclient_valve.so
COPY preinstall/nonsteam/ $HOME/css/
COPY preinstall/cstrike/ $HOME/css/cstrike
COPY preinstall/maps/ $HOME/css/cstrike/maps
#copy maps
ADD cfg/ $HOME/css/cstrike/cfg

VOLUME [ "/root/ServerCSS/" ]

RUN chmod +x ./entrypoint.sh

CMD ./entrypoint.sh