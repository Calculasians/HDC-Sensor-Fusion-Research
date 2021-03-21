`include "const.vh"

module temporal_encoder #(
	parameter NUM_FOLDS, // 1 means no folding. Equivalent to #accumulators
	parameter NUM_FOLDS_WIDTH, // ceillog(NUM_FOLDS)
	parameter FOLD_WIDTH  // 2000 means no folding. FOLD_WIDTH should be a factor of 2000
) (
	input								clk,
	input								rst,

	input								hvin_valid,
	output								hvin_ready,
	input		[FOLD_WIDTH-1:0]		hvin,
	input 		[1:0]					classification_counter,
	input 								send_to_am,


	output								hvout_valid,
	input								hvout_ready,
	output reg	[FOLD_WIDTH-1:0] 		hvout
); 

	reg		[1:0]					counter;
	reg  							send_to_am_double_delay;
	reg     						send_to_am_delay;
	reg    	[1:0]					classification_counter_delay;

	reg		[FOLD_WIDTH-1:0] 		ngram [`NGRAM_SIZE-1:0];
	reg   							permutation_tracker;
	reg  	[`NGRAM_SIZE-1:0]		permutations_1;
	reg     [`NGRAM_SIZE-1:0] 		permutations_0;
 
 
	wire	hvin_fire;
	wire	hvout_fire;

	assign hvin_fire	= hvin_valid && hvin_ready;
	assign hvin_ready	= counter == 0;

	assign hvout_fire	= hvout_valid && hvout_ready;
	assign hvout_valid	= send_to_am_double_delay && counter == 2;

	always @(posedge clk) begin
		if (rst || counter == 2) begin
			counter <= 0;
		end
		else if (hvin_fire || counter == 1) begin
			counter <= counter + 1;
		end   
	end

	always @(posedge clk) begin
		send_to_am_delay 				<= send_to_am;
		send_to_am_double_delay			<= send_to_am_delay;
		classification_counter_delay 	<= classification_counter;
	end

	always @(posedge clk) begin
		if (rst) 
			permutation_tracker <= 1'b0;
		else if (hvout_fire) 
			permutation_tracker <= ~permutation_tracker;
	end

	integer i;
	always @(posedge clk) begin
		if (rst || hvout_fire) begin
			permutations_1 <= {`NGRAM_SIZE{1'b0}};
			permutations_0 <= {`NGRAM_SIZE{1'b0}};
			for (i = 0; i < `NGRAM_SIZE; i = i + 1) ngram[i] <= {`HV_DIMENSION{1'b0}};
		end
		else if (hvin_fire) begin
			if (classification_counter_delay == 0) begin
				if (permutation_tracker) 
					permutations_1[1:0] <= hvin[1:0];
				else 
					permutations_0[1:0] <= hvin[1:0];
			end else if (classification_counter_delay == 1) begin
				if (permutation_tracker) 
					permutations_1[2] <= hvin[0];
				else 
					permutations_0[2] <= hvin[0];
			end

			ngram[0] <= hvin;

			if (classification_counter_delay == 1)
				ngram[1] <= (permutation_tracker) ? {permutations_0[0], ngram[0] >> 1} : {permutations_1[0], ngram[0] >> 1};
			else if (classification_counter_delay == 2)
				ngram[1] <= (permutation_tracker) ? {permutations_0[2], ngram[0] >> 1} : {permutations_1[2], ngram[0] >> 1};

			if (classification_counter_delay == 2)
				ngram[2] <= (permutation_tracker) ? {permutations_0[1], ngram[1] >> 1} : {permutations_1[1], ngram[1] >> 1};
		end
	end

	// We fill in the hvout from most-significant FOLD to least-significant FOLD
	integer j; 
	always @(posedge clk) begin
		if (counter == 1) begin
			for (j = 0; j < FOLD_WIDTH; j = j + 1) hvout[j] <= ngram[0][j] ^ ngram[1][j] ^ ngram[2][j];
		end
	end

endmodule : temporal_encoder
