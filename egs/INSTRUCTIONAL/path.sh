#!/usr/bin/env bash

# adds root directory of `kaldi` to $PATH
export KALDI_ROOT=`pwd`/../../

# adds librispeech_instructional/utils to $PATH
# adds openfst to $PATH
# adds IRSTLM to $PATH
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH

[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

# we use this both in the (optional) LM training and the G2P-related scripts
PYTHON='python2.7'

# adds a src directories for C++ code
export PATH=${PATH_TO_KALDI}/egs/nextiva_recipes/utils/:${PATH_TO_KALDI}/src/bin:${PATH_TO_KALDI}/tools/openfst/bin:${PATH_TO_KALDI}/src/fstbin/:${PATH_TO_KALDI}/src/gmmbin/:${PATH_TO_KALDI}/src/featbin/:${PATH_TO_KALDI}/src/lm/:${PATH_TO_KALDI}/src/sgmmbin/:${PATH_TO_KALDI}/src/fgmmbin/:${PATH_TO_KALDI}/src/latbin/:${PATH_TO_KALDI}/src/lmbin/:${PATH_TO_KALDI}/src/chainbin/:${PATH_TO_KALDI}/src/ivectorbin/:${PATH_TO_KALDI}/src/kwsbin/:${PATH_TO_KALDI}/src/nnet2bin/:${PATH_TO_KALDI}/src/nnet3bin/:${PATH_TO_KALDI}/src/nnetbin/${PATH_TO_KALDI}/src/onlinebin/:${PATH_TO_KALDI}/src/online2bin/:${PATH_TO_KALDI}/src/sgmm2bin:${PATH_TO_KALDI}/src/sgmmbin/:$PATH
export LC_ALL=C






### Below are the paths used by the optional parts of the recipe

# We only need the Festival stuff below for the optional text normalization(for LM-training) step
#FEST_ROOT=tools/festival
#NSW_PATH=${FEST_ROOT}/festival/bin:${FEST_ROOT}/nsw/bin
#export PATH=$PATH:$NSW_PATH

# SRILM is needed for LM model building
#SRILM_ROOT=$KALDI_ROOT/tools/srilm
#SRILM_PATH=$SRILM_ROOT/bin:$SRILM_ROOT/bin/i686-m64
#export PATH=$PATH:$SRILM_PATH

# Sequitur G2P executable
#sequitur=$KALDI_ROOT/tools/sequitur/g2p.py
#sequitur_path="$(dirname $sequitur)/lib/$PYTHON/site-packages"

# Directory under which the LM training corpus should be extracted
#LM_CORPUS_ROOT=./lm-corpus
