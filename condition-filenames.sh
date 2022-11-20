#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

gxargs -d'\n' basename -a |
    sed -r '
        s/^Episode //;
        s/MSTR([0-9]{4})PM/\1/;
        s/([0-9]{4})_[0-9]/\1/;
    '
