#!/bin/bash

# This script is called by make from the project root.

if [ "$1" == "" ]; then
    echo "First argument must be the package's source zip file."
fi

PACKAGE_NAME=wallcalendar

SRC_ZIP="$1"

DIST_DIR=$(kpsewhich -var-value TEXMFHOME)"/tex/$PACKAGE_NAME"

if [ ! -z "$DIST_DIR" ]; then
   mkdir -p "$DIST_DIR"
fi

rm -r "$DIST_DIR"/*

unzip "$SRC_ZIP" -d "$DIST_DIR"

mktexlsr

