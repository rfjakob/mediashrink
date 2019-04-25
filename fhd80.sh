#!/bin/bash
#
# Resize pictures to FullHD (1920x1080), save with quality 80

set -eu

set -eu

MYNAME=$(basename "$0")

# Postfix
p="_fhd80"

# Resize the SMALLER side to 1080px if it is larger
RESIZE="-resize 1080^>"

# We are a low-priority job
renice 19 $$ > /dev/null

SKIPPED=0
KEPT=0
REPLACED=0

for f in "$@"
do
	# Filename without extension
	n=${f%.*}
	# Output file
	out="$n$p.jpg"

	if [[ "$n" == *$p ]]
	then
			echo "$f: Skipping, already has \"$p\" postfix"
			let SKIPPED=SKIPPED+1
			continue
	fi

	# Is the file a JPEG image?
	if ! file "$f" | grep "JPEG image data" > /dev/null
	then
		echo "$f: Skipping, not a JPEG image"
		let SKIPPED=SKIPPED+1
		continue
	fi

	# Resize and compress to JPG quality 80, progressive
	convert -verbose $RESIZE -interlace Plane -quality 80 "$f" "$out.tmp"

	# Calculate new filesize
	old_size=$(stat --printf="%s" "$f")
	new_size=$(stat --printf="%s" "$out.tmp")
	percent=$((new_size * 100 / old_size))
	echo -n "New size: $percent%. "

	# Overwrite original image only if the new one is significantly
	# smaller
	if [[ $percent -gt 80 ]]
	then
		echo "Keeping original."
		rm "$out.tmp"
		let KEPT=KEPT+1
		continue
	else
		echo "Replacing file."
		mv "$out.tmp" "$out"
		let REPLACED=REPLACED+1
	fi

	# Restore original timestamp
	touch -r "$f" "$out"

	# Move original file to trash
	trash-put "$f"
done

# Print success message to terminal and to GUI notifications,
# if availabe.
MSG="Done. Replaced $REPLACED files, kept $KEPT, skipped $SKIPPED"
echo "$MSG"
if command -v notify-send ; then
	notify-send "$MYNAME" "$MSG"
fi
