#!/usr/bin/env bash
# Turn a single still image into a vertical (9:16) Instagram Reel-ready video
# with a blurred fill background and a slow Ken Burns zoom-in.
#
# Usage:
#   scripts/make_instagram_reel.sh <input_image> <output.mp4> [duration_seconds]
#
# Requires: ffmpeg

set -euo pipefail

INPUT="${1:?usage: make_instagram_reel.sh <input_image> <output.mp4> [duration_seconds]}"
OUTPUT="${2:?usage: make_instagram_reel.sh <input_image> <output.mp4> [duration_seconds]}"
DURATION="${3:-12}"
WIDTH=1080
HEIGHT=1920
FPS=30

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
COMPOSITE="$WORKDIR/composite_still.jpg"

# 1) Composite the source image onto a 1080x1920 canvas: a blurred, filled
#    copy in the background so nothing gets cropped, with the full image
#    centered on top.
ffmpeg -y -i "$INPUT" -filter_complex "
[0:v]split=2[a][b];
[a]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},gblur=sigma=30,eq=brightness=-0.12[bg];
[b]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease[fg];
[bg][fg]overlay=(W-w)/2:(H-h)/2[out]" \
  -map "[out]" -frames:v 1 "$COMPOSITE"

# 2) Animate the composite with a slow zoom-in (Ken Burns effect) and a
#    silent audio track (Instagram's upload flow expects an audio stream).
ffmpeg -y -loop 1 -i "$COMPOSITE" -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
  -filter_complex "[0:v]scale=$((WIDTH*2)):$((HEIGHT*2)),zoompan=z='min(zoom+0.0006,1.15)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS},format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=$((DURATION - 1)).4:d=0.6[v]" \
  -map "[v]" -map 1:a -t "$DURATION" -c:v libx264 -preset medium -crf 19 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -shortest -movflags +faststart \
  "$OUTPUT"

echo "Reel written to $OUTPUT"
