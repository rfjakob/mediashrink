#!/bin/bash
#
# Transcode Motion JPEG to x264/aac in mp4 container
#
# The output file gets the .mp4 extension

set -eu

for f in "$@"
do
	# Filename without extension
	n=${f%.*}
	# Extension
	e="${f##*.}"

	# Test if the file is in motion JPEG format
	if ! file "$f" | grep "video: Motion JPEG"
	then
		echo "$f: Not Motion JPEG"
		continue
	fi

	# Actual transcode. For an .mp4 output file, ffmpeg uses
	# libx264 and aac per default (checked Apr 2019). Specify the
	# codecs explicitely should the defaults change.
	nice ffmpeg -hide_banner -i "$f" -c:v libx264 -c:a aac "$n.mp4"

	# Restore original timestamp
	t=$(stat -c %Y "$f")
	touch -d "@$t" "$n.mp4"

	# Show old and new size
	ls -sh "$f" "$n.mp4"

	# Rename original file and move to trash
	mv "$f" "$n-transcoded.$e"
	trash-put "$n-transcoded.$e"
done
