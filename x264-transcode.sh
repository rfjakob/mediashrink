#!/bin/bash
#
# Transcode Motion JPEG to x264 + mp3
#
# The output file gets "_x264" appended

set -eu

# Postfix
p="_x264"

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

	# Actual resize
	nice ffmpeg -i "$f" -c:v libx264 -c:a libmp3lame -aq 2 "$n$p.mkv"

	# Restore original timestamp
	t=$(stat -c %Y "$f")
	touch -d "@$t" "$n$p.mkv"

	# Rename original file and move to trash
	mv "$f" "$n$p-transcoded.$e"
	trash-put "$n$p-transcoded.$e"
done
