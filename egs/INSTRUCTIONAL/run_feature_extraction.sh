#!/usr/bin/env bash

# This script generates MFCCs and cmvn statistics

# ARGUMENTS
# REQUIRED
# -c <path> = path to `.conf` file
# -n [no argument] = simply if training data is present
# -t [no argument] = simply if testing data is present
# Must have *at least* one of `-n` or `-t`
# OPTIONAL
# -j <int> = number of processors to use, default=2
# -q <string> = non-vanilla hyperparameters to `compute_cmvn_stats.sh`, in the form "--fake-dims 13:14"

# OUTPUTS
# Creates:
    # `mfcc/` directory for the `mfcc`s from training data
    # `exp/` for logs
    # `data/{train,test}dir/{feats,cmvn}.scp` which are required when running `run_train_phones.sh`

############################
##BEGIN parse params##
############################

# all params
all_params="\
    mfcc_config \
    train_data_present \
    test_data_present \
    num_processors \
    non_vanilla_compute_cmvn_stats_hyperparameters"

# parse parameter file
for param in ${all_params}; do
    param_name=${param}
    declare ${param}="$(python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 ${param_name})"
done

############################
##END parse params##
############################

# source file with path information
. ${KALDI_INSTRUCTIONAL_PATH}/path.sh

# update variables for train/test dir
train_dir=
test_dir=

if [ "${train_data_present}" = true ]; then
    train_dir=train_dir
fi

if [ "${test_data_present}" = true ]; then
    test_dir=test_dir
fi

printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

for dir in ${train_dir} ${test_dir}; do

    # run fix_data_dir just in case
#    utils/fix_data_dir.sh ${dir}

    # make mfccs
    ${KALDI_INSTRUCTIONAL_PATH}/steps/make_mfcc.sh --nj ${num_processors} \
        --mfcc-config ${mfcc_config} \
        ${KALDI_INSTRUCTIONAL_PATH}/data/${dir} \
        ${KALDI_INSTRUCTIONAL_PATH}/exp/make_mfcc/${dir} \
        ${KALDI_INSTRUCTIONAL_PATH}/mfcc \
        || (printf "\n####\n#### ERROR: make_mfcc.sh \n####\n\n" && exit 1);

    # compute cmvn stats
    ${KALDI_INSTRUCTIONAL_PATH}/steps/compute_cmvn_stats.sh \
        ${non_vanilla_compute_cmvn_stats_hyperparameters} \
        ${KALDI_INSTRUCTIONAL_PATH}/data/${dir} \
        ${KALDI_INSTRUCTIONAL_PATH}/exp/make_mfcc/${dir} \
        ${KALDI_INSTRUCTIONAL_PATH}/mfcc \
        || (printf "\n####\n#### ERROR: compute_cmvn_stats.sh \n####\n\n" && exit 1);
done

printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > mfcc/kaldi_config_args.json