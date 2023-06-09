FROM archlinux

ENV USER root
ENV HOME /root/ServerCSS

WORKDIR $HOME

COPY packages/*.pkg.tar.zst $HOME/packages/
RUN pacman -Sy git wget bottom gdb nmap --noconfirm
RUN pacman -U packages/*.pkg.tar.zst --noconfirm
RUN rm -r packages

ADD ./config.cfg config.cfg
ADD ./server.sh server.sh

COPY preinstall/archives/ $HOME/archives
COPY preinstall/nonsteam/ $HOME/nonsteam
COPY preinstall/cstrike/ $HOME/css/cstrike
COPY preinstall/maps/ $HOME/css/cstrike/maps
COPY preinstall/cfg/ $HOME/cfg

VOLUME [ "/root/ServerCSS/" ]

RUN chmod +x ./server.sh

CMD ./server.sh
