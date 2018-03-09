import sys

# TODO parameterize for all transcript types

# Reads in a `transcript` file and a list of `.wav` filenames,
# looks up the transcripts that relate to the list of .wav filenames,
# outputs a smaller `transcript` file with only transcripts relevant to
# the list of .wav filenames.

# NOTE: Assumes audio file name is *present* in the utteranceIDs of segments
# e.g. AimeeMullins_1998.wav --> AimeeMullins_1998-0002313-0002460
# NOTE: Currently designed to handle TEDLIUM transcript conventions

# sys.argv[1]= full path to `transcripts`
# sys.argv[2]= full path to `waves.[train/test]` file


# Read in `transcripts` file
f_trans = open(sys.argv[1], "r")

# Reads in `waves.[train/test]` file
f_waves = open(sys.argv[2], "r")

# Build dictionary from transcripts file
all_trans = []
for line in f_trans:
    line_split = line.split(" ")
    trans_id = line_split[0]
    trans = line_split[1:]
    all_trans.append((trans_id, line.rstrip()))
f_trans.close()

for wav in f_waves:
    # get the utteranceID
    wav_id = wav.split(".")[0]
    # find matching segments
    for item in all_trans:
        if wav_id in item[0]:
            # print the line to stdout
            print(item[1])
            # remove from list (to speed up process)
            # all_trans.remove(item)
            # TODO the inclusion of this line was causing every other line to be skipped - why?
f_waves.close()


