#!/bin/bash

cd "$(dirname "$0")"

rm diff-old/* diff-new/* diff-compare/*
touch diff-old/.gitkeep diff-new/.gitkeep diff-compare/.gitkeep

get_page_count() {
    pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ {print $2}'
}

calendars_from_makefile() {
    sed -n 's/.*calendars: \(.*\)/\1/p' Makefile | tr ' ' '\n' | grep '\.pdf$' | sed 's/\.pdf$//'
    sed -n 's/^cal-translations: \(.*\)/\1/p' Makefile | tr ' ' '\n' | sed 's/\.pdf$//'
}

restore_pdf() {
    local name="$1"
    if git ls-files --error-unmatch "${name}.pdf" >/dev/null 2>&1; then
        git checkout "${name}.pdf" 2>/dev/null
    else
        rm -f "${name}.pdf"
    fi
}

skipped=()
differ=()

for cal in $(calendars_from_makefile); do
    name="${cal}"
    pdf="${name}.pdf"

    echo -n "Processing $name... "

    if [[ -f "$pdf" ]]; then
        restore_pdf "$name"
        pages=$(get_page_count "$pdf")
    else
        pages=0
    fi

    if [[ "$pages" -gt 1 ]]; then
        pdftk "$pdf" burst output ./diff-old/"$name"-%02d.pdf
    elif [[ -f "$pdf" ]]; then
        cp "$pdf" ./diff-old/"$name"-01.pdf
    fi

    if ! make "$pdf" -B > out.log 2>&1; then
        echo "SKIPPED (build failed)"
        skipped+=("$name")
        continue
    fi

    if [[ "$pages" -gt 1 ]]; then
        pdftk "$pdf" burst output ./diff-new/"$name"-%02d.pdf
    elif [[ -f "$pdf" ]]; then
        cp "$pdf" ./diff-new/"$name"-01.pdf
    fi

    echo "done"
done

for i in ./diff-old/*.pdf; do
    [[ -f "$i" ]] || continue
    name=$(basename "$i")
    calname="${name%.pdf}"
    calname="${calname%-???}"

    if [[ " ${skipped[@]} " =~ " ${calname} " ]]; then
        continue
    fi

    if [[ ! -f "./diff-new/$name" ]]; then
        skipped+=("$name (missing from diff-new)")
        continue
    fi

    metric=$(compare -metric AE "./diff-old/$name" "./diff-new/$name" -compose src -alpha off "./diff-compare/${name%.pdf}.jpg" 2>&1)
    ae_value="${metric%% *}"
    if [[ "$ae_value" != "0" ]]; then
        differ+=("$name: $metric")
    fi
done

echo "Restoring PDFs to committed versions..."
for cal in $(calendars_from_makefile); do
    restore_pdf "$cal"
done

if [[ ${#skipped[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped due to build failure:"
    for s in "${skipped[@]}"; do
        echo "  - $s"
    done
fi

if [[ ${#differ[@]} -gt 0 ]]; then
    echo ""
    echo "Files with differences:"
    for d in "${differ[@]}"; do
        echo "  - $d"
    done
fi

echo "Done."
