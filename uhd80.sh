#!/bin/bash
#
# This script:
# 1) Resizes to UHD (3840x2160) *if bigger*
# 2) Compresses with ImageMagick quality 80
# 3) Replaces original file *if new file is smaller than 80% of original*
#
# The output file gets "uhd80" appended, the original file gets
# ".resized" appended and goes to the trash. This is done to easily
# identify processed pictures when browsing the trash.

set -eu

MYNAME=$(basename "$0")

# Postfix
p="_uhd80"

# Target size
maxw=3840
maxh=2160

# Resize the SMALLER side to 2160px if it is larger
RESIZE="-resize 2160^>"

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
