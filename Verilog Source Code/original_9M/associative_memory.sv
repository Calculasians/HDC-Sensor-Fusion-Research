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

	reg  [counter_width-1:0] distance_v_plus;
	reg  [counter_width-1:0] distance_v_min;
	reg  [counter_width-1:0] distance_a_high;
	reg  [counter_width-1:0] distance_a_low;

	reg  [`HV_DIMENSION-1:0] similarity_v_plus;
	reg  [`HV_DIMENSION-1:0] similarity_v_min;
	reg  [`HV_DIMENSION-1:0] similarity_a_high;
	reg  [`HV_DIMENSION-1:0] similarity_a_low;

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

	integer i;
	always @(*) begin
		similarity_v_plus = hvin ^ prototype_v_plus;

		distance_v_plus = {counter_width{1'b0}};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) distance_v_plus = distance_v_plus + {{counter_width-1{1'b0}}, similarity_v_plus[i]};
	end

	always @(*) begin
		similarity_v_min = hvin ^ prototype_v_min;

		distance_v_min = {counter_width{1'b0}};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) distance_v_min = distance_v_min + {{counter_width-1{1'b0}}, similarity_v_min[i]};
	end

	always @(*) begin
		similarity_a_high = hvin ^ prototype_a_high;

		distance_a_high = {counter_width{1'b0}};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) distance_a_high = distance_a_high + {{counter_width-1{1'b0}}, similarity_a_high[i]};
	end

	always @(*) begin
		similarity_a_low = hvin ^ prototype_a_low;

		distance_a_low = {counter_width{1'b0}};
		for (i = 0; i < `HV_DIMENSION; i = i + 1) distance_a_low = distance_a_low + {{counter_width-1{1'b0}}, similarity_a_low[i]};
	end

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
