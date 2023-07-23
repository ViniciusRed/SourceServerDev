#!/bin/bash

SERVER_DIR=./ServerCSS
DOWNLOAD_LOCK=${SERVER_DIR}/download.lock

if [ -d $SERVER_DIR ]; then
  echo '> Folder exists'
else
  mkdir ServerCSS
fi

urls=(
  ""
  ""
  ""
  ""
  ""
  ""
)

if [ ! -f $DOWNLOAD_LOCK ]; then
  for url in "${urls[@]}"; do
    echo "Downloading: $url"
    wget "$url"
    echo "Download completed: $url"
    echo "All downloads have been completed!"
  done
fi
touch $DOWNLOAD_LOCK

# Check which distro and make the necessary package facilities

# Make the server installation
chmod +x $SERVER_DIR/server.sh && chmod +x $SERVER_DIR/addons.sh
cd $SERVER_DIR && ./server.sh
