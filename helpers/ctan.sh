#!/bin/bash

# This script is called by make from the project root.

EXCLUDE=$(cat ./helpers/ctan_exclude.txt | sed 's/\n/ /g')

cat ./helpers/ctan_include.txt | zip -r -q -X -ll -@ wallcalendar.zip -x $EXCLUDE
