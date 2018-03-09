#!/usr/bin/env bash

# This script will generate a wav.scp file for a given directory of audio

# $1 path to audio directory
# $2 path to write wav.scp

audio_dir=$1
wav_scp_out=$2

mkdir -p ${KALDI_INSTRUCTIONAL_PATH}/data/local
waves_list=${KALDI_INSTRUCTIONAL_PATH}/data/local/waves_list

# get a list of all the audio files in the directory
ls -1 ${audio_dir} > ${waves_list}

# sort files by bytes (preferred approach for kaldi)
if [[ -e ${waves_list} ]]; then
        LC_ALL=C sort -i ${waves_list} -o ${waves_list}
fi

# build wav.scp file
${KALDI_INSTRUCTIONAL_PATH}/local/create_wav_scp.pl \
        ${audio_dir} \
        ${waves_list} > ${wav_scp_out}

echo "file written to ${wav_scp_out}"

