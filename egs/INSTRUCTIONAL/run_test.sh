#!/usr/bin/env bash

# This script will generate predicted transcriptions for test data found in `data/test_dir`

# ARGUMENTS
### REQUIRED
# -g <path> = full path to graph directory, default=`exp/triphones/graph/`
# -t <path> = full path to test data dir, default=`data/test_dir/`
# -d <path> = full path to experiment directory; parent directory must contain final.mdl
### OPTIONAL
# -j <int> = number of processors to use, default=2
# -w <int> = language model weight to use when returning transcription, default = `10`
# -b <float> = size of beam during graph traversal
# -m <int> = maximum number of active nodes in graph
# -q <string> = non-vanilla hyperparameters to `decode.sh` or `decode_fmllr.sh`, in the form "--beam 20"
# -z <string> = full path to experiment folder to save all important data

# OUTPUTS
# Creates one or more subdirectories in `data/test_dir/split*/` equal to setting of `-j` where
# files are copied for each parallel process
# Creates a `decode_test_dir` directory, housing logs and all output files

############################
##BEGIN parse params##
############################

# all params
all_params="\
    graph_dir \
    data_test_dir \
    decode_dir \
    num_processors \
    weight \
    beam \
    max_active \
    non_vanilla_decode_hyperparameters \
    save_to"

# parse parameter file
for param in ${all_params}; do
    param_name=${param}
    declare ${param}="$(python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 ${param_name})"
done

############################
##END parse params##
############################

#Print timestamp in HH:MM:SS (24 hour format)
printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

decode_srcdir=$(dirname ${decode_dir})
model=${decode_srcdir}/final.mdl

# identify language model weights to use
# +/-2 $weight
weight_lower=$(expr ${weight} - 2)
weight_upper=$(expr ${weight} + 2)

# get start time
start=$(date +%s)

# decode
${KALDI_INSTRUCTIONAL_PATH}/steps/decode.sh \
    ${non_vanilla_decode_hyperparameters} \
    --model ${model} \
    --nj ${num_processors} \
    --beam ${beam} \
    --max_active ${max_active} \
    --scoring-opts "--min-lmwt ${weight_lower} --max-lmwt ${weight_upper}" \
    ${graph_dir} \
    ${data_test_dir} \
    ${decode_dir} \
    || (printf "\n####\n#### ERROR: decode.sh \n####\n\n" && exit 1);

# get end time
end=$(date +%s)
# get elapsed time
elapsed=$(expr ${end} - ${start})
# convert to minutes:seconds
minutes=$(expr ${elapsed} \/ 60)
seconds=$(expr ${elapsed} - ${minutes} \* 60)

# analyze lattices
for lmwt in $(seq ${weight_lower} ${weight_upper}); do
    # convert lmwt -> acwt
    acwt=$(awk "BEGIN {printf \"%.2f\",1.0/${lmwt}}")
    ${KALDI_INSTRUCTIONAL_PATH}/steps/diagnostic/analyze_lats.sh \
        --acwt ${acwt} \
        ${graph_dir} \
        ${decode_dir}
done

echo
printf "Time to decode and score in MM:SS\n";
# save decoding time to file
echo "${minutes}:${seconds}" | tee ${decode_dir}/runtime
echo

python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > ${decode_dir}/kaldi_config_args.json

if [ ! -z "${save_to}" ]; then

    mkdir -p ${save_to}

    # saves transcripts (only for one run ==> $weight)
    ${KALDI_INSTRUCTIONAL_PATH}/utils/int2sym.pl -f 2- \
        ${graph_dir}/words.txt ${decode_dir}/scoring/${weight}.tra \
        > ${save_to}/predicted_transcripts_${weight}.txt \
        || (printf "\n####\n#### ERROR: int2sym.pl\n####\n\n" && exit 1);

    # saves WER and SER results for all five runs (+/- 2 $weight)
    wers=$(grep WER ${decode_dir}/wer_*)
    sers=$(grep SER ${decode_dir}/wer_*)

    printf '%s\n' "${wers[@]}" > ${save_to}/results.txt
    echo >> ${save_to}/results.txt
    printf '%s\n' "${sers[@]}" >> ${save_to}/results.txt

    # copy entire decode_dir to save_to
    cp -r ${decode_dir} ${save_to}

    # display results
    cat ${save_to}/results.txt

else

    # outputs transcripts (only for one run ==> $weight)
    ${KALDI_INSTRUCTIONAL_PATH}/utils/int2sym.pl -f 2- \
        ${graph_dir}/words.txt ${decode_dir}/scoring/${weight}.tra \
        || (printf "\n####\n#### ERROR: int2sym.pl\n####\n\n" && exit 1);

    # saves WER and SER results for all five runs (+/- 2 $weight)
    wers=$(grep WER ${decode_dir}/wer_*)
    sers=$(grep SER ${decode_dir}/wer_*)

    # display results
    echo ${wers}
    echo
    echo ${sers}

fi


