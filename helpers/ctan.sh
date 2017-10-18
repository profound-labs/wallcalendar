#!/bin/bash

# This script is called by make from the project root.

cd ..

cat ./wallcalendar/helpers/ctan_include.txt |\
    zip -r -q -X -ll -@ wallcalendar/wallcalendar.zip -x@wallcalendar/helpers/ctan_exclude.txt

cd wallcalendar
