import pandas as pd
import utils

class TemporalEncoder:

	dimension = 2000
	ngram_size = 3

	def __init__(self):
		self.reset()

	# ngram    : a List that contains permuted hypervectors which represent the history
	# output_T : a Series which represents the output hypervector of the Temporal Encoder

	# Binds the input hypervector with the permuted version of those contained in the ngram (history)
	# Input:
	# - input_R  : a Series/List that represents the hypervector coming out of the Spatial Encoder
	def capture(self, input_R):
		if (type(input_R) == pd.Series):
			input_R = input_R.tolist()

		self.output_T = pd.Series(utils.bind(self.ngram + [input_R]))

		i = self.ngram_size-2
		while (i > 0):
			self.ngram[i] = utils.permute(self.ngram[i-1])
			i -= 1
		self.ngram[0] = utils.permute(input_R)

	def reset(self):
		self.ngram    = [[0] * self.dimension] * (self.ngram_size - 1)
		self.output_T = None
