import pandas as pd
import math
import utils

class Memory:

	def __init__(self, infile):
		self.data = pd.read_csv(infile, header=None).astype(int)

	def getCol(self, col):
		return self.data.iloc[:,col]

	def getRow(self, row):
		return self.data.iloc[row,:]

class FeatureMemory(Memory):

	def __init__(self, infile):
		temp         = pd.read_csv(infile, header=None)
		self.data    = temp.iloc[:,:214]
		self.label_a = temp.iloc[:,214]
		self.label_v = temp.iloc[:,215]
		self.reset()

	def normalize(self):
		for i in range(len(self.data.columns)):
			self.data.iloc[:,i] = self.data.iloc[:,i] - min(self.data.iloc[:,i])
			self.data.iloc[:,i] = self.data.iloc[:,i] / max(self.data.iloc[:,i])
			self.data.iloc[:,i] = self.data.iloc[:,i] - 0.4

	def downSample(self, interval):
		self.ds_data    = pd.DataFrame()
		self.ds_label_v = pd.Series()
		self.ds_label_a = pd.Series()

		for i in range (0, len(self.data), interval):
			self.ds_data    = self.ds_data.append(self.data.iloc[i,:], ignore_index=True)
			self.ds_label_v = self.ds_label_v.append(pd.Series(self.label_v[i]))
			self.ds_label_a = self.ds_label_a.append(pd.Series(self.label_a[i]))

		self.ds_label_v = self.ds_label_v.to_frame().reset_index().drop(labels='index', axis=1)
		self.ds_label_a = self.ds_label_a.to_frame().reset_index().drop(labels='index', axis=1)

    # feature values are between -0.4 to 0.6
    # Positive feature values = 1, else = 0
    # Label values are either 0 (zero), 1 (positive), 2 (negative)
    # Positive label values = 0, negative label values = 1
	def discretize(self):
		for i in range (len(self.ds_data)):
			for j in range (len(self.ds_data.columns)):
				self.ds_data.iloc[i][j] = 1 if self.ds_data.iloc[i][j] > 0 else (2 if self.ds_data.iloc[i][j] < 0 else 0)
			self.ds_label_v.iloc[i,0] = 0 if self.ds_label_v.iloc[i,0] == 1 else 1
			self.ds_label_a.iloc[i,0] = 0 if self.ds_label_a.iloc[i,0] == 1 else 1

	def genTrainData(self, learning_rate):
		# label_v_plus_index : row index where valence label = 0
		# label_v_min_index  : row index where valence label = 1
		label_v_plus_index = self.ds_label_v.index[self.ds_label_v[0] == 0].to_frame().reset_index().drop(labels='index', axis=1)
		label_v_min_index  = self.ds_label_v.index[self.ds_label_v[0] == 1].to_frame().reset_index().drop(labels='index', axis=1)

		# label_a_high_index : row index where arousal label = 0
		# label_a_low_index  : row index where arousal label = 1
		label_a_high_index = self.ds_label_a.index[self.ds_label_a[0] == 0].to_frame().reset_index().drop(labels='index', axis=1)
		label_a_low_index  = self.ds_label_a.index[self.ds_label_a[0] == 1].to_frame().reset_index().drop(labels='index', axis=1)

		# only get some percentage of the index for training data
		train_label_v_plus_index = label_v_plus_index.loc[0:math.floor(len(label_v_plus_index) * learning_rate-1)][0].tolist()
		train_label_v_min_index  = label_v_min_index.loc[0:math.floor(len(label_v_min_index) * learning_rate)-1][0].tolist()

		train_label_a_high_index = label_a_high_index.loc[0:math.floor(len(label_a_high_index) * learning_rate)-1][0].tolist()
		train_label_a_low_index  = label_a_low_index.loc[0:math.floor(len(label_a_low_index) * learning_rate)-1][0].tolist()

		# sampling data rows that corresponds to the labels
		self.train_data_v_plus = self.ds_data.loc[train_label_v_plus_index]
		self.train_data_v_min  = self.ds_data.loc[train_label_v_min_index]
		self.train_data_a_high = self.ds_data.loc[train_label_a_high_index]
		self.train_data_a_low  = self.ds_data.loc[train_label_a_low_index]

	def reset(self):
		self.ds_data    = None
		self.ds_label_v = None
		self.ds_label_a = None

		self.train_data_v_plus = None
		self.train_data_v_min  = None
		self.train_data_a_high = None
		self.train_data_a_low  = None

class ProjectionMemory:

	def __init__(self, proj_plus_infile, proj_neg_infile):
		self.proj_plus = Memory(proj_plus_infile)
		self.proj_neg  = Memory(proj_neg_infile)

class AssociativeMemory:

	dimension = 2000

	def __init__(self):
		self.reset()

	def accumulate(self, input_label, input_F):
		if (input_label == "v_plus"):
			self.accumulate_v_plus.append(input_F)
		elif (input_label == "v_min"):
			self.accumulate_v_min.append(input_F)
		elif (input_label == "a_high"):
			self.accumulate_a_high.append(input_F)
		elif (input_label == "a_low"):
			self.accumulate_a_low.append(input_F)
		else:
			print("Invalid input label given")

	def bundle(self, input_label):
		if (input_label == "v_plus"):
			self.prototype_v_plus = pd.Series(data=utils.bundle(self.accumulate_v_plus))
		elif (input_label == "v_min"):
			self.prototype_v_min  = pd.Series(data=utils.bundle(self.accumulate_v_min))
		elif (input_label == "a_high"):
			self.prototype_a_high = pd.Series(data=utils.bundle(self.accumulate_a_high))
		elif (input_label == "a_low"):
			self.prototype_a_low  = pd.Series(data=utils.bundle(self.accumulate_a_low))
		else:
			print("Invalid input label given")

    # return a tuple of 2 items
    # the 0th element corresponds to valence label : 0 == plus, 1 == min
    # the 1st element corresponds to arousal label : 0 == high, 1 == low
    # if the distance is equal, it will return v_min or a_low
	def predict(self, input_F):
		distance_v_plus = utils.hamming(input_F, self.prototype_v_plus)
		distance_v_min  = utils.hamming(input_F, self.prototype_v_min)

		distance_a_high = utils.hamming(input_F, self.prototype_a_high)
		distance_a_low  = utils.hamming(input_F, self.prototype_a_low)

		self.distance_v_history.append([distance_v_plus, distance_v_min])
		self.distance_a_history.append([distance_a_high, distance_a_low])

		return (0 if distance_v_plus < distance_v_min else 1, 0 if distance_a_high < distance_a_low else 1)

	def reset(self):
		self.accumulate_v_plus = []
		self.accumulate_v_min  = []
		self.accumulate_a_high = []
		self.accumulate_a_low  = []

		self.prototype_v_plus = None
		self.prototype_v_min  = None
		self.prototype_a_high = None
		self.prototype_a_low  = None

		self.distance_v_history = []
		self.distance_a_history = []
