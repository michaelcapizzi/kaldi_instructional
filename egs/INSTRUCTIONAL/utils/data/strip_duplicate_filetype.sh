#!/usr/bin/env bash

# This script will remove a duplicate filetype from filename

# $1 = directory for audio filenames to clean

ALLFILES=( $(find $1 -name *.wav -type f) )

for f in ${ALLFILES[@]}; do
  before_filetype=${f%%.*}
  mv ${f} ${before_filetype}.wav
done

echo "all files in ${1} have been renamed"
