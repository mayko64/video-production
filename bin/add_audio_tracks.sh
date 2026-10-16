#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 3 ]; then
    echo "Usage:"
    echo "  $0 INPUT_VIDEO OUTPUT_VIDEO AUDIO1 [AUDIO2 AUDIO3 ...]"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
shift 2

TRACKS=("$@")

# Settings
VOLUME="${VOLUME:-0.22}"
CROSSFADE="${CROSSFADE:-2}"
FADEOUT="${FADEOUT:-5}"

# Check dependencies
command -v ffmpeg >/dev/null || {
    echo "ffmpeg not found"
    exit 1
}

command -v ffprobe >/dev/null || {
    echo "ffprobe not found"
    exit 1
}

# Get video duration
VIDEO_DURATION=$(
    ffprobe -v error \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 \
        "$INPUT"
)

if [ -z "$VIDEO_DURATION" ]; then
    echo "Could not determine video duration"
    exit 1
fi

echo "Video duration: $VIDEO_DURATION seconds"

# Build a sequence of tracks long enough to cover the video
SEQUENCE=()
TOTAL=0
INDEX=0

while awk "BEGIN { exit !($TOTAL < $VIDEO_DURATION + $CROSSFADE) }"; do

    TRACK="${TRACKS[$((INDEX % ${#TRACKS[@]}))]}"

    TRACK_DURATION=$(
        ffprobe -v error \
            -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 \
            "$TRACK"
    )

    if [ -z "$TRACK_DURATION" ]; then
        echo "Could not determine duration of: $TRACK"
        exit 1
    fi

    SEQUENCE+=("$TRACK")

    if [ "${#SEQUENCE[@]}" -eq 1 ]; then
        TOTAL="$TRACK_DURATION"
    else
        TOTAL=$(awk \
            "BEGIN { print $TOTAL + $TRACK_DURATION - $CROSSFADE }")
    fi

    INDEX=$((INDEX + 1))
done

echo
echo "Music sequence:"
for TRACK in "${SEQUENCE[@]}"; do
    echo "  $(basename "$TRACK")"
done

echo

# Build ffmpeg input arguments
FFMPEG_INPUTS=(-i "$INPUT")

for TRACK in "${SEQUENCE[@]}"; do
    FFMPEG_INPUTS+=(-i "$TRACK")
done

# Build filter graph
FILTER=""

# Apply volume to every track
for i in "${!SEQUENCE[@]}"; do
    AUDIO_INDEX=$((i + 1))
    FILTER+="[$AUDIO_INDEX:a]volume=$VOLUME[a$AUDIO_INDEX];"
done

# Join tracks with crossfades
if [ "${#SEQUENCE[@]}" -eq 1 ]; then

    LAST="[a1]"

else

    FILTER+="[a1][a2]acrossfade=d=$CROSSFADE:c1=tri:c2=tri[x2];"
    LAST="[x2]"

    for ((i = 3; i <= ${#SEQUENCE[@]}; i++)); do

        FILTER+="${LAST}[a$i]acrossfade=d=$CROSSFADE:c1=tri:c2=tri[x$i];"
        LAST="[x$i]"

    done

fi

# Fade out at the end of the video
FADE_START=$(awk \
    "BEGIN {
        s = $VIDEO_DURATION - $FADEOUT
        if (s < 0) s = 0
        print s
    }"
)

FILTER+="${LAST}atrim=duration=$VIDEO_DURATION,"
FILTER+="afade=t=out:st=$FADE_START:d=$FADEOUT[music]"

echo "Rendering..."
echo

ffmpeg \
    "${FFMPEG_INPUTS[@]}" \
    -filter_complex "$FILTER" \
    -map 0:v \
    -map "[music]" \
    -c:v copy \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    "$OUTPUT"

echo
echo "Done:"
echo "$OUTPUT"

