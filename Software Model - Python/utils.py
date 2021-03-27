import pandas as pd
import math

# input_hvs : list of Series/list
# output    : list
def bundle(input_hvs):
	accumulator = [0] * len(input_hvs[0])
	for i in range(len(input_hvs)):
		accumulator = [sum(x) for x in zip(accumulator, input_hvs[i])]
	return [1 if (x > (len(input_hvs) // 2)) else 0 for x in accumulator]

# input_hvs : list of Series/list
# output    : list
def bind(input_hvs):
	output = [0] * len(input_hvs[0])
	for i in range(len(input_hvs)):
		output = [(lambda x: x[0] ^ x[1])(x) for x in zip(output, input_hvs[i])]
	return output

# input_hvs : list of Series/list
# output    : list
def permute(input_hv):
	if (type(input_hv) == pd.Series):
		input_hv = input_hv.tolist()
	return [0] + input_hv[0:len(input_hv)-1]

# input_labels : Series/list
# output       : label
def classify(input_labels):
	return 1 if (sum(input_labels) > (len(input_labels) // 2)) else 0

# hv1    : Series
# hv2    : Series
# output : int
def hamming(hv1, hv2):
	if (len(hv1) != len(hv2)):
		return math.inf
	return sum(hv1 ^ hv2)

def hamming_df(df1, df2):
	total = 0
	if (len(df1) != len(df2) or len(df1.columns) != len(df2.columns)):
		return math.inf
	for i in range(len(df1)):
		for j in range(len(df1.columns)):
			if (df1.iloc[i,j] != df2.iloc[i,j]):
				total += 1
	return total

def gen_next_hv_rule_90(input_hv):
	if (type(input_hv) == pd.Series):
		input_hv = input_hv.tolist()
	hv_right = [0] + input_hv[0:len(input_hv)-1]
	hv_left  = input_hv[1:len(input_hv)] + [0]
	return bind([hv_right, hv_left])

def gen_next_hv_folded_rule_90(input_hv, num_folds):
	fold_width = len(input_hv) // num_folds
	if (type(input_hv) == pd.Series):
		input_hv = input_hv.tolist()
	sliced_input_hv = [input_hv[fold_width*i:fold_width*(i+1)] for i in range(num_folds)]
	sliced_results = []
	for s in sliced_input_hv:
		sliced_results.append(gen_next_hv_rule_90(s))
	return [item for sublist in sliced_results for item in sublist]
