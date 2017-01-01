#!/bin/bash
#
# Compress pdfs using ps2pdf.

set -eu

for f in "$@"
do
    fnew="$f.new"
    echo "Compressing $f"
    ps2pdf -dAutoRotatePages=/None "$f" "$fnew"
    old_size=$(stat --printf="%s" "$f")
    new_size=$(stat --printf="%s" "$fnew")
    percent=$((new_size * 100 / old_size))
    echo -n "New size: $percent%. "

    if [[ $percent -gt 80 ]]
    then
        echo "Keeping original."
        rm "$fnew"
        continue
    else
        echo "Replacing file."
        mv "$fnew" "$f"
    fi
done
