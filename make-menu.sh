#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

filenames=( "$@" )

remove_last_newline ()
{
    perl -ne 'print $last if $.>1; $last = $_; END{chomp $last; print $last}' "$@"
}

orig_pwd=$(pwd)
cd $(mktemp -d menu.XXXXXX)

spacing=10
basename -a "${filenames[@]%.*}" |
    remove_last_newline |
    # Without a `-trim`, interlinear spacing of 10 seems to work, but that is probably at best a happy accident.
    # For `png:color-type=3` see PNG color depth: https://www.w3.org/TR/png/#11IHDR
    magick -background black -fill white -interline-spacing $spacing -font Helvetica -size 'x460>' label:@- -resize '720x>' \
        -repage 720x480 -repage +'%[fx:(%[W]-%[w])/2]+%[fx:(%[H]-%[h])/2]' -type Grayscale -colors 3 +write mpr:all \( mpr:all -crop "1x${#filenames[@]}@" +write tile-%d.png \) \( mpr:all -gravity center -extent 720x480 +write all.png -negate +write all-invert.png \) null:

cat <<EOF | xmllint --pretty 1 - > menu.xml
<subpictures>
  <stream>
    <spu start="0" image="all.png" highlight="all-invert.png" force="yes">
      $(identify -set option:ys '%[fx:%[Y]]' -set option:ye '%[fx:%[h]+%[Y]]]' -format '
      <button x0="%[fx:%[X]]" y0="%[fx:%[ys]+%[ys]%2]" x1="%w" y1="%[fx:%[ye]-%[ye]%2]"/>\n' tile-*.png)
    </spu>
  </stream>
</subpictures>
EOF

(
exec >&2
magick -size 720x480 canvas:black -depth 8 ppm:- |
    ppmtoy4m -r -n 60 |
    y4mscaler -O preset=dvd |
    mpeg2enc -o black.m2v
dd if=/dev/zero bs=4 count=1000 |
    lame -r -b 128 -s 48000 - output.m2a
mplex -f 8 -o /dev/stdout black.m2v output.m2a |
    spumux menu.xml > menu.mpg
)
realpath --relative-to="$orig_pwd" menu.mpg
