`include "const.vh"

module spatial_encoder #(
	parameter num_channel = 32
) (
	input  clk,
	input  rst,

	input  din_valid,
	output din_ready,
	input  [`HV_DIMENSION-1:0] im,
	input  [`HV_DIMENSION-1:0] projm,

	output hvout_valid,
	input  hvout_ready,
	output reg [`HV_DIMENSION-1:0] hvout
);

	/* Note:
		- A single data in handshake will spend `num_channel` cycles to accumulate the inputs
		  This means that it does not matter whether `din_valid` is high throughout `num_channel` cycles or not
		- It takes `num_channel + 2` cycles for the spatial encoder to produce a valid output
		  - The first `num_channel` cycles are used to accumulate the inputs
		  - The `num_channel + 1` cycle is used to bind the accumulated inputs with the final hv
		  - The `num_channel + 2` cycle is used to bundle all of the accumulated inputs (majority)
		- Once `hvout_valid` is asserted, it will stay high until `hvout_ready` is asserted.
		  In that time frame, `hvout` will keep the correct data.
	*/

	localparam num_channel_width = `ceilLog2(num_channel + 2);

	reg  [num_channel_width-1:0] accumulator [`HV_DIMENSION-1:0];
	reg  [`HV_DIMENSION-1:0] final_hv;
	reg  [num_channel_width-1:0] counter;
	wire [`HV_DIMENSION-1:0] binded_im_projm;

	wire din_fire;
	wire hvout_fire;

	assign din_fire        = din_valid && din_ready;
	assign din_ready       = counter < num_channel;

	assign hvout_fire      = hvout_valid && hvout_ready;
	assign hvout_valid     = counter == num_channel + 2;

	assign binded_im_projm = im ^ projm;

	always @(posedge clk) begin
		if (rst || hvout_fire)
			counter <= 0;
		else if (din_fire || (counter >= num_channel && counter < num_channel + 2))
			counter <= counter + 1;
	end

	always @(posedge clk) begin
		if (counter == 1)
			final_hv <= binded_im_projm;
		else if (counter == num_channel - 1 && din_fire)
			final_hv <= final_hv ^ binded_im_projm;
	end

	integer i;
	always @(posedge clk) begin
			if (counter == 0 && din_fire)
			for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= {{num_channel_width-1{1'b0}}, binded_im_projm[i]};
		else if (counter < num_channel && din_fire)
			for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= accumulator[i] + {{num_channel_width-1{1'b0}}, binded_im_projm[i]};
		else if (counter == num_channel)
			for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= accumulator[i] + {{num_channel_width-1{1'b0}}, final_hv[i]};
	end

	always @(posedge clk) begin
		if (counter == num_channel + 1)
			for (i = 0; i < `HV_DIMENSION; i = i + 1) hvout[i] <= (accumulator[i] > (num_channel+1 >> 1)) ? 1'b1 : 1'b0;
	end

endmodule