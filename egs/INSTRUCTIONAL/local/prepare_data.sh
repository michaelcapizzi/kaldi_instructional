#!/bin/bash

# This script prepares the data for training by formatting input data properly.
# NOTE: This script can be run with or without testing data

# -r = full path to `transcripts` file
# NOTE: if flag *not* present, assumes segmented transcript files
# -x = full path to `lexicon.txt` file
# -p = full path to `phones.txt` file
# -s = list of phones representing silence, default=`SIL OOV`
# -l = full path to `language_model` file
# -n = full path of training data
# -t = full path of testing data
# -u = using UNsegmented transcript file [optional]
# -g <path> = full path to TRAIN segments file  **needed if *not -u*
# -h <path> = full path to TEST segments file   **needed if *not -u*


# default values for variables
train_dir=""
test_dir=""
segmented=true
silence_phones="SIL OOV"
language_model=

while getopts "r:ux:p:s:l:n:t:g:h:" opt; do
    case ${opt} in
        r)
            transcripts=${OPTARG}
            ;;
        u)
            segmented=false
            ;;
        x)
            lexicon=${OPTARG}
            ;;
        p)
            phones=${OPTARG}
            ;;
        s)
            silence_phones=${OPTARG}
            ;;
        l)
            language_model=${OPTARG}
            ;;
        n)
            train_dir=${OPTARG}
            ;;
        t)
            test_dir=${OPTARG}
            ;;
        g)
            segmentsTRAIN=${OPTARG}
            ;;
        h)
            segmentsTEST=${OPTARG}
            ;;
        \?)
            echo "Wrong flags"
            exit 1
            ;;
    esac
done

# make nextiva_recipes/data/local/
mkdir -p ${KALDI_INSTRUCTIONAL_PATH}/data/local

echo "Preparing data"

# write `waves.train` and/or `waves.test` files
if [[ ${train_dir} != "" ]]; then
    ls -1 ${train_dir} > ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.train
fi
if [[ ${test_dir} != "" ]]; then
    ls -1 ${test_dir} > ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.test
fi

# sort files by bytes (kaldi-style) and re-save them with original filename
#for file in waves.test waves.train; do
for file in ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.test data/local/waves.train; do
    if [[ -e ${file} ]]; then
        LC_ALL=C sort -i ${file} -o ${file};
    fi
done

for item in ${train_dir} ${test_dir}; do

    # if dealing with train_dir
    if [[ ${item} == ${train_dir} ]]; then

        # make a data/train_dir directory
        mkdir -p ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir

        # make a two-column list of test utterance ids and their paths
        ${KALDI_INSTRUCTIONAL_PATH}/local/create_wav_scp.pl \
            ${train_dir} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.train \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/wav.scp

        # create separate transcription file
        # <utteranceID> <text>
        if [ "${segmented}" = true ]; then

            python ${KALDI_INSTRUCTIONAL_PATH}/local/create_txt_segments.py \
                ${transcripts} \
                ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.train \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/text
            cp ${segmentsTRAIN} ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/segments

        else

            ${KALDI_INSTRUCTIONAL_PATH}/local/create_txt.pl \
                ${transcripts} \
                ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.train \
                    > ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/text

        fi
        
        # create `utt2spk` and `spk2utt`
        if [ "${segmented}" = true ]; then
    
            # create based on `segments` (in case `transcripts` doesn't exist)
            cat ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/segments | \
                perl -ane 'm:([^-]+)-([12AB][^-]*)-([0-9]+)-([0-9]+): || die "bad line $_"; print  "$1-$2-$3-$4 $1-$2\n"; ' \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/utt2spk
            ${KALDI_INSTRUCTIONAL_PATH}/utils/utt2spk_to_spk2utt.pl \
                <${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/utt2spk \
                >${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/spk2utt
    
        else
    
            # create based on `wav.scp`
            # (since `segments` doesn't exist and in case `transcripts` doesn't exist)
            cat ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/wav.scp | \
                awk '{printf("%s %s\n", $1, $1);}' > ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/utt2spk
            ${KALDI_INSTRUCTIONAL_PATH}/utils/utt2spk_to_spk2utt.pl \
                <${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/utt2spk \
                >${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/spk2utt
    
        fi

    # if dealing with test dir
    elif [[ ${item} == ${test_dir} ]]; then

        # make a data/test_dir directory
        mkdir -p ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir

        # make a two-column list of test utterance ids and their paths
        ${KALDI_INSTRUCTIONAL_PATH}/local/create_wav_scp.pl \
            ${test_dir} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.test \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/wav.scp

        # create separate transcription file
        # <utteranceID> <text>
        if [ "${segmented}" = true ]; then

            python ${KALDI_INSTRUCTIONAL_PATH}/local/create_txt_segments.py \
                ${transcripts} \
                ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.test \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/text
            cp ${segmentsTEST} data/test_dir/segments

        else

            ${KALDI_INSTRUCTIONAL_PATH}/local/create_txt.pl \
                    ${transcripts} \
                    ${KALDI_INSTRUCTIONAL_PATH}/data/local/waves.test \
                    > ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/text

        fi

        # create `utt2spk` and `spk2utt`
        if [ "${segmented}" = true ]; then
    
            # create based on `segments` (in case `transcripts` doesn't exist)
            cat ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/segments | \
                perl -ane 'm:([^-]+)-([12AB][^-]*)-([0-9]+)-([0-9]+): || die "bad line $_"; print  "$1-$2-$3-$4 $1-$2\n"; ' \
                > ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/utt2spk
            ${KALDI_INSTRUCTIONAL_PATH}/utils/utt2spk_to_spk2utt.pl \
                <${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/utt2spk \
                >${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/spk2utt
    
        else
    
            # create based on `wav.scp`
            # (since `segments` doesn't exist and in case `transcripts` doesn't exist)
            cat ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/wav.scp | \
                awk '{printf("%s %s\n", $1, $1);}' > ${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/utt2spk
            ${KALDI_INSTRUCTIONAL_PATH}/utils/utt2spk_to_spk2utt.pl \
                <${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/utt2spk \
                >${KALDI_INSTRUCTIONAL_PATH}/data/test_dir/spk2utt
    
        fi
        
    fi
    
done

if [ ! -z "${language_model}" ]; then
    # copy language model file into data/local/
    # removing <unk> from all lines
    grep -v -E "<(u|U)" ${language_model} > ${KALDI_INSTRUCTIONAL_PATH}/data/local/lm_tg.arpa
fi

# make nextiva_recipes/data/local/dict
mkdir -p ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict

# the following three steps replace `/local/prepare_dict.sh`
# copy lexicon files into data/local/dict
cp ${lexicon} ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/lexicon.txt
#cp ${lexicon} ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/lexicon_words.txt

# remove SIL from phones if present and copy to data/local/dict
silence_phones_delimited=$(echo ${silence_phones// /|})
cat ${phones} | grep -v -E "${silence_phones_delimited}" > ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/nonsilence_phones.txt

# make list of silence phones
for phone in ${silence_phones}; do
    echo ${phone} >> ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/silence_phones.txt
done

# determine case of phones
first_line=`head -n1 ${phones}`
if [[ "${first_line}" =~ [A-Z] ]]; then
    upper=true
else
    upper=false
fi

# put only SIL in optional silence
if [ ${upper} = "true" ]; then
    echo "SIL" > ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/optional_silence.txt
else
    echo "sil" > ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/optional_silence.txt
fi
