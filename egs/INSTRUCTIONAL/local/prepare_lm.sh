#!/bin/bash

purge_oov=false

while getopts "w:l:z" opt; do
    case ${opt} in
        w)
            words=${OPTARG}
            ;;
        l)
            language_model=${OPTARG}
            ;;
        z)
            purge_oov=true
            oov=${KALDI_INSTRUCTIONAL_PATH}/data/lang/arpa_oov.txt
            ;;
    esac
done

# sourcing the path
. ${KALDI_INSTRUCTIONAL_PATH}/path.sh

echo "Preparing language models for test"

for lm_suffix in tg; do
    test=${KALDI_INSTRUCTIONAL_PATH}/data/lang_test_${lm_suffix}
    
    rm -rf ${KALDI_INSTRUCTIONAL_PATH}/data/lang_test_${lm_suffix}
    cp -r ${KALDI_INSTRUCTIONAL_PATH}/data/lang ${KALDI_INSTRUCTIONAL_PATH}/data/lang_test_${lm_suffix}

    if [ "${purge_oov}" = true ]; then
        # generate OOV list
        ${KALDI_INSTRUCTIONAL_PATH}/utils/find_arpa_oovs.pl ${words} ${language_model} > ${oov}


        # build language model files
        cat ${language_model} | arpa2fst - | fstprint | \
            ${KALDI_INSTRUCTIONAL_PATH}/utils/remove_oovs.pl ${oov} | \
            ${KALDI_INSTRUCTIONAL_PATH}/utils/eps2disambig.pl | \
            ${KALDI_INSTRUCTIONAL_PATH}/utils/s2eps.pl | fstcompile --isymbols=$test/words.txt \
            --osymbols=$test/words.txt --keep_isymbols=false --keep_osymbols=false \
            | fstrmepsilon | fstarcsort --sort_type=ilabel > $test/G.fst
        fstisstochastic $test/G.fst

    else

        # build language models
        cat ${language_model} | arpa2fst - | fstprint | \
            ${KALDI_INSTRUCTIONAL_PATH}/utils/eps2disambig.pl | \
            ${KALDI_INSTRUCTIONAL_PATH}/utils/s2eps.pl | fstcompile --isymbols=$test/words.txt \
            --osymbols=$test/words.txt --keep_isymbols=false --keep_osymbols=false \
            | fstrmepsilon | fstarcsort --sort_type=ilabel > $test/G.fst
        fstisstochastic $test/G.fst

    fi
      
    # The output is like:
    # 9.14233e-05 -0.259833
    # we do expect the first of these 2 numbers to be close to zero (the second
    # is nonzero because the backoff weights make the states sum to >1).
    # Because of the <s> fiasco for these particular LMs the first number is not
    # as close to zero as it could be.

    # Everything below is only for diagnostic.
    # Checking that G has no cycles with empty words on them (e.g. <s>, </s>);
    # this might cause determinization failure of CLG.
    # #0 is treated as an empty word.
    mkdir -p tmpdir.g
    awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} END{print "0 0 #0 #0"; print "0";}' \
        < ${KALDI_INSTRUCTIONAL_PATH}/data/local/dict/lexicon.txt  >tmpdir.g/select_empty.fst.txt
    fstcompile --isymbols=$test/words.txt --osymbols=$test/words.txt \
        tmpdir.g/select_empty.fst.txt | fstarcsort --sort_type=olabel | \
        fstcompose - $test/G.fst > tmpdir.g/empty_words.fst
    fstinfo tmpdir.g/empty_words.fst | grep cyclic | grep -w 'y' && 
    echo "Language model has cycles with empty words" && exit 1
    rm -r tmpdir.g

done

echo "Succeeded in formatting data."
