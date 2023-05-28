FROM archlinux

ENV USER root
ENV HOME /root/ServerCSS

WORKDIR $HOME

COPY packages/*.pkg.tar.zst $HOME/packages/
RUN pacman -Sy git wget bottom gdb nmap --noconfirm
RUN pacman -U packages/*.pkg.tar.zst --noconfirm
RUN rm -r packages

EXPOSE 27015
EXPOSE 27020

ADD ./config.cfg config.cfg
ADD ./server.sh server.sh

COPY preinstall/nonsteam/ $HOME/nonsteam
COPY preinstall/cstrike/ $HOME/css/cstrike

COPY preinstall/maps/ $HOME/css/cstrike/maps
ADD cfg/ $HOME/css/cstrike/cfg

VOLUME [ "/root/ServerCSS/" ]

RUN chmod +x ./server.sh

CMD ./server.sh