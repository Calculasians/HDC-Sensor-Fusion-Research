import hdc_top
import utils

def series_to_string(input_series):
	return input_series.to_string(index=False).replace(" ", "").replace("\n", "")

def list_to_string(input_list):
	return str(input_list).strip('[]').replace(",","").replace(" ", "")

# Instantiate the datapath
hdc_top.HDCTop.dimension = 2000;
hdc_top = hdc_top.HDCTop('database/fm.csv', 
                         'database/imrandom/GSR_proj_pos_D_2000_imrandom.csv', 'database/imrandom/GSR_proj_neg_D_2000_imrandom.csv',
                         'database/imrandom/ECG_proj_pos_D_2000_imrandom.csv', 'database/imrandom/ECG_proj_neg_D_2000_imrandom.csv',
                         'database/imrandom/EEG_proj_pos_D_2000_imrandom.csv', 'database/imrandom/EEG_proj_neg_D_2000_imrandom.csv',
                         'database/imrandom/im_D_2000_imrandom.csv',
                         is_early_fusion=True)

# Open Files
im				 = open("tb_database/im.txt", "w")

GSR_fm			 = open("tb_database/GSR_fm.txt", "w")
GSR_proj_plus	 = open("tb_database/imrandom/GSR_proj_pos_D_2000_imrandom.txt", "w")
GSR_proj_neg	 = open("tb_database/imrandom/GSR_proj_neg_D_2000_imrandom.txt", "w")
GSR_output_R	 = open("tb_database/imrandom/GSR_output_R_D_2000_imrandom.txt", "w")

ECG_fm			 = open("tb_database/ECG_fm.txt", "w")
ECG_proj_plus	 = open("tb_database/imrandom/ECG_proj_pos_D_2000_imrandom.txt", "w")
ECG_proj_neg	 = open("tb_database/imrandom/ECG_proj_neg_D_2000_imrandom.txt", "w")
ECG_output_R	 = open("tb_database/imrandom/ECG_output_R_D_2000_imrandom.txt", "w")

EEG_fm			 = open("tb_database/EEG_fm.txt", "w")
EEG_proj_plus	 = open("tb_database/imrandom/EEG_proj_pos_D_2000_imrandom.txt", "w")
EEG_proj_neg	 = open("tb_database/imrandom/EEG_proj_neg_D_2000_imrandom.txt", "w")
EEG_output_R	 = open("tb_database/imrandom/EEG_output_R_D_2000_imrandom.txt", "w")

output_R_fused	 = open("tb_database/imrandom/output_R_fused_D_2000_imrandom.txt", "w")
output_T		 = open("tb_database/imrandom/output_T_D_2000_imrandom.txt", "w")

output_V_label   = open("tb_database/imrandom/output_V_label_D_2000_imrandom.txt", "w")
output_A_label   = open("tb_database/imrandom/output_A_label_D_2000_imrandom.txt", "w")
output_prototype = open("tb_database/imrandom/output_prototype_D_2000_imrandom.txt", "w")

for i in range(len(hdc_top.item_memory.data)):
	im.write(series_to_string(hdc_top.item_memory.getRow(i))+"\n")

for i in range(len(hdc_top.projection_memory_GSR.proj_plus.data)):
	GSR_proj_plus.write(series_to_string(hdc_top.projection_memory_GSR.proj_plus.getRow(i))+"\n")
	GSR_proj_neg.write(series_to_string(hdc_top.projection_memory_GSR.proj_neg.getRow(i))+"\n")

for i in range(len(hdc_top.projection_memory_ECG.proj_plus.data)):
	ECG_proj_plus.write(series_to_string(hdc_top.projection_memory_ECG.proj_plus.getRow(i))+"\n")
	ECG_proj_neg.write(series_to_string(hdc_top.projection_memory_ECG.proj_neg.getRow(i))+"\n")

for i in range(len(hdc_top.projection_memory_EEG.proj_plus.data)):
	EEG_proj_plus.write(series_to_string(hdc_top.projection_memory_EEG.proj_plus.getRow(i))+"\n")
	EEG_proj_neg.write(series_to_string(hdc_top.projection_memory_EEG.proj_neg.getRow(i))+"\n")

hdc_top.train_am();
output_prototype.write(series_to_string(hdc_top.associative_memory.prototype_v_plus)+"\n")
output_prototype.write(series_to_string(hdc_top.associative_memory.prototype_v_min)+"\n")
output_prototype.write(series_to_string(hdc_top.associative_memory.prototype_a_high)+"\n")
output_prototype.write(series_to_string(hdc_top.associative_memory.prototype_a_low)+"\n")

hdc_top.reset_spatial_encoder()
hdc_top.reset_temporal_encoder()

for i in range(len(hdc_top.feature_memory.ds_data)):
	GSR_fm.write(series_to_string(hdc_top.feature_memory.ds_data.iloc[i,0:32].astype(int))+"\n")
	ECG_fm.write(series_to_string(hdc_top.feature_memory.ds_data.iloc[i,32:109].astype(int))+"\n")
	EEG_fm.write(series_to_string(hdc_top.feature_memory.ds_data.iloc[i,109:214].astype(int))+"\n")

	hdc_top.run_spatial_encoder(hdc_top.feature_memory.ds_data.iloc[i,:])

	GSR_output_R.write(series_to_string(hdc_top.spatial_encoder_GSR.output_R)+"\n")
	ECG_output_R.write(series_to_string(hdc_top.spatial_encoder_ECG.output_R)+"\n")
	EEG_output_R.write(series_to_string(hdc_top.spatial_encoder_EEG.output_R)+"\n")

	hdc_top.output_R_fused = utils.bundle([hdc_top.spatial_encoder_GSR.output_R, 
										   hdc_top.spatial_encoder_ECG.output_R,
										   hdc_top.spatial_encoder_EEG.output_R])

	output_R_fused.write(list_to_string(hdc_top.output_R_fused)+"\n")

	hdc_top.run_temporal_encoder()

	output_T.write(series_to_string(hdc_top.temporal_encoder.output_T)+"\n")

	predicted_v, predicted_a = hdc_top.predict_am()
	output_V_label.write(str(predicted_v)+"\n")
	output_A_label.write(str(predicted_a)+"\n")

# Close Files
im.close()

GSR_fm.close()
GSR_proj_plus.close()
GSR_proj_neg.close()
GSR_output_R.close()

ECG_fm.close()
ECG_proj_plus.close()
ECG_proj_neg.close()
ECG_output_R.close()

EEG_fm.close()
EEG_proj_plus.close()
EEG_proj_neg.close()
EEG_output_R.close()

output_R_fused.close()
output_T.close()

output_V_label.close()
output_A_label.close()
output_prototype.close()
