#!/bin/bash

for i in *.pdf ./cal-burst/*.pdf; do
    dir=$(dirname "$i")
    name=$(basename "$i" .pdf)
    out="$dir/$name.jpg"
    echo "$i -> $out"
    convert -density 600 "$i" -flatten -compress jpeg -quality 90 -filter Lanczos -resize '250x' -bordercolor black -border 2 "$out"
done

