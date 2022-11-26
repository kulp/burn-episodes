#!/usr/bin/env bash

# Fail early and loudly.
set -o errexit -o nounset -o pipefail

dir=${1?"Supply a directory containing VIDEO_TS"}
title=${2?"Supply a title for the DVD"}

iso=$(mktemp -d)/dvd.iso
trap "rm $iso" EXIT
mkisofs -dvd-video -output $iso -volid "$title" "$dir"
hdiutil burn -nosynthesize -noverifyburn -forceclose $iso
