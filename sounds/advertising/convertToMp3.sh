#!/usr/bin/env bash

# Convert all .ogg files in the script's directory to .mp3 (same filenames)
# Requires: ffmpeg

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for f in "$SCRIPT_DIR"/*.ogg; do
    [ -e "$f" ] || continue  # skip if none exist
    base="${f%.*}"
    ffmpeg -i "$f" -codec:a libmp3lame -qscale:a 2 "${base}.mp3"
done

