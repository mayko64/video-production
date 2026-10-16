#!/usr/bin/env bash

set -e

SCRIPT_NAME="$(basename "$0")"

if [ "$#" -ne 4 ]; then
    echo "Usage:"
    echo "  $SCRIPT_NAME INPUT.mkv OUTPUT.mkv START END"
    echo
    echo "Example:"
    echo "  $SCRIPT_NAME input.mkv output.mkv 00:12:30 00:17:30"
    echo
    echo "Time format:"
    echo "  HH:MM:SS"
    echo
    echo "START and END define the section to REMOVE."
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
START="$3"
END="$4"

if [ ! -f "$INPUT" ]; then
    echo "Error: input file not found: $INPUT"
    exit 1
fi

echo
echo "WARNING:"
echo "This operation will cut the video ONLY at keyframes."
echo
echo "The section that will be REMOVED:"
echo "  $START  ->  $END"
echo
echo "The video will NOT be re-encoded."
echo "Cut points may therefore be slightly different from the requested times."
echo
read -r -p "Press Enter to continue, or Ctrl+C to cancel..."

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PART1="$TMPDIR/part1.mkv"
PART2="$TMPDIR/part2.mkv"

echo
echo "Cutting..."

# Part before the section to remove
ffmpeg -hide_banner -loglevel warning \
    -i "$INPUT" \
    -t "$START" \
    -map 0 \
    -c copy \
    "$PART1"

# Part after the section to remove
ffmpeg -hide_banner -loglevel warning \
    -ss "$END" \
    -i "$INPUT" \
    -map 0 \
    -c copy \
    "$PART2"

echo "Joining..."

LIST="$TMPDIR/concat.txt"

printf "file '%s'\n" "$PART1" > "$LIST"
printf "file '%s'\n" "$PART2" >> "$LIST"

ffmpeg -hide_banner -loglevel warning \
    -f concat \
    -safe 0 \
    -i "$LIST" \
    -c copy \
    "$OUTPUT"

echo
echo "Done:"
echo "  $OUTPUT"

