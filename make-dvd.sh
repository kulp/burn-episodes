#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

here=$(dirname $0)
tempbase=$(mktemp -d dvdauthor.XXXXXX)
outdir=$tempbase/dvd
state=$tempbase/tmp
trap "rm -rf $state" EXIT

mkdir -p $outdir $state
echo >&2 "Generating output in $outdir"
echo >&2 "Temporary files are in $state"

converted=( )

ffmpeg_flags=(
    -target ntsc-dvd

    -aspect 4:3
    -b:v 1976k
    -bufsize 4M

    -acodec mp2
    # Reducing the sample rate might theoretically help avoid wasting our
    # (intentionally constrained) audio bandwidth, but appears to cause
    # dvdauthor to choke for lack of sufficient NAV frames (?).
    #-ar 24000
    -ac 1
    -b:a 112k
)

for f in "$@"
do
    echo >&2 "Converting $f ..."
    out="$state/$(basename "${f%.???}").mpg"
    (
        absolute="$(realpath "$out")"
        cd "$(mktemp -d $state/mpg.XXXXXX)"
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
menu_mpg=$($here/make-menu.sh "${converted[@]}")

cat > $state/dvd.xml <<EOF
<?xml version="1.0"?>
<dvdauthor>
  <vmgm/>
  <titleset>
    <menus>
      <pgc pause="inf">
        <vob file="$menu_mpg"/>         $(for i in $(seq 1 $#); do echo "
        <button>jump title $i;</button> "; done)
      </pgc>
    </menus>
    <titles>                            $(for f in "${converted[@]}"; do echo "
      <pgc pause='inf'>
        <vob file='$f'/>
      </pgc>                            "; done)
    </titles>
  </titleset>
</dvdauthor>
EOF

echo >&2 "Authoring DVD ..."
VIDEO_FORMAT=NTSC dvdauthor -o $outdir -x $state/dvd.xml

echo >&2 -n "Result: "
realpath $outdir
