`include "const.vh"

module fuser (
	output hvin_ready,

	input  hvin1_valid,
	input  [`HV_DIMENSION-1:0] hvin1,

	input  hvin2_valid,
	input  [`HV_DIMENSION-1:0] hvin2,

	input  hvin3_valid,
	input  [`HV_DIMENSION-1:0] hvin3,

	output hvout_valid,
	input  hvout_ready,
	output reg [`HV_DIMENSION-1:0] hvout
);

	localparam num_mod = 3;
	localparam num_mod_width = `ceilLog2(num_mod);

	reg  [num_mod_width:0] accumulator [`HV_DIMENSION-1:0];

	assign hvin_ready = hvout_ready;
	assign hvout_valid = hvin1_valid && hvin2_valid && hvin3_valid;

	integer i;
	always @(*) begin
		for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] = {{num_mod_width-1{1'b0}}, hvin1[i]};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] = accumulator[i] + {{num_mod_width-1{1'b0}}, hvin2[i]};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] = accumulator[i] + {{num_mod_width-1{1'b0}}, hvin3[i]};

		for (i = 0; i < `HV_DIMENSION; i = i + 1) hvout[i] = (accumulator[i] > (num_mod >> 1)) ? 1'b1 : 1'b0;
	end

endmodule