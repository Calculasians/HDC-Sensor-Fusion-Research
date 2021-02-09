`include "const.vh"

module temporal_encoder (
	input  clk,
	input  rst,

	input  hvin_valid,
	output hvin_ready,
	input  [`HV_DIMENSION-1:0] hvin,

	output reg hvout_valid,
	input  hvout_ready,
	output reg [`HV_DIMENSION-1:0] hvout
);

	reg  [`HV_DIMENSION-1:0] ngram[`NGRAM_SIZE-1:0];

	wire hvin_fire;
	wire hvout_fire;

	assign hvin_fire  = hvin_valid && hvin_ready;
	assign hvin_ready = ~hvout_valid || hvout_ready;

	assign hvout_fire = hvout_valid && hvout_ready;

	always @(posedge clk) begin
		if (rst)
			hvout_valid <= 1'b0;
		else if (hvin_fire)
			hvout_valid <= 1'b1;
		else if (hvout_fire)
			hvout_valid <= 1'b0;
	end

	integer i;
	always @(posedge clk) begin
		if (rst)
			for (i = 0; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= {`HV_DIMENSION{1'b0}};
		else if (hvin_fire) begin
			ngram[0] <= hvin;
			for (i = 1; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= ngram[i-1] >> 1;
		end
	end

	always @(*) begin
		hvout = ngram[0];
		for (i = 1; i < `NGRAM_SIZE; i = i + 1) hvout = hvout ^ ngram[i];
	end

endmodule