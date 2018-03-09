#!/bin/bash

# startup script for kaldi instance

# make sure codebase is up-to-date
cd /scratch
if [ ! -d "kaldi" ]; then
  git clone https://github.com/michaelcapizzi/kaldi.git
  wait
  cd kaldi
  git checkout kaldi_instructional
else
  cd kaldi
  git checkout kaldi_instructional
  wait
  git pull
fi

# make sure bjoyce3 and mcapizzi are in users
added_to_groups=$(cat /etc/group | grep bjoyce3)
if [ -z ${added_to_groups} ]; then
  cp /etc/group /etc/group.original
  wait
  sed -i.bak -E "s%(users:x:[0-9]+:[a-z,]+)%\1mcapizzi,bjoyce3,%" /etc/group
fi