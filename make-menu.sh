#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

filenames=( "$@" )

remove_last_newline ()
{
    perl -ne 'print $last if $.>1; $last = $_; END{chomp $last; print $last}' "$@"
}

spacing=10
active_color=lightgreen
for color in white $active_color
do
    (IFS=$'\n'; echo "${filenames[*]}") |
        remove_last_newline |
        # Without a `-trim`, interlinear spacing of 10 seems to work, but that is probably at best a happy accident.
        # For `png:color-type=3` see PNG color depth: https://www.w3.org/TR/png/#11IHDR
        magick -background black -fill transparent -interline-spacing $spacing -font Helvetica -size x460 label:@- -resize '700x>' \
            -background $color -flatten -repage 720x480 -repage +'%[fx:(%[W]-%[w])/2]+%[fx:(%[H]-%[h])/2]' -define png:color-type=3 -colors 8 -type Palette +write png8:all-$color.png -crop 1x10@ tile-$color-%d.png
done
