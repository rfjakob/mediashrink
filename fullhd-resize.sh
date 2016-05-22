#!/bin/bash
#
# Resize pictures to FullHD (1920x1080)
#
# The output file gets "fullhd" appended, the original file gets
# "fullhd-resized" appended and goes to the trash. This is done to easily
# identify processed pictures when browsing the trash.

set -eu

# Postfix
p="_fullhd"

for f in "$@"
do
	s="1920x1920"

	# Filename without extension
	n=${f%.*}
	# Extension
	e="${f##*.}"

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

	# Smaller than 1920px (already resized)?
	w=$(identify -format %w "$f") || continue
	h=$(identify -format %h "$f")
	if [[ $w -le 2048 && $h -le 2048 ]]
	then
		echo "$f: Skipping, already small: ${w}x${h}"
		continue
	elif [[ $(( 2 * h )) -le $w ]]
	then
		echo "$f: Detected panorama: ${w}x${h}"
		s="x1080"
	fi

	# The Moto X camera has a strange aspect ratio of 15.987:9.
	# Fix it by cropping off 2 pixels.
	c=""
	if [[ $w -eq 4320 && $h -eq 2432 ]]
	then
		echo "$f: Detected Moto X landscape picture, cropping to 16:9"
		c="-crop 4320x2430+0+0"
	elif  [[ $w -eq 2432 && $h -eq 4320 ]]
	then
		echo "$f: Detected Moto X portrait picture, cropping to 16:9"
		c="-crop 2430x4320+0+0"
	fi

	# Actual resize
	echo "$f: Resizing ${w}x${h} to max $s"
	nice convert "$f" $c -resize $s "$n$p.$e"

	# Restore original timestamp
	t=$(stat -c %Y "$f")
	touch -d "@$t" "$n$p.$e"

	# Rename original file and move to trash
	mv "$f" "$n$p-resized.$e"
	trash-put "$n$p-resized.$e"
done
