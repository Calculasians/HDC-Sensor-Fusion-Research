`include "const.vh"

module fuser_fanout_reduced #(
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
	reg 							done_delay;
	reg  							hvin_valid_delay;
	reg [`NUM_MODALITY_WIDTH-1:0] 	mod_counter;

	localparam NUM_REPLICATIONS = 8; // we will duplicate fold_counter 8 times
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_0;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_1;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_2;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_3;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_4;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_5;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_6;
	reg [NUM_FOLDS_WIDTH-1:0]		fold_counter_delay_7;

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
		if (hvin_valid) begin
			fold_counter_delay_0 <= fold_counter;
			fold_counter_delay_1 <= fold_counter;
			fold_counter_delay_2 <= fold_counter;
			fold_counter_delay_3 <= fold_counter;
			fold_counter_delay_4 <= fold_counter;
			fold_counter_delay_5 <= fold_counter;
			fold_counter_delay_6 <= fold_counter;
			fold_counter_delay_7 <= fold_counter;
		end else begin
			fold_counter_delay_0 <= hvin[0 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_1 <= hvin[1 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_2 <= hvin[2 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_3 <= hvin[3 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_4 <= hvin[4 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_5 <= hvin[5 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_6 <= hvin[6 +: NUM_FOLDS_WIDTH];
			fold_counter_delay_7 <= hvin[7 +: NUM_FOLDS_WIDTH];
		end
	end

	always @(posedge clk) begin
		done_delay 			<= done;
		hvin_valid_delay	<= hvin_valid;
	end

	integer j0;
	always @(posedge clk) begin
		for (j0 = 0; j0 < `HV_DIMENSION / NUM_REPLICATIONS; j0 = j0 + 1) begin
			if (hvin_valid_delay && j0 >= fold_counter_delay_0 * FOLD_WIDTH && j0 < fold_counter_delay_0 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j0] <= (accumulator[j0 - (fold_counter_delay_0 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end	

	integer j1;
	always @(posedge clk) begin
		for (j1 = `HV_DIMENSION / NUM_REPLICATIONS; j1 < (`HV_DIMENSION / NUM_REPLICATIONS) * 2; j1 = j1 + 1) begin
			if (hvin_valid_delay && j1 >= fold_counter_delay_1 * FOLD_WIDTH && j1 < fold_counter_delay_1 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j1] <= (accumulator[j1 - (fold_counter_delay_1 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j2;
	always @(posedge clk) begin
		for (j2 = (`HV_DIMENSION / NUM_REPLICATIONS) * 2; j2 < (`HV_DIMENSION / NUM_REPLICATIONS) * 3; j2 = j2 + 1) begin
			if (hvin_valid_delay && j2 >= fold_counter_delay_2 * FOLD_WIDTH && j2 < fold_counter_delay_2 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j2] <= (accumulator[j2 - (fold_counter_delay_2 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j3;
	always @(posedge clk) begin
		for (j3 = (`HV_DIMENSION / NUM_REPLICATIONS) * 3; j3 < (`HV_DIMENSION / NUM_REPLICATIONS) * 4; j3 = j3 + 1) begin
			if (hvin_valid_delay && j3 >= fold_counter_delay_3 * FOLD_WIDTH && j3 < fold_counter_delay_3 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j3] <= (accumulator[j3 - (fold_counter_delay_3 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j4;
	always @(posedge clk) begin
		for (j4 = (`HV_DIMENSION / NUM_REPLICATIONS) * 4; j4 < (`HV_DIMENSION / NUM_REPLICATIONS) * 5; j4 = j4 + 1) begin
			if (hvin_valid_delay && j4 >= fold_counter_delay_4 * FOLD_WIDTH && j4 < fold_counter_delay_4 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j4] <= (accumulator[j4 - (fold_counter_delay_4 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j5;
	always @(posedge clk) begin
		for (j5 = (`HV_DIMENSION / NUM_REPLICATIONS) * 5; j5 < (`HV_DIMENSION / NUM_REPLICATIONS) * 6; j5 = j5 + 1) begin
			if (hvin_valid_delay && j5 >= fold_counter_delay_5 * FOLD_WIDTH && j5 < fold_counter_delay_5 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j5] <= (accumulator[j5 - (fold_counter_delay_5 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j6;
	always @(posedge clk) begin
		for (j6 = (`HV_DIMENSION / NUM_REPLICATIONS) * 6; j6 < (`HV_DIMENSION / NUM_REPLICATIONS) * 7; j6 = j6 + 1) begin
			if (hvin_valid_delay && j6 >= fold_counter_delay_6 * FOLD_WIDTH && j6 < fold_counter_delay_6 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j6] <= (accumulator[j6 - (fold_counter_delay_6 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

	integer j7;
	always @(posedge clk) begin
		for (j7 = (`HV_DIMENSION / NUM_REPLICATIONS) * 7; j7 < (`HV_DIMENSION / NUM_REPLICATIONS) * 8; j7 = j7 + 1) begin
			if (hvin_valid_delay && j7 >= fold_counter_delay_7 * FOLD_WIDTH && j7 < fold_counter_delay_7 * FOLD_WIDTH + FOLD_WIDTH) begin
				hvout[j7] <= (accumulator[j7 - (fold_counter_delay_7 * FOLD_WIDTH)] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			end
		end
	end

endmodule : fuser_fanout_reduced
