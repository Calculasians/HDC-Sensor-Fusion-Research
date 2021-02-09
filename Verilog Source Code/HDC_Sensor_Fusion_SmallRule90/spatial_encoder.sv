`include "const.vh"

module spatial_encoder (
	input										clk,
	input										rst,

	input										din_valid,
	output										din_ready,
	input		[`HV_DIMENSION-1:0] 			im,
	input		[`HV_DIMENSION-1:0] 			projm,
	input		[`MAX_NUM_CHANNEL_WIDTH-1:0] 	num_channel,

	output										hvout_valid,
	input										hvout_ready,
	output reg	[`HV_DIMENSION-1:0]				hvout
);

	localparam MAX_NUM_CHANNEL_INTERNAL_WIDTH = `MAX_NUM_CHANNEL_WIDTH+1;

	//---------------------//
	// Registers and Wires //
	//---------------------//

	reg		[MAX_NUM_CHANNEL_INTERNAL_WIDTH-1:0]	counter;
	reg		[MAX_NUM_CHANNEL_INTERNAL_WIDTH-1:0]	accumulator [`HV_DIMENSION-1:0];
	reg		[`HV_DIMENSION-1:0]						final_hv;
	reg		[MAX_NUM_CHANNEL_INTERNAL_WIDTH-1:0]	num_channel_stored;
	wire	[`HV_DIMENSION-1:0]						binded_im_projm;

	wire											din_fire;
	wire											hvout_fire;

	//----------------------------------------------------------------------------------------------------//
	//----------------------------------------------------------------------------------------------------//

	assign din_fire			= din_valid && din_ready;
	assign din_ready		= counter == 0;

	assign hvout_fire		= hvout_valid && hvout_ready;
	assign hvout_valid		= counter == num_channel_stored + 1;

	assign binded_im_projm	= im ^ projm;

	always @(posedge clk) begin
		if (rst || hvout_fire) begin
			counter <= 0;
		end
		else if (din_fire || (counter > 0 && counter < num_channel_stored + 1)) begin
			counter <= counter + 1;
		end
	end

	always @(posedge clk) begin
		if (din_fire) begin
			num_channel_stored <= {1'b0, num_channel};
		end
	end

	always @(posedge clk) begin
		if (counter == 1) begin
			final_hv <= binded_im_projm;
		end
		else if (counter == num_channel_stored-1) begin
			final_hv <= final_hv ^ binded_im_projm;
		end
	end

	integer i;
	always @(posedge clk) begin
		if (din_fire) begin
			for (i = 0; i < `HV_DIMENSION/2; i = i + 1) accumulator[i] <= {{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, binded_im_projm[i]};
			for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) accumulator[i] <={{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, binded_im_projm[i]};
		end
		else if (counter > 0 && counter < num_channel_stored) begin
			for (i = 0; i < `HV_DIMENSION/2; i = i + 1) accumulator[i] <= accumulator[i] + {{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, binded_im_projm[i]};
			for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= accumulator[i] + {{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, binded_im_projm[i]};
		end
		else if (counter == num_channel_stored) begin
			for (i = 0; i < `HV_DIMENSION/2; i = i + 1) accumulator[i] <= accumulator[i] + {{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, final_hv[i]};
			for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= accumulator[i] + {{MAX_NUM_CHANNEL_INTERNAL_WIDTH-1{1'b0}}, final_hv[i]};
		end
	end

	always @(*) begin
		for (i = 0; i < `HV_DIMENSION/2; i = i + 1) hvout[i] = (accumulator[i] > ((num_channel_stored+1) >> 1)) ? 1'b1 : 1'b0;
		for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) hvout[i] = (accumulator[i] > ((num_channel_stored+1) >> 1)) ? 1'b1 : 1'b0;
	end

endmodule : spatial_encoder