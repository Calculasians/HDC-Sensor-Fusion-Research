`include "const.vh"

module hv_generator #(
	parameter NUM_FOLDS, // 1 means no folding. Equivalent to #accumulators
	parameter NUM_FOLDS_WIDTH, // ceillog(NUM_FOLDS)
	parameter FOLD_WIDTH  // 2000 means no folding. FOLD_WIDTH should be a factor of 2000
) (
	input 		clk,
	input 		rst,

	input 		fin_valid, 
	output 		fin_ready,
	input 		[`CHANNEL_WIDTH-1:0] features [2:0][`TOTAL_NUM_CHANNEL-1:0],

	output 		dout_valid,
	input 		dout_ready,
	output 		[FOLD_WIDTH-1:0] im_out,
	output	 	[FOLD_WIDTH-1:0] projm_out
);

	localparam 	projm_pos = `SEED_HV;
	localparam 	projm_neg = (projm_pos << 1) ^ (projm_pos >> 1);

	wire 		fin_fire;

	reg 		[`CHANNEL_WIDTH-1:0] 			feature_memory [2:0][`TOTAL_NUM_CHANNEL-1:0];

	reg			[1:0]							classification_counter;
	reg 		[NUM_FOLDS_WIDTH-1:0]			fold_counter;
	reg 		[`MAX_NUM_CHANNEL_WIDTH-1:0] 	channel_counter;
	reg			[FOLD_WIDTH-1:0] 				im;
	reg 		[`HV_DIMENSION-1:0] 			projm;

	reg			[1:0] 							curr_state;
	localparam 	IDLE 		= 2'b00;
	localparam 	PROCESS_GSR = 2'b01;
	localparam 	PROCESS_ECG = 2'b11;
	localparam 	PROCESS_EEG = 2'b10; 

	assign fin_fire = fin_valid && fin_ready;


	integer i;
	integer j;
	always @(posedge clk) begin
		if (rst) begin
			curr_state 				<= IDLE;
			classification_counter	<= 0;
			fold_counter 			<= NUM_FOLDS-1;
			channel_counter			<= 0;
		end

		case (curr_state)
			IDLE: begin
				if (fin_fire) begin
					curr_state				<= PROCESS_GSR;

					// syntax is im[variable starting pos +: constant width] 
					im						<= (projm_neg[((NUM_FOLDS-1) * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[((NUM_FOLDS-1) * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
					classification_counter	<= 0;
					fold_counter 			<= NUM_FOLDS-1;
					channel_counter 		<= 0;
					for (i = 0; i < 3; i = i + 1) begin
						for (j = 0; j < `TOTAL_NUM_CHANNEL; j = j + 1) begin
							feature_memory[i][j] <= features[i][j];
						end
					end
				end
			end

			PROCESS_GSR: begin
				if (channel_counter == `GSR_NUM_CHANNEL) begin
					im 				<= (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
					channel_counter <= 0;
					curr_state 		<= PROCESS_ECG;
				end else begin
					im				<= (im << 1) ^ (im >> 1);
					channel_counter <= channel_counter + 1;
				end	
			end

			PROCESS_ECG: begin
				if (channel_counter == `ECG_NUM_CHANNEL) begin
					im 				<= (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
					channel_counter <= 0;
					curr_state 		<= PROCESS_EEG;
				end else begin
					im				<= (im << 1) ^ (im >> 1);
					channel_counter <= channel_counter + 1;
				end
			end

			PROCESS_EEG: begin
				if (channel_counter == `EEG_NUM_CHANNEL) begin
					if (fold_counter == 0 && classification_counter == 2) begin
						classification_counter 	<= 0;
						fold_counter 			<= NUM_FOLDS-1;
						curr_state 				<= IDLE;
						im 						<= (projm_neg[((NUM_FOLDS-1) * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[((NUM_FOLDS-1) * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
					end else begin
						curr_state 				<= PROCESS_GSR;
						if (classification_counter == 2) begin
							classification_counter 	<= 0;
							fold_counter 			<= fold_counter - 1;
							im 						<= (projm_neg[((fold_counter-1) * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[((fold_counter-1) * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
						end else begin
							classification_counter 	<= classification_counter + 1;
							im 						<= (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] << 1) ^ (projm_neg[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH] >> 1);
						end
					end

					channel_counter <= 0;
				end else begin
					im				<= (im << 1) ^ (im >> 1);
					channel_counter <= channel_counter + 1;
				end
			end

		endcase
	end

	always @(*) begin
		if (curr_state == PROCESS_GSR) begin
			if (feature_memory[classification_counter][channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[classification_counter][channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (curr_state == PROCESS_ECG) begin
			if (feature_memory[classification_counter][`GSR_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[classification_counter][`GSR_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (curr_state == PROCESS_EEG) begin
			if (feature_memory[classification_counter][`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[classification_counter][`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
	end

	assign fin_ready 	= (curr_state == IDLE);
	assign dout_valid 	= (curr_state != IDLE);

	assign im_out 		= im; 
	assign projm_out 	= projm[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH];

endmodule : hv_generator
