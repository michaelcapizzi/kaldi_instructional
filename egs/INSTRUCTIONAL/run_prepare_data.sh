#!/bin/bash

# This scripts prepares the data (audio, transcripts, phones list, language model) for later use
# *Note:* This script can take training and/or testing audio

# ARGUMENTS
# REQUIRED
# -r <path> = full path to `transcripts` file
# NOTE: if flag *not* present, assumes segmented transcript files
# -x <path> = full path to `lexicon.txt` file
# -p <path> = full path to `phones.txt` file
# -s <string> = string representing a list of phones representing silence, minimally: `SIL`
# -l <path> = full path to `language_model` file
    # can be OMITTED if building for TIDIGITS
# -z [no argument] = if present, automatically purge OOV from language model
# -n <path> = full path of training data
# -t <path> = full path of testing data
    # Must have *at least* one of `-n` or `-t`
# OPTIONAL
# -u [no argument] = if present, using UNsegmented transcript file
# -g <path> = full path to TRAIN segments file  **needed if *not -u*
# -h <path> = full path to TEST segments file   **needed if *not -u*
# -q <string> = non-vanilla hyperparameters to `prepare_lang.sh`, in the form "--sil-prob .1"

# OUTPUTS
# Creates `data/` directory
# This includes subdirectories: `data/lang/`, `data/lang_test_tg/`, `data/local/`, and
# `data/train_dir` and/or `data/test_dir/`

############################
##BEGIN parse params##
############################

# all params
all_params="\
    transcripts \
    lexicon \
    phones \
    language_model \
    purge_oov \
    train_dir \
    test_dir \
    unsegmented \
    segments_train \
    segments_test \
    silence_phones \
    non_vanilla_prepare_lang_hyperparameters"

# parse parameter file
for param in ${all_params}; do
    param_name=${param}
    declare ${param}="$(python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 ${param_name})"
done

############################
##END parse params##
############################

printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

# run local/prepare_data.sh
if [[ ${train_dir} != "" && ${test_dir} != "" ]]; then
    if [ "${unsegmented}" = false ]; then
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -n ${train_dir} \
            -t ${test_dir} \
            -g ${segments_train} \
            -h ${segments_test} \
            || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
        ${KALDI_INSTRUCTIONAL_PATH}/utils/fix_data_dir.sh data/train_dir \
            || (printf "\n####\n#### ERROR: fix_data_dir.sh\n####\n\n" && exit 1);
        ${KALDI_INSTRUCTIONAL_PATH}/utils/fix_data_dir.sh data/test_dir \
            || (printf "\n####\n#### ERROR: fix_data_dir.sh\n####\n\n" && exit 1);
    else
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -n ${train_dir} \
            -t ${test_dir} \
            -u \
        || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
    fi
elif [[ ${train_dir} != "" && ${test_dir} == "" ]]; then
    if [ "${unsegmented}" = false ]; then
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -n ${train_dir} \
            -g ${segments_train} \
            || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
        ${KALDI_INSTRUCTIONAL_PATH}/utils/fix_data_dir.sh data/train_dir \
            || (printf "\n####\n#### ERROR: fix_data_dir.sh\n####\n\n" && exit 1);
    else
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -n ${train_dir} \
            -u \
            || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
    fi
elif [[ ${test_dir} != "" && ${train_dir} == "" ]]; then
    if [ "${unsegmented}" = false ]; then
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -t ${test_dir} \
            -h ${segments_test} \
            || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
        ${KALDI_INSTRUCTIONAL_PATH}/utils/fix_data_dir.sh data/test_dir \
            || (printf "\n####\n#### ERROR: fix_data_dir.sh\n####\n\n" && exit 1);
    else
        ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_data.sh \
            -r ${transcripts} \
            -x ${lexicon} \
            -p ${phones} \
            -s "${silence_phones}" \
            -l "${language_model}" \
            -t ${test_dir} \
            -u \
            || (printf "\n####\n#### ERROR: prepare_data.sh\n####\n\n" && exit 1);
    fi
else
    printf "\n####\n#### ERROR: Neither training nor testing data provided\n####\n\n" && exit 1
fi
# run utils/prepare_lang.sh
${KALDI_INSTRUCTIONAL_PATH}/utils/prepare_lang.sh \
    ${non_vanilla_prepare_lang_hyperparameters} \
    --position-dependent-phones true \
    ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict \
    "<unk>" \
    ${KALDI_INSTRUCTIONAL_PATH}/data/local/lang \
    ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
    || (printf "\n####\n#### ERROR: prepare_lang.sh\n####\n\n" && exit 1);

# run local/prepare_lm.sh
# creates `data/lang_test_tg
if [ "${purge_oov}" = true ]; then
    ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_lm.sh \
        -w ${KALDI_INSTRUCTIONAL_PATH}/data/lang/words.txt \
        -l ${language_model} \
        -z \
        || (printf "\n####\n#### ERROR: prepare_lm.sh\n####\n\n" && exit 1);
else
    ${KALDI_INSTRUCTIONAL_PATH}/local/prepare_lm.sh \
        -l ${language_model} \
        || (printf "\n####\n#### ERROR: prepare_lm.sh\n####\n\n" && exit 1);
fi

printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > data/kaldi_config_args.json