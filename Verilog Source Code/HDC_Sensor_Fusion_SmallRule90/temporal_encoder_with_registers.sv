`include "const.vh"

module temporal_encoder (
	input							clk,
	input							rst,

	input							hvin_valid,
	output							hvin_ready,
	input		[`HV_DIMENSION-1:0]	hvin,

	output							hvout_valid,
	input							hvout_ready,
	output reg	[`HV_DIMENSION-1:0] hvout
);

	//---------------------//
	// Registers and Wires //
	//---------------------//

	reg		[1:0]				counter;
	reg		[`HV_DIMENSION-1:0] ngram [`NGRAM_SIZE-1:0];
	reg		[`HV_DIMENSION-1:0] binded_ngram;

	wire	hvin_fire;
	wire	hvout_fire;

	//----------------------------------------------------------------------------------------------------//
	//----------------------------------------------------------------------------------------------------//

	assign hvin_fire	= hvin_valid && hvin_ready;
	assign hvin_ready	= counter == 0;

	assign hvout_fire	= hvout_valid && hvout_ready;
	assign hvout_valid	= counter == 2;

	always @(posedge clk) begin
		if (rst || hvout_fire) begin
			counter <= 0;
		end
		else if (hvin_fire || (counter > 0 && counter < 2)) begin
			counter <= counter + 1;
		end
	end

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= {`HV_DIMENSION{1'b0}};
		end
		else if (hvin_fire) begin
			ngram[0] <= hvin;
			for (i = 1; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= ngram[i-1] >> 1;
		end
	end

	always @(*) begin
		binded_ngram = ngram[0];
		for (i = 1; i < `NGRAM_SIZE; i = i + 1) binded_ngram = binded_ngram ^ ngram[i];
	end

	always @(posedge clk) begin
		if (counter == 1) begin
			hvout <= binded_ngram;
		end
	end

endmodule : temporal_encoder