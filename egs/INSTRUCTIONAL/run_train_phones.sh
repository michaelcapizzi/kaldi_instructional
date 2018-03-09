#!/usr/bin/env bash

# This script trains `monophone`s and `triphone`s for given `mfcc`s

#ARGUMENTS
## REQUIRED
# -i <string> = type of phone training to do: "mono", "deltas", "lda_mllt", or "sat"

## OPTIONAL
# -j <int> = number of processors to use, default=2
# -l <int> = number of leaves, default=2000
# -g <int> = total number of Gaussians, default=10000
# -p <int> = scale to reduce original audio file size to speed up `train_mono.sh`, example `-p 4` = use 1/4 original files
# -q <string> = non-vanilla hyperparameters to `train_mono.sh`, in the form "--num_iters 50"
# -r <string> = non-vanilla hyperparameters to `align_si.sh` for monophones, in the form "--beam 20"
# -s <string> = non-vanilla hyperparameters to `train_deltas.sh` of deltas + deltas-deltas in the form "--num_iters 50"
# -t <string> = non-vanilla hyperparameters to `align_si.sh` for deltas + delta-deltas in the form "--beam 20"
# -w <string> = non-vanilla hyperparameters to `train_lda_mllt.sh` for LDA-MLLT, in the form "--beam 20"
# -x <string> = non-vanilla hyperparameters to `align_fmllr.sh` for LDA-MLLT, in the form "--beam 20"
# -y <string> = non-vanilla hyperparameters to `train_sat.sh` for SAT, in the form "--beam 20"
# -z <string> = non-vanilla hyperparameters to `align_fmllr.sh` for SAT, in the form "--beam 20"

# OUTPUTS
# Creates `exp/monophones/`, `exp/monophones_aligned/` and `exp/triphones/` and `exp/triphones_aligned/`
# and, depending on training type, `exp/{triphones_2, triphones_2_aligned, triphones_lda, triphones_lda_aligned, triphones_sat, and triphones_sat_aligned}
# subdirectories for trained phones and logs

############################
##BEGIN parse params##
############################

# all params
all_params="\
    training_type \
    num_gaussians \
    num_leaves \
    data_reduction_rate \
    num_processors \
    non_vanilla_train_mono_hyperparameters \
    non_vanilla_mono_align_hyperparameters \
    non_vanilla_train_deltas_hyperparameters \
    non_vanilla_deltas_align_hyperparameters \
    non_vanilla_train_lda_mllt_hyperparameters \
    non_vanilla_lda_align_fmllr_hyperparameters \
    non_vanilla_train_sat_hyperparameters \
    non_vanilla_sat_align_hyperparameters"

# parse parameter file
for param in ${all_params}; do
    param_name=${param}
    declare ${param}="$(python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 ${param_name})"
done

############################
##END parse params##
############################

# reduce data size (if needed)
if [ ! -z ${data_reduction_rate} ]; then
    total_files=$(cat ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir/utt2spk | wc -l)
    reduce_n=$(expr ${total_files} \/ ${data_reduction_rate})
fi

# determine type of training
if [ ${training_type} == "mono" ]; then
    echo "flat start monophone training"
elif [ ${training_type} == "deltas" ]; then
    echo "single round of delta + delta-delta training"
elif [ ${training_type} == "lda_mllt" ]; then
    echo "LDA-MLLT training"
elif [ ${training_type} == "sat" ]; then
    echo "SAT training"
else
    echo "training type options:"
    echo "\"mono\" = flat start monophone training, aligned"
    echo "\"deltas\" = single round of delta + delta-delta triphones, aligned"
    echo "\"lda_mllt\" = LDA-MLLT triphones aligned with FMLLR"
    echo "\"sat\" = SAT triphones aligned with FMLLR"
    exit 1
fi

printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

# Flat start and monophone training
# This script applies cepstral mean normalization (per speaker)

if [ ! -d "exp/monophones" ]; then

    if [ ! -z "${reduce_n}" ]; then

        # get sample of training audio
        ${KALDI_INSTRUCTIONAL_PATH}/utils/subset_data_dir.sh \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${reduce_n} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_${reduce_n}_dir

        # removed --cmd in original `run`, sticking with default
        ${KALDI_INSTRUCTIONAL_PATH}/steps/train_mono.sh \
            ${non_vanilla_train_mono_hyperparameters} \
            --nj ${num_processors} \
            --totgauss ${num_gaussians} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_${reduce_n}_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/monophones \
            || (printf "\n####\n#### ERROR: train_mono.sh \n####\n\n" && exit 1);

    else

        # removed --cmd and --totgauss options in original `run`, sticking with default
        ${KALDI_INSTRUCTIONAL_PATH}/steps/train_mono.sh \
            ${non_vanilla_train_mono_hyperparameters} \
            --nj ${num_processors} \
            --totgauss ${num_gaussians} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/monophones \
            || (printf "\n####\n#### ERROR: train_mono.sh \n####\n\n" && exit 1);

    fi

    printf "Timestamp in HH:MM:SS (24 hour format)\n";
    date +%T
    printf "\n"

    python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/monophones/kaldi_config_args.json

fi


if [ ! -d "exp/monophones_aligned" ]; then

    # align monophones with data

    # removed --boost_silence=1.25 option in original `run`, sticking with default
    ${KALDI_INSTRUCTIONAL_PATH}/steps/align_si.sh \
        ${non_vanilla_mono_align_hyperparameters} \
        --nj ${num_processors} \
        ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
        ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
        ${KALDI_INSTRUCTIONAL_PATH}/exp/monophones \
        ${KALDI_INSTRUCTIONAL_PATH}/exp/monophones_aligned \
        || (printf "\n####\n#### ERROR: align_si.sh of monophones\n####\n\n" && exit 1);

    printf "Timestamp in HH:MM:SS (24 hour format)\n";
    date +%T
    printf "\n"

    python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/monophones_aligned/kaldi_config_args.json

fi


if [[ ${training_type} != "mono" ]]; then

    if [ ! -d "exp/triphones" ]; then

        # train delta + delta-delta
        # removed --cmd in original `run`, sticking with default
        ${KALDI_INSTRUCTIONAL_PATH}/steps/train_deltas.sh \
            ${non_vanilla_train_deltas_hyperparameters} \
            ${num_leaves} \
            ${num_gaussians} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/monophones_aligned \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones \
            || (printf "\n####\n#### ERROR: train_deltas.sh \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones/kaldi_config_args.json

    fi


    if [ ! -d "exp/triphones_aligned" ]; then

        # align
        ${KALDI_INSTRUCTIONAL_PATH}/steps/align_si.sh \
            ${non_vanilla_deltas_align_hyperparameters} \
            --nj ${num_processors} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_aligned \
            || (printf "\n####\n#### ERROR: align_si.sh of triphones \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones_aligned/kaldi_config_args.json

    fi

fi

# set increased values for LDA-MLLT stage
# 100% more than in delta+delta-delta stage
lda_leaves=$(expr ${num_leaves} \* 2)
# 100% more than in delta+delta-delta stage
lda_gaussians=$(expr ${num_gaussians} \* 2)

if [[ ${training_type} != "mono" ]] && [[ ${training_type} != "deltas" ]]; then

    if [ ! -d "exp/triphones_lda" ]; then


        # train LDA-MLLT
        ${KALDI_INSTRUCTIONAL_PATH}/steps/train_lda_mllt.sh \
            ${non_vanilla_train_lda_mllt_hyperparameters} \
            ${lda_leaves} \
            ${lda_gaussians} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_aligned \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_lda \
            || (printf "\n####\n#### ERROR: train_lda_mllt.sh \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones_lda/kaldi_config_args.json

    fi


    if [ ! -d "exp/triphones_lda_aligned" ]; then

        # align with FMLLR
        ${KALDI_INSTRUCTIONAL_PATH}/steps/align_fmllr.sh \
            --nj ${num_processors} \
            ${non_vanilla_lda_align_fmllr_hyperparameters} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_lda \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_lda_aligned \
            || (printf "\n####\n#### ERROR: align_fmllr.sh \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones_lda_aligned/kaldi_config_args.json

    fi

fi

# set increased values for SAT stage
# 20% more than LDA-MLLT stage
sat_leaves=$(expr ${lda_leaves} \/ 5 + ${lda_leaves})
# 100% more than LDA-MLLT stage
sat_gaussians=$(expr ${lda_gaussians} + ${lda_gaussians})

if [ ${training_type} == "sat" ]; then

    if [ ! -d "exp/triphones_sat" ]; then

        # train SAT
        ${KALDI_INSTRUCTIONAL_PATH}/steps/train_sat.sh \
            ${non_vanilla_train_sat_hyperparameters} \
            ${sat_leaves} \
            ${sat_gaussians} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_lda_aligned \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_sat \
            || (printf "\n####\n#### ERROR: train_lda_mllt.sh \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones_sat/kaldi_config_args.json

    fi


    if [ ! -d "exp/triphones_sat_aligned" ]; then

        # align with FMLLR
        ${KALDI_INSTRUCTIONAL_PATH}/steps/align_fmllr.sh \
            --nj ${num_processors} \
            ${non_vanilla_sat_align_hyperparameters} \
            ${KALDI_INSTRUCTIONAL_PATH}/data/train_dir \
            ${KALDI_INSTRUCTIONAL_PATH}/data/lang \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_sat \
            ${KALDI_INSTRUCTIONAL_PATH}/exp/triphones_sat_aligned \
            || (printf "\n####\n#### ERROR: train_lda_mllt.sh \n####\n\n" && exit 1);

        printf "Timestamp in HH:MM:SS (24 hour format)\n";
        date +%T
        printf "\n"

        python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > exp/triphones_sat_aligned/kaldi_config_args.json

    fi

fi
