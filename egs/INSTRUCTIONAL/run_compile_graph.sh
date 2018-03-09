#!/usr/bin/env bash

# This script creates a fully expanded decoding graph (HCLG) that represents
# the language-model, pronunciation dictionary (lexicon), context-dependency,
# and HMM structure in our model.  The output is a Finite State Transducer
# that has word-ids on the output, and pdf-ids on the input (these are indexes
# that resolve to Gaussian Mixture Models).

# REQUIRE ARGUMENT
# -t <path> = full path to folder containing model to use

# OPTIONAL ARGUMENTS
# -q <string> = non-vanilla hyperparameters to `mkgraph.sh`, in the form "--loopscale .4"

# OUTPUTS
# Creates a new subdirectory /graph in the folder of model being used 
# and `data/lang_test_tg/tmp/` for housing files
# related to the building of the graph
# *NOTE*: The following files are the only ones required for `run_predict.sh`:
# (1) `graph/HCLG.fst`
# (2) `graph/words.txt`
# (3) `final.mdl`
# (4) `data/lang/phones/align_lexicon.int`
# (5) `final.mat` *if `lda_mllt` was run
# If the optional arguments are used, the following files will be saved
# to a secondary location.  These files are needed for `run_predict.sh` and `run_predict_wrapped.sh`

############################
##BEGIN parse params##
############################

# all params
all_params="\
    model_dir \
    non_vanilla_mkgraph_hyperparameters"

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

${KALDI_INSTRUCTIONAL_PATH}/utils/mkgraph.sh \
    ${non_vanilla_mkgraph_hyperparameters} \
    ${KALDI_INSTRUCTIONAL_PATH}/data/lang_test_tg \
    ${model_dir} \
    ${model_dir}/graph \
    || (printf "\n####\n#### ERROR: mkgraph.sh \n####\n\n" && exit 1);


printf "Timestamp in HH:MM:SS (24 hour format)\n";
date +%T
printf "\n"

python ${KALDI_INSTRUCTIONAL_PATH}/utils/parse_config.py $1 $0 > ${model_dir}/graph/kaldi_config_args.json

