#!/bin/bash
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    export PATH=$PATH:$HOME/go/bin
fi
ZOEKT_INDEX_DIR=$1
ZOEKT_CTAGS_ENABLED=1 zoekt-webserver -index "${ZOEKT_INDEX_DIR}" -listen :6070 & ssh -R 80:localhost:6070 serveo.net
