`include "const.vh"

module hv_generator (
	input		clk,
	input		rst,

	input		fin_valid,
	output		fin_ready,
	input		[`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0],
	
	output		dout_valid,
	input		dout_ready,
	output reg	[`HV_DIMENSION-1:0] im,
	output reg	[`HV_DIMENSION-1:0] projm,
	output		[`MAX_NUM_CHANNEL_WIDTH-1:0] num_channel
);

	localparam projm_pos				= `SEED_HV;
	localparam projm_neg				= (projm_pos << 1) ^ (projm_pos >> 1);

	//---------------------//
	// Registers and Wires //
	//---------------------//

	wire									fin_fire;
	wire									dout_fire;

	reg		[`NUM_MODALITY_WIDTH-1:0] 		mod_counter;
	reg		[`MAX_NUM_CHANNEL_WIDTH-1:0] 	channel_counter;
	reg		[`CHANNEL_WIDTH-1:0] 			feature_memory [`TOTAL_NUM_CHANNEL-1:0];

	//----------------------------------------------------------------------------------------------------//
	//----------------------------------------------------------------------------------------------------//

	assign fin_fire		= fin_valid && fin_ready;
	assign fin_ready	= mod_counter == `NUM_MODALITY;

	assign dout_fire	= dout_valid && dout_ready;
	assign dout_valid	= channel_counter == 0;

	assign num_channel      = (mod_counter == 0) ? `GSR_NUM_CHANNEL : (mod_counter == 1) ? `ECG_NUM_CHANNEL : `EEG_NUM_CHANNEL;

	always @(posedge clk) begin
		if (rst) begin
			mod_counter <= `NUM_MODALITY;
		end
		else if (fin_fire) begin
			mod_counter <= 0;
		end
		else if ((mod_counter == 0 && channel_counter == `GSR_NUM_CHANNEL-1) ||
				 (mod_counter == 1 && channel_counter == `ECG_NUM_CHANNEL-1) ||
				 (mod_counter == 2 && channel_counter == `EEG_NUM_CHANNEL-1)) begin
			mod_counter <= mod_counter + 1;
		end
	end

	always @(posedge clk) begin
		if (fin_fire || (mod_counter == 0 && channel_counter == `GSR_NUM_CHANNEL-1) || (mod_counter == 1 && channel_counter == `ECG_NUM_CHANNEL-1)) begin
			channel_counter <= 0;
		end
		else if (dout_fire || (channel_counter > 0 && channel_counter < `EEG_NUM_CHANNEL)) begin
			channel_counter <= channel_counter + 1;
		end
	end

	integer i;
	always @(posedge clk) begin
		if (fin_fire)
			for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) feature_memory[i] <= features[i];
	end

	always @(posedge clk) begin
		if (fin_fire) begin
			im <= (projm_neg << 1) ^ (projm_neg >> 1);
		end
		else if (dout_fire || (channel_counter > 0 && channel_counter < `EEG_NUM_CHANNEL)) begin
			im <= (im << 1) ^ (im >> 1);
		end
	end

	always @(*) begin
		if (mod_counter == 0) begin
			if (feature_memory[channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (mod_counter == 1) begin
			if (feature_memory[`GSR_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[`GSR_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (mod_counter == 2) begin
			if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
	end

endmodule : hv_generator