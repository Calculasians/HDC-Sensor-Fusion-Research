`include "const.vh"

module associative_memory (
	input  clk,
	input  rst,

	input  hvin_valid,
	output hvin_ready,
	input  [`HV_DIMENSION-1:0] hvin,

	output reg dout_valid,
	input  dout_ready,
	output reg valence,
	output reg arousal
);

	localparam [`HV_DIMENSION-1:0] prototype_v_plus = `PROTOTYPE_V_PLUS;
	localparam [`HV_DIMENSION-1:0] prototype_v_min  = `PROTOTYPE_V_MIN;
	localparam [`HV_DIMENSION-1:0] prototype_a_high = `PROTOTYPE_A_HIGH;
	localparam [`HV_DIMENSION-1:0] prototype_a_low  = `PROTOTYPE_A_LOW;
	localparam counter_width = `ceilLog2(`HV_DIMENSION);

	wire [counter_width-1:0] distance_v_plus;
	wire [counter_width-1:0] distance_v_min;
	wire [counter_width-1:0] distance_a_high;
	wire [counter_width-1:0] distance_a_low;

	wire [`HV_DIMENSION-1:0] similarity_v_plus;
	wire [`HV_DIMENSION-1:0] similarity_v_min;
	wire [`HV_DIMENSION-1:0] similarity_a_high;
	wire [`HV_DIMENSION-1:0] similarity_a_low;

	wire hvin_fire;
	wire dout_fire;

	assign hvin_fire = hvin_valid && hvin_ready;
	assign hvin_ready = ~dout_valid || dout_ready;

	assign dout_fire = dout_valid && dout_ready;

	always @(posedge clk) begin
		if (rst)
			dout_valid <= 1'b0;
		else if (hvin_fire)
			dout_valid <= 1'b1;
		else if (dout_fire)
			dout_valid <= 1'b0;
	end

	assign similarity_v_plus = hvin ^ prototype_v_plus;
	assign similarity_v_min  = hvin ^ prototype_v_min;
	assign similarity_a_high = hvin ^ prototype_a_high;
	assign similarity_a_low  = hvin ^ prototype_a_low;

	hv2000_binary_adder V_PLUS (
		.hv		(similarity_v_plus),
		.weight	(distance_v_plus)
	);

	hv2000_binary_adder V_MIN (
		.hv		(similarity_v_min),
		.weight	(distance_v_min)
	);

	hv2000_binary_adder A_HIGH (
		.hv		(similarity_a_high),
		.weight	(distance_a_high)
	);

	hv2000_binary_adder A_LOW (
		.hv		(similarity_a_low),
		.weight	(distance_a_low)
	);

	always @(posedge clk) begin
		if (hvin_fire) begin
			if (distance_v_plus < distance_v_min)
				valence <= 1'b0;
			else
				valence <= 1'b1;
		end
	end

	always @(posedge clk) begin
		if (hvin_fire) begin
			if (distance_a_high < distance_a_low)
				arousal <= 1'b0;
			else
				arousal <= 1'b1;
		end
	end

endmodule : associative_memory