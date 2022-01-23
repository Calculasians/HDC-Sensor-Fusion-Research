import pandas as pd
import utils

class SpatialEncoder:

	dimension = 2000

	def __init__(self, num_channel, use_final_hv):
		self.num_channel = num_channel
		self.use_final_hv = use_final_hv
		self.reset()

	# input_B     : List of Series/List of hypervectors coming from the projection memory
	# input_D     : List of Series/List of hypervectors coming from the item memory
	# bind_input  : List of Series/List that contains binded hypervectors for all the channels
	# output_R    : A Series which represents the output hypervector of the Spatial Encoder

	# Binds the hypervectors coming from the projection vector and the item memory and collect the result
	# Inputs:
	# - i 			: index (channel number) of the input hypervectors 
	# - input_Bi	: a Series/List that represents the hypervector coming out of the projection memory
	# - input_Di	: a Series/List that represents the hypervector coming out of the item memory
	def bind(self, i, input_Bi, input_Di):
		self.input_B[i]    = input_Bi
		self.input_D[i]    = input_Di
		self.bind_input[i] = utils.bind([self.input_B[i], self.input_D[i]])

	# Only call this function after all the channels have received and binded their input hypervectors
	# This is true only after the bind function is called num_channel times
	def bundle(self):
		if self.use_final_hv:
			self.bind_input[self.num_channel] = utils.bind([self.bind_input[self.num_channel-1], self.bind_input[1]])
		self.output_R = pd.Series(utils.bundle(self.bind_input))

	def reset(self):
		self.input_B     = [None] * self.num_channel
		self.input_D     = [None] * self.num_channel

		if self.use_final_hv:
			self.bind_input  = [None] * (self.num_channel + 1)
		else:
			self.bind_input  = [None] * self.num_channel
		self.output_R    = None
