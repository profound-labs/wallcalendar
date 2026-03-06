#!/bin/bash

for i in *.pdf ./cal-burst/*.pdf; do
    dir=$(dirname "$i")
    name=$(basename "$i" .pdf)
    pages=$(pdfinfo "$i" | grep 'Pages:' | sed 's/Pages: \+//')

    if [[ "$name" == "mwe" ]]; then
        continue
    fi

    if [[ "$dir" != "./cal-burst" && $pages -gt 1 ]]; then
        continue
    fi

    out="$dir/$name.jpg"
    echo "$i -> $out"
    convert -density 600 "$i" -flatten -compress jpeg -quality 90 -filter Lanczos -resize '270x' -bordercolor black -border 2 "$out"
done

