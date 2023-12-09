#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

if ! (( $# ))
then
    echo >&2 "$0: Supply at least one video file."
    exit 64 # EX_USAGE
fi

here=$(dirname "$0")
tempbase=$(mktemp -d dvdauthor.XXXXXX)
outdir=$tempbase/dvd
state=$tempbase/tmp

(
trap 'rm -rf "$outdir"' EXIT

(
trap 'rm -rf "$state"' EXIT

mkdir -p "$outdir" "$state"
echo >&2 "Generating output in $outdir"
echo >&2 "Temporary files are in $state"

converted=( )

ffmpeg_flags=(
    -target ntsc-dvd

    -aspect 4:3
    -b:v "(${BITRATE_MULTIPLIER:-1.0} * ${BITRATE:-1976k})"
    -bufsize 4M

    -acodec ac3
    -ac 1
    -b:a 128k
)

for f in "$@"
do
    echo >&2 "Converting $f ..."
    out="$state/$(basename "${f%.???}").mpg"
    (
        absolute="$PWD/$out"
        cd "$(mktemp -d "$state"/mpg.XXXXXX)"
        if [[ ${TWOPASS:-} ]]
        then
            ffmpeg -y -i "$f" "${ffmpeg_flags[@]}" -an -pass 1 /dev/null
            ffmpeg    -i "$f" "${ffmpeg_flags[@]}"     -pass 2 "$absolute"
        else
            ffmpeg -y -i "$f" "${ffmpeg_flags[@]}" "$absolute"
        fi
    )
    converted+=( "$out" )
    echo >&2 "done converting $f."
done

echo >&2 "Making menus ..."
menu_mpg=$("$here"/make-menu.sh "${converted[@]}")

cat > "$state"/dvd.xml <<EOF
<?xml version="1.0"?>
<dvdauthor>
  <vmgm>
    <fpc>jump titleset 1 menu;</fpc>
  </vmgm>
  <titleset>
    <menus>
      <pgc pause="inf">
        <vob file="$menu_mpg"/>         $(for i in $(seq 1 $#); do echo "
        <button>jump title $i;</button> "; done)
      </pgc>
    </menus>
    <titles>                            $(for f in "${converted[@]}"; do echo "
      <pgc>
        <vob file=\"$f\"/>
        <post>call menu;</post>
      </pgc>                            "; done)
    </titles>
  </titleset>
</dvdauthor>
EOF

echo >&2 "Authoring DVD ..."
VIDEO_FORMAT=NTSC dvdauthor -o "$outdir" -x "$state"/dvd.xml
)

"$here"/burn-dvd.sh "$outdir" "${DVD_TITLE:-}"
)

echo >&2 -n "Result: "
echo "$PWD/$outdir"
