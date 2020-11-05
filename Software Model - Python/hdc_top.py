import utils
import memory
import spatial_encoder
import temporal_encoder

class HDCTop:

	downsample_interval = 8
	learning_rate       = 0.25
	num_channel_GSR     = 32
	num_channel_ECG     = 77
	num_channel_EEG     = 105
	dimension           = 2000
	ngram_size          = 3

	def __init__(self, 	fm_infile, 
						pm_plus_GSR_infile, pm_neg_GSR_infile,
						pm_plus_ECG_infile, pm_neg_ECG_infile,
						pm_plus_EEG_infile, pm_neg_EEG_infile,
						im_infile,
						is_early_fusion=True):

		# Feature Memory
		self.feature_memory = memory.FeatureMemory(fm_infile)
		self.feature_memory.normalize()
		self.feature_memory.downSample(self.downsample_interval)
		self.feature_memory.discretize()
		self.feature_memory.genTrainData(self.learning_rate)

		# Projection Memory
		self.projection_memory_GSR = memory.ProjectionMemory(pm_plus_GSR_infile, pm_neg_GSR_infile)
		self.projection_memory_ECG = memory.ProjectionMemory(pm_plus_ECG_infile, pm_neg_ECG_infile)
		self.projection_memory_EEG = memory.ProjectionMemory(pm_plus_EEG_infile, pm_neg_EEG_infile)

		# Item Memory
		self.item_memory = memory.Memory(im_infile)

		# Associative Memory
		memory.AssociativeMemory.dimension = self.dimension
		self.associative_memory = memory.AssociativeMemory()

		# Spatial Encoder
		spatial_encoder.SpatialEncoder.dimension = self.dimension
		self.spatial_encoder_GSR = spatial_encoder.SpatialEncoder(self.num_channel_GSR)
		self.spatial_encoder_ECG = spatial_encoder.SpatialEncoder(self.num_channel_ECG)
		self.spatial_encoder_EEG = spatial_encoder.SpatialEncoder(self.num_channel_EEG)

		# Temporal Encoder
		temporal_encoder.TemporalEncoder.dimension  = self.dimension
		temporal_encoder.TemporalEncoder.ngram_size = self.ngram_size
		self.temporal_encoder     = temporal_encoder.TemporalEncoder()	# used only when is_early_fusion is True
		self.temporal_encoder_GSR = temporal_encoder.TemporalEncoder()	# used only when is_early_fusion is False
		self.temporal_encoder_ECG = temporal_encoder.TemporalEncoder()	# used only when is_early_fusion is False
		self.temporal_encoder_EEG = temporal_encoder.TemporalEncoder()	# used only when is_early_fusion is False

		self.is_early_fusion = is_early_fusion

		# Prediction Statistics
		self.correct_prediction      = 0
		self.wrong_prediction        = 0
		self.prediction_success_rate = 0

		self.correct_v_prediction      = 0
		self.wrong_v_prediction        = 0
		self.prediction_v_success_rate = 0

		self.correct_a_prediction      = 0
		self.wrong_a_prediction        = 0
		self.prediction_a_success_rate = 0

		self.predicted_v_history = []
		self.predicted_a_history = []

	# Train the prototype hypervectors inside the associative memory
	def train_am(self):
		self.run('v_plus', self.feature_memory.train_data_v_plus)
		self.run('v_min', self.feature_memory.train_data_v_min)
		self.run('a_high', self.feature_memory.train_data_a_high)
		self.run('a_low', self.feature_memory.train_data_a_low)

	# Test run the whole system
	def test(self):
		self.run('test', self.feature_memory.ds_data)

	# Corresponds to running the whole datapath 
	# Inputs: 
	# - label 		: during training, a String that indicates the target prototype hypervector
	#				  during testing, a String 'test'
	# - features 	: a Series (list) of feature values
	def run(self, label, features):
		self.reset_spatial_encoder()
		self.reset_temporal_encoder()

		for i in range(len(features)):
			self.run_spatial_encoder(features.iloc[i,:])
			if (self.is_early_fusion):
				self.output_R_fused = utils.bundle([self.spatial_encoder_GSR.output_R, 
									 				self.spatial_encoder_ECG.output_R, 
									 				self.spatial_encoder_EEG.output_R])
			self.run_temporal_encoder()
			if (not self.is_early_fusion):
				self.output_T_fused = utils.bundle([self.temporal_encoder_GSR.output_T, 
									 				self.temporal_encoder_ECG.output_T, 
									 				self.temporal_encoder_EEG.output_T])
			if (i > 1):
				if (label == 'test'):
					actual_label_v = utils.classify(self.feature_memory.ds_label_v.iloc[i-self.ngram_size+1:i+1,0])
					actual_label_a = utils.classify(self.feature_memory.ds_label_a.iloc[i-self.ngram_size+1:i+1,0])
					self.predict_am_internal(actual_label_v, actual_label_a)
				else:
					self.accumulate_am(label)

		if (label == 'test'):
			self.compute_summary()
		else:
			self.bundle_am(label)

	# Process the feature values in the Spatial Encoder
	# Inputs:
	# - features 	: a Series (list) of feature values
	def run_spatial_encoder(self, features):
		for i in range(self.num_channel_GSR):
			if (features[i] == 1):
				input_Bi = self.projection_memory_GSR.proj_plus.getRow(i)
			elif (features[i] == 2):
				input_Bi = self.projection_memory_GSR.proj_neg.getRow(i)
			else:
				input_Bi = [0] * self.dimension
			self.spatial_encoder_GSR.bind(i, input_Bi, self.item_memory.getRow(i))
		self.spatial_encoder_GSR.bundle()

		for i in range(self.num_channel_ECG):
			if (features[i+self.num_channel_GSR] == 1):
				input_Bi = self.projection_memory_ECG.proj_plus.getRow(i)
			elif (features[i+self.num_channel_GSR] == 2):
				input_Bi = self.projection_memory_ECG.proj_neg.getRow(i)
			else:
				input_Bi = [0] * self.dimension
			self.spatial_encoder_ECG.bind(i, input_Bi, self.item_memory.getRow(i))
		self.spatial_encoder_ECG.bundle()

		for i in range(self.num_channel_EEG):
			if (features[i+self.num_channel_GSR+self.num_channel_ECG] == 1):
				input_Bi = self.projection_memory_EEG.proj_plus.getRow(i)
			elif (features[i+self.num_channel_GSR+self.num_channel_ECG] == 2):
				input_Bi = self.projection_memory_EEG.proj_neg.getRow(i)
			else:
				input_Bi = [0] * self.dimension
			self.spatial_encoder_EEG.bind(i, input_Bi, self.item_memory.getRow(i))
		self.spatial_encoder_EEG.bundle()

	# Process the output of the Spatial Encoder in the Temporal Encoder
	def run_temporal_encoder(self):
		if (self.is_early_fusion):
			self.temporal_encoder.capture(self.output_R_fused)
		else:
			self.temporal_encoder_GSR.capture(self.spatial_encoder_GSR.output_R)
			self.temporal_encoder_ECG.capture(self.spatial_encoder_ECG.output_R)
			self.temporal_encoder_EEG.capture(self.spatial_encoder_EEG.output_R)

	# Used only during training, Associative Memory accumulates the output of the datapath
	# Inputs:
	# - label 	: a String that indicates the target prototype hypervector
	def accumulate_am(self, label):
		if (self.is_early_fusion):
			self.associative_memory.accumulate(label, self.temporal_encoder.output_T)
		else:
			self.associative_memory.accumulate(label, self.output_T_fused)

	# Used only during training, Associative Memory bundles all the accumulated trained hypervectors
	# Inputs:
	# - label 	: a String that indicates the target prototype hypervector
	def bundle_am(self, label):
		self.associative_memory.bundle(label)

	# Used only during testing, Associative Memory predicts the valence and the arousal values that correspond to the output of the datapath
	def predict_am(self):
		if (self.is_early_fusion):
			return self.associative_memory.predict(self.temporal_encoder.output_T)
		else:
			return self.associative_memory.predict(self.output_T_fused)

	# Used only during testing, not only this predicts the valence, and the arousal values, but it also keeps track of the prediction statistics
	# Inputs:
	# - label_v : 0 == plus, 1 == min, the actual/correct valence value corresponding to the output of the datapath
	# - label_a : 0 == high, 1 == low, the actual/correct arousal value corresponding to the output of the datapath
	def predict_am_internal(self, label_v, label_a):
		if (self.is_early_fusion):
			predicted_v, predicted_a = self.associative_memory.predict(self.temporal_encoder.output_T)
		else:
			predicted_v, predicted_a = self.associative_memory.predict(self.output_T_fused)

		self.predicted_v_history.append(predicted_v)
		self.predicted_a_history.append(predicted_a)

		if (predicted_v == label_v and predicted_a == label_a):
			self.correct_prediction += 1
		else:
			self.wrong_prediction += 1

		if (predicted_v == label_v):
			self.correct_v_prediction += 1
		else:
			self.wrong_v_prediction += 1

		if (predicted_a == label_a):
			self.correct_a_prediction += 1
		else:
			self.wrong_a_prediction += 1

	# Used only during testing, collect all the statistics after running a test and calculate the success rates of the predictions
	def compute_summary(self):
		self.prediction_success_rate = self.correct_prediction / (self.correct_prediction + self.wrong_prediction)
		self.prediction_v_success_rate = self.correct_v_prediction / (self.correct_v_prediction + self.wrong_v_prediction)
		self.prediction_a_success_rate = self.correct_a_prediction / (self.correct_a_prediction + self.wrong_a_prediction)

	def reset(self):
		self.reset_memory()
		self.reset_spatial_encoder()
		self.reset_temporal_encoder()
		self.reset_statistics()

	def reset_memory(self):
		self.associative_memory.reset()

	def reset_spatial_encoder(self):
		self.spatial_encoder_GSR.reset()
		self.spatial_encoder_ECG.reset()
		self.spatial_encoder_EEG.reset()

	def reset_temporal_encoder(self):
		self.temporal_encoder.reset()
		self.temporal_encoder_GSR.reset()
		self.temporal_encoder_ECG.reset()
		self.temporal_encoder_EEG.reset()

	def reset_statistics(self):
		self.correct_prediction      = 0
		self.wrong_prediction        = 0
		self.prediction_success_rate = 0

		self.correct_v_prediction      = 0
		self.wrong_v_prediction        = 0
		self.prediction_v_success_rate = 0

		self.correct_a_prediction      = 0
		self.wrong_a_prediction        = 0
		self.prediction_a_success_rate = 0
