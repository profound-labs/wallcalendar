#!/bin/bash

# TODO get the list of calendar name from listing the .pdf in doc/examples/

for i in marks plain showframe showtrims thumbnails translations-english translations-hungarian translations-japanese varnishmask year-planner; do
    name="cal-$i"
    git checkout "$name".pdf
    pdftk "$name".pdf burst output ./diff-old/"$name"-%02d.pdf
    make "$name" > out.log 2>&1
    if [[ $? -ne 0 ]]; then
        echo "ERROR: compiling '$name.pdf' failed. See out.log"
        exit 2
    fi
    pdftk "$name".pdf burst output ./diff-new/"$name"-%02d.pdf
done

for i in ./diff-old/*.pdf; do
    name=`basename $i`

    echo -n "Compare $name, AE: ... "

    compare \
        -metric AE \
        ./diff-old/"$name" \
        ./diff-new/"$name" \
        -compose src \
        -alpha off \
        ./diff-compare/`basename -s .pdf $i`.jpg

    if [[ $? -eq 1 ]]; then
        echo -e "\nDIFFER: $name\n"
    else
        echo -e "\n"
    fi
done

for i in plain showframe showtrims varnishmask; do
    name="cal-$i"
    git checkout "$name".pdf
done
