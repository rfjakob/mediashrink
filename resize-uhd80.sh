#!/bin/bash
#
# Resize pictures to UHD (3840x2160), save with quality 80
#
# The output file gets "uhd80" appended, the original file gets
# ".resized" appended and goes to the trash. This is done to easily
# identify processed pictures when browsing the trash.

set -eu

# Postfix
p="_uhd80"

# Target size
maxw=3840
maxh=2160

# Resize the SMALLER side to 2160px if it is larger
RESIZE="-resize 2160^>"

# We are a low-priority job
renice 19 $$ > /dev/null

for f in "$@"
do
	# Filename without extension
	n=${f%.*}
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
