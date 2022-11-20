#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

ffmpeg_flags=(
    -target ntsc-dvd

    -aspect 4:3
    -b:v 2010k

    -acodec mp2
    # Reducing the sample rate might theoretically help avoid wasting our
    # (intentionally constrained) audio bandwidth, but appears to cause
    # dvdauthor to choke for lack of sufficient NAV frames (?).
    #-ar 24000
    -ac 1
    -b:a 112k
)

state=$(mktemp -d)

echo "$state"
for f in "$@"
do
    out="$state/$(basename "${f%.???}").mpg"
    (cd "$(mktemp -d)"
        ffmpeg -y -i "$f" "${ffmpeg_flags[@]}" -an -pass 1 /dev/null
        ffmpeg    -i "$f" "${ffmpeg_flags[@]}"     -pass 2 "$out"
    )
done
