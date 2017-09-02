#!/bin/bash
#
# Recompress with mozjpeg, quality 80

MOZJPEG=/usr/local/bin/cjpeg

set -eu

# Postfix
p="_q80"

for f in "$@"
do
	# Filename without extension
	n="${f%.*}"
	# Output file
	out="$n$p.jpg"

	if [[ "$n" == *$p ]]
	then
			echo "$f: Skipping, already has \"$p\" postfix"
			continue
	fi

	# Is the file a JPEG image?
	if ! file "$f" | grep "JPEG image data" > /dev/null
	then
		echo "$f: Skipping, not a JPEG image"
		continue
	fi

	# Actual recomp
	echo -n "$f: Recompressing. "
	# mozjpeg has better compression AND quality than standard imagemagick
	nice $MOZJPEG -quality 80 "$f" > "$out.tmp"
	old_size=$(stat --printf="%s" "$f")
	new_size=$(stat --printf="%s" "$out.tmp")
	percent=$((new_size * 100 / old_size))
	echo -n "New size: $percent%. "

	if [[ $percent -gt 80 ]]
	then
		echo "Keeping original."
		rm "$out.tmp"
		continue
	else
		echo "Replacing file."
		mv "$out.tmp" "$out"
	fi

	# Restore original timestamp
	touch -r "$f" "$out"

	# Move original file to trash
	trash-put "$f"
done
