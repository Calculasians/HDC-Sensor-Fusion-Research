`include "const.vh"

module hv_generator (
	input clk,
	input rst,

	input  [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0],
	input  fin_valid,
	output fin_ready,

	// GSR
	output [`HV_DIMENSION-1:0] GSR_im,
	output reg [`HV_DIMENSION-1:0] GSR_projm,
	output GSR_dout_valid,
	input  GSR_dout_ready,

	// ECG
	output [`HV_DIMENSION-1:0] ECG_im,
	output reg [`HV_DIMENSION-1:0] ECG_projm,
	output ECG_dout_valid,
	input  ECG_dout_ready,

	// EEG
	output [`HV_DIMENSION-1:0] EEG_im,
	output reg [`HV_DIMENSION-1:0] EEG_projm,
	output EEG_dout_valid,
	input  EEG_dout_ready,

	input  [`HV_DIMENSION-1:0] seed_hv,
	input  seed_hv_valid
);

	//------------------------//
	// SEED HV Initialization //
	//------------------------//

	reg  [`HV_DIMENSION-1:0] projm_pos;
	reg  [`HV_DIMENSION-1:0] projm_neg;
	reg  valid_seed_hv;

	always @(posedge clk) begin
		if (seed_hv_valid) begin
			projm_pos <= seed_hv;
			projm_neg <= (seed_hv << 1) ^ (seed_hv >> 1);
			valid_seed_hv <= 1'b1;
		end
	end

	//---------------------//
	// Registers and Wires //
	//---------------------//

	wire fin_fire;

	reg  [`CHANNEL_WIDTH-1:0] feature_memory [`TOTAL_NUM_CHANNEL-1:0];
	reg  [6:0] counter;

	reg  [`HV_DIMENSION-1:0] im;

	//-------//
	// Logic //
	//-------//

	assign fin_fire  = fin_valid && fin_ready;
	assign fin_ready = valid_seed_hv && counter == `EEG_NUM_CHANNEL && GSR_dout_ready && ECG_dout_ready && EEG_dout_ready;

	always @(posedge clk) begin
		if (rst)
			counter <= `EEG_NUM_CHANNEL;
		else if (fin_fire)
			counter <= 0;
		else if (counter < `EEG_NUM_CHANNEL)
			counter <= counter + 1;
	end

	integer i;
	always @(posedge clk) begin
		if (fin_fire)
			for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) feature_memory[i] <= features[i];
	end

	always @(posedge clk) begin
		if (fin_fire)
			im <= (projm_neg << 1) ^ (projm_neg >> 1);
		else if (counter < `EEG_NUM_CHANNEL - 1)
			im <= (im << 1) ^ (im >> 1);
	end

	assign GSR_dout_valid = counter < `GSR_NUM_CHANNEL;
	assign GSR_im = im;

	always @(*) begin
		if (feature_memory[counter] == 1)
			GSR_projm = projm_pos;
		else if (feature_memory[counter] == 2)
			GSR_projm = projm_neg;
		else
			GSR_projm = {`HV_DIMENSION{1'b0}};
	end

	assign ECG_dout_valid = counter < `ECG_NUM_CHANNEL;
	assign ECG_im = im;

	always @(*) begin
		if (feature_memory[`GSR_NUM_CHANNEL + counter] == 1)
			ECG_projm = projm_pos;
		else if (feature_memory[`GSR_NUM_CHANNEL + counter] == 2)
			ECG_projm = projm_neg;
		else
			ECG_projm = {`HV_DIMENSION{1'b0}};
	end

	assign EEG_dout_valid = counter < `EEG_NUM_CHANNEL;
	assign EEG_im = im;

	always @(*) begin
		if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + counter] == 1)
			EEG_projm = projm_pos;
		else if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + counter] == 2)
			EEG_projm = projm_neg;
		else
			EEG_projm = {`HV_DIMENSION{1'b0}};
	end

endmodule : hv_generator