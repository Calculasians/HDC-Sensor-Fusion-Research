`include "const.vh"

module memory_controller (
	input clk,
	input rst,

	input  [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0],
	input  fin_valid,
	output fin_ready,

	// GSR
	output reg [`HV_DIMENSION-1:0] GSR_im,
	output reg [`HV_DIMENSION-1:0] GSR_projm,
	output GSR_dout_valid,
	input  GSR_dout_ready,

	// ECG
	output reg [`HV_DIMENSION-1:0] ECG_im,
	output reg [`HV_DIMENSION-1:0] ECG_projm,
	output ECG_dout_valid,
	input  ECG_dout_ready,

	// EEG
	output reg [`HV_DIMENSION-1:0] EEG_im,
	output reg [`HV_DIMENSION-1:0] EEG_projm,
	output EEG_dout_valid,
	input  EEG_dout_ready,

	// SRAM 1
	output reg [2:0] addr_1,
	input  [`HV_DIMENSION-1:0] hv_1,

	// SRAM 2
	output reg [2:0] addr_2,
	input  [`HV_DIMENSION-1:0] hv_2,

	// SRAM 3
	output reg [2:0] addr_3,
	input  [`HV_DIMENSION-1:0] hv_3
);

	//--------------------//
	// Regsiter and Wires //
	//--------------------//

	wire fin_fire;

	reg  [`CHANNEL_WIDTH-1:0] feature_memory [`TOTAL_NUM_CHANNEL-1:0];
	reg  [6:0] counter;
	reg  [3:0] row_counter;
	reg  [3:0] col_counter;
	reg  repeated;

	wire [4:0] im_addr;
	wire [4:0] projm_pos_addr;
	wire [4:0] projm_neg_addr;

	reg  [1:0] im_intermediate;
	reg  [1:0] projm_pos_intermediate;
	reg  [1:0] projm_neg_intermediate;

	reg  [1:0] im_sram;
	reg  [1:0] projm_pos_sram;
	reg  [1:0] projm_neg_sram;

	reg  [`HV_DIMENSION-1:0] projm_pos;
	reg  [`HV_DIMENSION-1:0] projm_pos_saved;
	reg  [`HV_DIMENSION-1:0] projm_neg;
	reg  [`HV_DIMENSION-1:0] projm_neg_saved;

	//-------------//
	// State Logic //
	//-------------//

	assign fin_fire  = fin_valid && fin_ready;
	assign fin_ready = counter == `EEG_NUM_CHANNEL + 2 && GSR_dout_ready && ECG_dout_ready && EEG_dout_ready;

	always @(posedge clk) begin
		if (rst)
			counter <= `EEG_NUM_CHANNEL + 2;
		else if (fin_fire)
			counter <= 0;
		else if (counter <= `EEG_NUM_CHANNEL + 1)
			counter <= counter + 1;
	end

	always @(posedge clk) begin
		if (fin_fire)
			col_counter <= 9;
		else if (row_counter == col_counter && repeated)
			col_counter <= col_counter - 1;
	end

	always @(posedge clk) begin
		if (fin_fire || row_counter == col_counter)
			row_counter <= 0;
		else
			row_counter <= row_counter + 1;
	end

	always @(posedge clk) begin
		if (fin_fire || (row_counter == col_counter && repeated))
			repeated <= 1'b0;
		else if (row_counter == col_counter)
			repeated <= 1'b1;
	end

	integer i;
	always @(posedge clk) begin
		if (fin_fire)
			for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) feature_memory[i] <= features[i];
	end

	//------------//
	// SRAM Logic //
	//------------//

	assign im_addr = `IM_CHANNEL_TO_INDEX(counter);
	assign projm_pos_addr = `PROJM_POS_CHANNEL_TO_INDEX(counter);
	assign projm_neg_addr = `PROJM_NEG_CHANNEL_TO_INDEX(counter);

	always @(*) begin
		if (im_addr[4:3] == 2'b00) begin
			addr_1 = im_addr[2:0];
		end
		else if (projm_pos_addr[4:3] == 2'b00) begin
			addr_1 = projm_pos_addr[2:0];
		end
		else if (projm_neg_addr[4:3] == 2'b00) begin
			addr_1 = projm_neg_addr[2:0];
		end
		else begin
			addr_1 = 0;
		end
	end

	always @(*) begin
		if (im_addr[4:3] == 2'b01) begin
			addr_2 = im_addr[2:0];
		end
		else if (projm_pos_addr[4:3] == 2'b01) begin
			addr_2 = projm_pos_addr[2:0];
		end
		else if (projm_neg_addr[4:3] == 2'b01) begin
			addr_2 = projm_neg_addr[2:0];
		end
		else begin
			addr_2 = 0;
		end
	end

	always @(*) begin
		if (im_addr[4]) begin
			addr_3 = im_addr[2:0];
		end
		else if (projm_pos_addr[4]) begin
			addr_3 = projm_pos_addr[2:0];
		end
		else if (projm_neg_addr[4]) begin
			addr_3 = projm_neg_addr[2:0];
		end
		else begin
			addr_3 = 0;
		end
	end

	always @(posedge clk) begin
		im_intermediate <= im_addr[4:3];
		im_sram  <= im_intermediate;

		projm_pos_intermediate <= projm_pos_addr[4:3];
		projm_pos_sram <= projm_pos_intermediate;

		projm_neg_intermediate <= projm_neg_addr[4:3];
		projm_neg_sram <= projm_neg_intermediate;
	end

	//--------------//
	// Output Logic //
	//--------------//

	assign GSR_dout_valid = counter > 1 && counter < `GSR_NUM_CHANNEL + 2;
	assign ECG_dout_valid = counter > 1 && counter < `ECG_NUM_CHANNEL + 2;
	assign EEG_dout_valid = counter > 1 && counter < `EEG_NUM_CHANNEL + 2;

	always @(*) begin
		if (im_sram == 2'b00) begin
			GSR_im = hv_1;
			ECG_im = hv_1;
			EEG_im = hv_1;
		end
		else if (im_sram == 2'b01) begin
			GSR_im = hv_2;
			ECG_im = hv_2;
			EEG_im = hv_2;
		end
		else if (im_sram[1]) begin
			GSR_im = hv_3;
			ECG_im = hv_3;
			EEG_im = hv_3;
		end
		else begin
			GSR_im = {`HV_DIMENSION{1'b0}};
			ECG_im = {`HV_DIMENSION{1'b0}};
			EEG_im = {`HV_DIMENSION{1'b0}};
		end
	end

	always @(*) begin
		if (projm_pos_sram == 2'b00)
			projm_pos = hv_1;
		else if (projm_pos_sram == 2'b01)
			projm_pos = hv_2;
		else if (projm_pos_sram[1])
			projm_pos = hv_3;
		else
			projm_pos = {`HV_DIMENSION{1'b0}};
	end

	always @(*) begin
		if (projm_neg_sram == 2'b00)
			projm_neg = hv_1;
		else if (projm_neg_sram == 2'b01)
			projm_neg = hv_2;
		else if (projm_neg_sram[1])
			projm_neg = hv_3;
		else
			projm_neg = {`HV_DIMENSION{1'b0}};
	end

	always @(posedge clk) begin
		if (row_counter == 2) begin
			projm_pos_saved <= projm_pos;
			projm_neg_saved <= projm_neg;
		end
	end

	always @(*) begin
		if (feature_memory[counter - 2] == 1)
			GSR_projm = (row_counter == 2) ? projm_pos : projm_pos_saved;
		else if (feature_memory[counter - 2] == 2)
			GSR_projm = (row_counter == 2) ? projm_neg : projm_neg_saved;
		else
			GSR_projm = {`HV_DIMENSION{1'b0}};
	end

	always @(*) begin
		if (feature_memory[`GSR_NUM_CHANNEL + counter - 2] == 1)
			ECG_projm = (row_counter == 2) ? projm_pos : projm_pos_saved;
		else if (feature_memory[`GSR_NUM_CHANNEL + counter - 2] == 2)
			ECG_projm = (row_counter == 2) ? projm_neg : projm_neg_saved;
		else
			ECG_projm = {`HV_DIMENSION{1'b0}};
	end

	always @(*) begin
		if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + counter - 2] == 1)
			EEG_projm = (row_counter == 2 || counter == `EEG_NUM_CHANNEL + 1) ? projm_pos : projm_pos_saved;
		else if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + counter - 2] == 2)
			EEG_projm = (row_counter == 2 || counter == `EEG_NUM_CHANNEL + 1) ? projm_neg : projm_neg_saved;
		else
			EEG_projm = {`HV_DIMENSION{1'b0}};
	end

endmodule : memory_controller
