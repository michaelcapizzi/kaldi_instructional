#!/bin/bash

# This script removes all files generated in `nextiva_recipes` after any step of the process.
# Ensures a clean state

rm -rf ${KALDI_INSTRUCTIONAL_PATH}/data/ \
    ${KALDI_INSTRUCTIONAL_PATH}/mfcc/ \
    ${KALDI_INSTRUCTIONAL_PATH}/exp/

