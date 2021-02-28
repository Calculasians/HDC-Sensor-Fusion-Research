`include "const.vh"

module fuser #(
	parameter NUM_FOLDS, // 1 means no folding. Equivalent to #accumulators
	parameter NUM_FOLDS_WIDTH, // ceillog(NUM_FOLDS)
	parameter FOLD_WIDTH  // 2000 means no folding. FOLD_WIDTH should be a factor of 2000
) (
	input 								clk,
	input 								rst,

	input 								hvin_valid,
	output 								hvin_ready,
	input 		[FOLD_WIDTH-1:0]		hvin,
	input 		[NUM_FOLDS_WIDTH-1:0]	fold_counter,
	input 								done,

	output 								hvout_valid,
	input 								hvout_ready,
	output reg 	[`HV_DIMENSION-1:0] 	hvout			
);

	reg [`NUM_MODALITY_WIDTH-1:0] accumulator [`HV_DIMENSION-1:0];

	assign hvin_ready 		= 1'b1;
	assign hvout_valid 		= done;

	integer i;
	always @(posedge clk) begin
		if (rst || done) begin
			for (i = 0; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= {`NUM_MODALITY_WIDTH{1'b0}};
		end else if (hvin_valid) begin
			for (i = 0; i < `HV_DIMENSION; i = i + 1) begin
				if (i >= fold_counter * FOLD_WIDTH && i < fold_counter * FOLD_WIDTH + FOLD_WIDTH) begin
					accumulator[i] <= accumulator[i] + {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i - (fold_counter * FOLD_WIDTH)]};
				end
			end

			//for (i = fold_counter * FOLD_WIDTH; i < fold_counter * FOLD_WIDTH + FOLD_WIDTH; i = i + 1)
			//	accumulator[i] <= accumulator[i] + {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i - (fold_counter * FOLD_WIDTH)]};
		end
	end

	integer j;
	always @(*) begin
		for (j = 0; j < `HV_DIMENSION; j = j + 1)  hvout[j] = (accumulator[j] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
	end

endmodule : fuser
