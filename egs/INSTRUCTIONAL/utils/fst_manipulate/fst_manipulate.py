import pywrapfst as openfst
import re
from math import exp


def write_wrapper(fst_, path_out):
	"""
	Wraps the native `.draw()` method from `pywrapfst`,
	but edits the `.dot` file in place to be in portrait mode for easier viewing in notebook
	"""
	# write out
	fst_.draw(path_out)
	# read in
	dot_in = open(path_out, "r").read()
	# edit orientation
	dot_out = re.sub(r'Landscape', 'Portrait', dot_in)
	with open(path_out, "w") as f:
		f.write(dot_out)


def lookup_word(word, sym_table):
	"""
	Gets the index for a word from an existing symbol table
	:param word: <str> to lookup
	:param sym_table: symbol table from existing fst
						existing_fst.input_symbols()
	:return: <int>
	"""
	try:
		return sym_table.find(word)
	except:
		return sym_table.find("<unk>")


def lookup_idx(idx, sym_table):
	"""
	Gets the word for an index in an existing symbol table
	:param idx: <int> to lookup
	:return: <str>
	"""
	return sym_table.find(idx)


def sequence_to_fst(seq_string, lm_fst):
	"""
	Builds an `fst` to represent a test sentence
	:param seq_string: <str> of the sequence
	:param lm_fst: <openfst.Fst> of the language model
	:return: <openfst.Fst> representing the sequence
	"""
	# initialize the fst
	sentence_fst = openfst.Fst()
	# set SymbolTables from lm fst
	sentence_fst.set_input_symbols(lm_fst.input_symbols().copy())
	sentence_fst.set_output_symbols(lm_fst.output_symbols().copy())

	# symbol table to use for lookup
	lookup_table = lm_fst.input_symbols()

	# begin buildling fst
	states = {}
	# add start state
	states["start"] = sentence_fst.add_state()
	sentence_fst.set_start(states["start"])

	# convert sequence <str> to <list> of indexes
	#  add <s>
	sentence_idxs = [lookup_word("<s>", lookup_table)]
	# add words in sequence
	sentence_idxs.extend([lookup_word(w, lookup_table) for w in seq_string.lower().split()])
	# add </s>
	sentence_idxs.append(lookup_word("</s>", lookup_table))

	# add nodes and arcs for sentence
	for i in range(len(sentence_idxs)):
		if i == len(sentence_idxs) - 1:
			break
		states[i] = sentence_fst.add_state()
		idx = sentence_idxs[i]
		if i == 0:
			# for start state
			sentence_fst.add_arc(
				states["start"],
				openfst.Arc(
					ilabel=idx,
					olabel=idx,
					weight=None,
					nextstate=states[0]
				)
			)
		elif i != len(sentence_idxs) - 1:
			sentence_fst.add_arc(
				states[i-1],
				openfst.Arc(
					ilabel=idx,
					olabel=idx,
					weight=None,
					nextstate=states[i]
				)
			)

	# add end state
	states["end"] = sentence_fst.add_state()
	sentence_fst.set_final(states["end"])
	# add final arc
	sentence_fst.add_arc(
		states[i-1],
		openfst.Arc(
			ilabel=sentence_idxs[-1],
			olabel=sentence_idxs[-1],
			weight=None,
			nextstate=states["end"]
		)
	)
	return sentence_fst



def check_sequence(seq_string, lm_fst):
	"""
	Checks a sequence against the language model representing the language model
	If the sequence is valid, it will return the composed FST
	If the sequence is not valid, will return None
	:param seq_string: <str> of the sequence
	:param lm_fst: <openfst.Fst> representing the language model
	:return: <openfst.Fst> or None
	"""
	seq_fst = sequence_to_fst(seq_string, lm_fst)
	return openfst.compose(lm_fst, seq_fst)


def get_shortest_path(fst_in):
	"""
	Generates the shortest path through an FST
	:param fst_in: <openfst.Fst>
	:return: <openfst.Fst> or None
	"""
	try:
		return openfst.shortestpath(fst_in)
	except:
		return None


def calculate_cost(fst_in):
	"""
	Calculates the cost of shortest path through an FST
	:param fst_in: <openfst.Fst>
	:return: <float>
	"""
	try:
		return float(openfst.shortestdistance(fst_in)[-1].to_string())
	except:
		return None


def convert_neg_log_e(neg_log_e):
	"""
	Removes a negative log, base e value from log space and takes its opposite
	In other words, converts -ln -> probability
	:param neg_log_e: the negative log, base e value to convert
	:return: <float>
	"""
	return float(exp(-neg_log_e))


def neg_log_e_to_log_10(neg_log_e):
	"""
	Converts a negative log likelihood in base e to log base 10
	:param neg_log_e: the negative log likehood to convert
	:return: <float>
	"""
	return -(neg_log_e/2.303)


def index_fst(fst_in):
	"""
	Analyzes an existing FST and finds:
		1. the node associated with each word
		2. the weight for each arc, to and from
	Also builds a node_2_word lookup
	:param fst_in: <openfst.Fst>
	:return: two <dict>s
	"""
	# initialize output dict and lookup
	word_dict = {}
	node_2_word = {}

	# symbol table to use for lookup
	lookup_table = fst_in.input_symbols()

	# traverse FST to get node IDs for each word and a lookup node_id -> word
	for state in fst_in.states():
		for arc in fst_in.arcs(state):
			state = arc.nextstate
			word = lookup_table.find(arc.ilabel)
			if word not in word_dict:
				word_dict[word] = {
					"state_id": state,
					 "weights_from": {},
					 "weights_to": {}
				}
			node_2_word[state] = word

	# traverse a second time to map all weights to and from
	for state in fst_in.states():
		# skip start state
		if state != fst_in.start():
			for arc in fst_in.arcs(state):
				from_state = state
				to_state = arc.nextstate
				from_word = node_2_word[from_state]
				to_word = node_2_word[to_state]
				word = lookup_table.find(arc.ilabel)
				weight = float(arc.weight.to_string())
				if from_word not in word_dict[word]["weights_from"]:
					word_dict[word]["weights_from"][from_word] = weight
				if to_word not in word_dict[from_word]["weights_to"]:
					word_dict[from_word]["weights_to"][to_word] = weight
 
	return word_dict, node_2_word


def add_arc(fst_in, from_word, to_word, weight):
	"""
	Adds an arc to a given FST
	Note: Despite returning an updated FST, this  method makes the changes
	**IN PLACE**, so you may want to make a copy of the original
	FST before updating the weights
	:param fst_in: <openfst.Fst> to modify
	:param from_word: <str>
	:param to_word: <str>
	:param weight: <float>
	:return: updated <openfst.Fst>
	"""
	# make a dict and node_2_word from index_fst()
	fst_dict, node_2_word = index_fst(fst_in)

	# get a lookup table
	lookup = fst_in.input_symbols()

	# set from state as idx
	from_state = fst_dict[from_word]["state_id"]

	# set to state as idx
	to_state = fst_dict[to_word]["state_id"]

	fst_in = fst_in.add_arc(
		from_state,
		openfst.Arc(
			lookup_word(to_word, lookup),
			lookup_word(to_word, lookup),
			openfst.Weight(
				"tropical",
				weight
			),
			to_state
		)
	)

	return fst_in


def remove_arc(fst_in, from_word, to_word):
	"""
	Removes an arc from a given FST
	Note: Despite returning an updated FST, this  method makes the changes
	**IN PLACE**, so you may want to make a copy of the original
	FST before updating the weights
	:param fst_in: <openfst.Fst> to modify
	:param from_word: <str>
	:param to_word: <str>
	:return: updated <openfst.Fst>

	"""
	# make a dict and node_2_word from index_fst()
	fst_dict, node_2_word = index_fst(fst_in)

	# get a lookup table
	lookup = fst_in.input_symbols()

	# set from state as idx
	from_state = fst_dict[from_word]["state_id"]

	# initialize list to hold all arcs to add
	arcs_to_keep = []

	# traverse all arcs and add to arcs_to_keep
	# except for one to remove
	for arc in fst_in.arcs(from_state):
		arc_from_word = node_2_word[from_state]
		arc_to_word = node_2_word[arc.nextstate]
		arc_weight = float(arc.weight.to_string())
		if not (arc_from_word == from_word and arc_to_word == to_word):
			dict_ = {
				"from_state": from_state,
				"to_state": arc.nextstate,
				"to_word_id": arc.ilabel,
				"weight": arc_weight
			}
			arcs_to_keep.append(dict_)
		else:
			print("removing: from_state:{} -> arc:{} -> to_state:{}".format(
				 from_state,
				 arc.ilabel,
				 arc.nextstate
				)
			 )

	# delete all arcs from from_state
	fst_intermediate = fst_in.delete_arcs(from_state)

	# add back arcs from arcs_to_keep
	for arc_dict in arcs_to_keep:
		fst_in = fst_in.add_arc(
			arc_dict["from_state"],
			openfst.Arc(
				arc_dict["to_word_id"],
				arc_dict["to_word_id"],
				openfst.Weight(
					"tropical",
					arc_dict["weight"]
				),
				arc_dict["to_state"]
			)
		)

	return fst_in



def update_weight(fst_in, from_word, to_word, new_weight):
	"""
	Updates a single weight on a given FST
	Note: Despite returning an updated FST, this method makes the changes
		  **IN PLACE**, so you may want to make a copy of the original
		  FST before updating weights
	:param fst_in: <openfst.Fst> to modify
	:param from_word: <str>
	:param to_word: <str>
	:param: new_weight: <float>
	:return: updated <openfst.Fst>
	"""
	# make a dict and node_2_word from index_fst()
	fst_dict, node_2_word = index_fst(fst_in)

	# get a lookup table
	lookup = fst_in.input_symbols()

	# set from state as idx
	from_state = fst_dict[from_word]["state_id"]

	# initialize list to hold all arcs to add
	arcs_to_keep = []

	# add updated arc
	arcs_to_keep.append(
		{
			"from_state": from_state,
			"to_state": fst_dict[to_word]["state_id"],
			"to_word_id": lookup_word(to_word, lookup),
			"weight": new_weight
		}
	)

	# traverse all arcs and add to arcs_to_keep
	# except for one to update
	for arc in fst_in.arcs(from_state):
		arc_from_word = node_2_word[from_state]
		arc_to_word = node_2_word[arc.nextstate]
		arc_weight = float(arc.weight.to_string())
		if not (arc_from_word == from_word and arc_to_word == to_word):
			dict_ = {
				"from_state": from_state,
				"to_state": arc.nextstate,
				"to_word_id": arc.ilabel,
				"weight": arc_weight
			}
			arcs_to_keep.append(dict_)

	# delete all arcs from from_state
	fst_intermediate = fst_in.delete_arcs(from_state)

	# add back arcs from arcs_to_keep
	for arc_dict in arcs_to_keep:
		print("adding: from_state:{} -> arc:{},weight:{} -> to_state:{}".format(
			 arc_dict["from_state"],
			 arc_dict["to_word_id"],
			 arc_dict["weight"],
			 arc_dict["to_state"]
			 )
		)
		fst_in = fst_in.add_arc(
			arc_dict["from_state"],
			openfst.Arc(
				arc_dict["to_word_id"],
				arc_dict["to_word_id"],
				openfst.Weight(
					"tropical",
					arc_dict["weight"]
				),
				arc_dict["to_state"]
			)
		)

	return fst_in
