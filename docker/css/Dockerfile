FROM archlinux

ENV USER root
ENV HOME /root/ServerCSS
WORKDIR $HOME

COPY pacman.conf /etc/
COPY packages/*pkg.tar.zst $HOME

RUN pacman -Syu git wget tar unzip gdb lib32-zlib lib32-curl curl --noconfirm && pacman -U *.pkg.tar.zst --noconfirm && pacman -Scc --noconfirm && rm -r *.pkg.tar.zst 

ADD ./server.sh server.sh
ADD ./addons.sh addons.sh
ADD ./config.cfg config.cfg
ADD ./fastdl.py fastdl.py

RUN chmod +x ./server.sh && chmod +x ./addons.sh

COPY preinstall/nonsteam/ $HOME/nonsteam

ADD preinstall/cfg/*.cfg $HOME/css/cstrike/cfg/

VOLUME [ "/root/ServerCSS/" ]

ENTRYPOINT [ "./server.sh" ]
SHELL [ "./server.sh" ] 