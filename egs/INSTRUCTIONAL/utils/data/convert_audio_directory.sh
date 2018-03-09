#!/usr/bin/env bash

# wraps convert_audio_single.sh to be used on an entire directory

# ARGUMENTS
# REQUIRED
# -i <directory> = full path to directory containing audio files to convert
# -o <directory> = full path to directory to place converted audio files
# -t <string> = original filetype, default = `.wav`

# OPTIONAL
# -s <int> = resample rate
# -r = if present, will remove original audio


filetype=".flac"
remove=false

while getopts "i:o:s:t:r" opt; do
    case ${opt} in
        i)
            in=${OPTARG}/
            ;;
        o)
            out=${OPTARG}/
            ;;
        s)
            sample_rate=${OPTARG}
            ;;
        t)
            filetype=${OPTARG}
            ;;
        r)
            remove=true
            ;;
        \?)
            echo "Wrong flags"
            exit 1
            ;;
    esac
done


mkdir -p ${out}

ALLFILES=( $(find ${in} -name *$filetype -type f) )

echo "converting all audio found in ${in}"

for file_in in ${ALLFILES[@]}; do
    base=$(basename ${file_in})
    if [ ! -z ${sample_rate} ]; then
        if [ ${remove} == true ]; then
            ${KALDI_INSTRUCTIONAL_PATH}/utils/data/convert_audio_single.sh \
                -i ${file_in} \
                -o ${out}${base%%$2}.wav \
                -s ${sample_rate} \
                -r
        else
            ${KALDI_INSTRUCTIONAL_PATH}/utils/data/convert_audio_single.sh \
                -i ${file_in} \
                -o ${out}${base%%$2}.wav \
                -s ${sample_rate}
        fi
    else
        if [ ${remove} == true ]; then
            ${KALDI_PATH}/utils/data/convert_audio_single.sh \
                -i ${file_in} \
                -o ${out}${base%%$2}.wav \
                -r
        else
            ${KALDI_PATH}/utils/data/convert_audio_single.sh \
                -i ${file_in} \
                -o ${out}${base%%$2}.wav
        fi
    fi
done

echo "audio in ${in} is converted"

if [[ ${remove} == true && ${in} != ${out} ]]; then
    rm -r ${in}
fi

