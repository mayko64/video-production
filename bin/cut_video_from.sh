#!/usr/bin/env bash

set -e

SCRIPT_NAME="$(basename "$0")"

if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $SCRIPT_NAME INPUT.mkv OUTPUT.mkv END"
    echo
    echo "Example:"
    echo "  $SCRIPT_NAME input.mkv output.mkv 01:23:45"
    echo
    echo "END = video will be cut after this time."
    echo "Time format: HH:MM:SS"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
END="$3"

if [ ! -f "$INPUT" ]; then
    echo "Error: input file not found: $INPUT"
    exit 1
fi

echo
echo "WARNING:"
echo "The video will be cut at a keyframe."
echo
echo "Everything AFTER $END will be removed."
echo
echo "The video will NOT be re-encoded."
echo "The actual cut point may differ slightly from the requested time."
echo

read -r -p "Press Enter to continue, or Ctrl+C to cancel..."

echo
echo "Trimming..."

ffmpeg -hide_banner -loglevel warning \
    -i "$INPUT" \
    -t "$END" \
    -map 0 \
    -c copy \
    "$OUTPUT"

echo
echo "Done:"
echo "  $OUTPUT"

