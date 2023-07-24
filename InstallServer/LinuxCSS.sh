#!/bin/bash

SERVER_DIR=./ServerCSS
DOWNLOAD_LOCK=download.lock
LinuxCSS=installed.lock

if [ -d $SERVER_DIR ]; then
  echo '> Folder exists'
  cd ServerCSS
else
  mkdir ServerCSS
  cd ServerCSS
fi

urls=(
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/addons.sh"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/fastdl.py"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/server.sh"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/config.cfg"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/preinstall/cfg/server.cfg"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/preinstall/nonsteam/rev.ini"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/preinstall/nonsteam/steam_appid.txt"
  "https://github.com/ViniciusRed/SourceServerDev/raw/main/docker/css/preinstall/nonsteam/bin/steamclient.so"
)

nosteamfs=(
  "rev.ini"
  "steam_appid.txt"
  "steamclient.so"
)

movefiles() {
  mkdir nosteam
  echo "> Copying the files"
  for nosteamf in "${nosteamfs[@]}"; do
    mv $nosteamf nosteam/
  done
  mv server.cfg css/cstrike/cfg
  echo "> All Copied Files"
}

download() {
  if [ ! -f $DOWNLOAD_LOCK ]; then
    for url in "${urls[@]}"; do
      echo "> Downloading: $url"
      wget "$url"
      echo "> Download completed: $url"
      echo "> All downloads have been completed!"
    done
    touch $DOWNLOAD_LOCK
  fi
}

# Check which distro and make the necessary package facilities

run() {
  ./server.sh install
}

# Make the server installation
install() {
  download
  sed -i 's#SERVER_DIR="[^"]*"#SERVER_DIR="$(pwd)/css"#' server.sh
  sed -i 's#NONSTEAM_DIR="${HOME}/nonsteam/"#NONSTEAM_DIR="$(pwd)/nonsteam/"#' server.sh
  sed -i 's#SERVER_DIR="[^"]*"#SERVER_DIR="$(pwd)/css/cstrike"#' addons.sh
  chmod +x ./server.sh && chmod +x ./addons.sh
  run && movefiles
  cd ..
  rm -r LinuxCSS.sh
}

install