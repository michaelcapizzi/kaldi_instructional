import feature_viz as f
import numpy as np

UTT = "5789-70653-0004"

feats_dict = f.read_in_features(
    "/Users/mcapizzi/Github/kaldi_instructional/egs/mini_librispeech/s5/mfcc/raw_mfcc_train_clean_5.1.scp"
)

ali_dict = f.read_in_alignments(
    "/Users/mcapizzi/Github/kaldi_instructional/egs/mini_librispeech/s5/exp/mono/ali_for_viz"
)

utt_ = feats_dict[UTT]
ali_ = ali_dict[UTT]
phones_dict = f.get_grouped_phones_dict(feats_dict, ali_dict)
average_mfccs_dict = f.get_average_mfccs(phones_dict)
print("utterance {} has {} frames".format(UTT, f.get_num_frames(utt_)))

f.plot_frames(utt_[125:130], ali_[125:130], average_mfccs_dict)


## all average mfcss

# all_phones, all_average_mfccs = zip(*average_mfccs_dict.items())
# f.plot_frames(np.array(all_average_mfccs), list(all_phones))

