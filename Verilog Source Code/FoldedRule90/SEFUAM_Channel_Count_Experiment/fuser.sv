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

	reg [`NUM_MODALITY_WIDTH-1:0] 	accumulator [FOLD_WIDTH-1:0];
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay;
	reg 					done_delay;
	reg [`NUM_MODALITY_WIDTH-1:0] 	mod_counter;

	assign hvin_ready 		= 1'b1;
	assign hvout_valid 		= done_delay;

	always @(posedge clk) begin
		if (rst || (hvin_valid && mod_counter == 2)) begin
			mod_counter <= 0;
		end else if (hvin_valid) begin
			mod_counter <= mod_counter + 1;
		end
	end


	integer i;
	always @(posedge clk) begin
		if (rst) 
			for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {`NUM_MODALITY_WIDTH{1'b0}};	
		else if (hvin_valid && mod_counter == 0)
			for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};		
		else if (hvin_valid) 
			for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= accumulator[i] + {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};
		
	end 

	always @(posedge clk) begin
		fold_counter_delay <= fold_counter;
	end

	always @(posedge clk) begin
		done_delay <= done;
	end


	integer j; 
	always @(posedge clk) begin
		for (j = 0; j < `HV_DIMENSION; j = j + 1) begin
			if (j >= fold_counter_delay * FOLD_WIDTH && j < fold_counter_delay * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j] <= (accumulator[j - (fold_counter_delay * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;		
			end
		end

		//for (j = fold_counter_delay * FOLD_WIDTH; j < fold_counter_delay * FOLD_WIDTH + FOLD_WIDTH; j = j + 1) begin
		//	hvout[j] = (accumulator[j - (fold_counter_delay * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
		//end
	end

endmodule : fuser
