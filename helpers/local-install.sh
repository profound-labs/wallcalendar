#!/bin/bash

# This script is called by make from the project root.

if [ "$1" == "" ]; then
    echo "First argument must be the package's source zip file."
fi

PACKAGE_NAME=wallcalendar

SRC_ZIP="$1"

DIST_DIR=$(kpsewhich -var-value TEXMFHOME)"/tex"

if [ ! -e "$DIST_DIR" ]; then
   mkdir -p "$DIST_DIR"
fi

if [ ! -e "$DIST_DIR/$PACKAGE_NAME" ]; then
    rm -r "$DIST_DIR/$PACKAGE_NAME"
fi

# The .zip file should contain a top-level directory.

unzip "$SRC_ZIP" -d "$DIST_DIR"

mktexlsr

