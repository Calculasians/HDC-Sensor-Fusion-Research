`include "const.vh"

module spatial_encoder #(
	parameter NUM_FOLDS, // 1 means no folding. Equivalent to #accumulators
	parameter NUM_FOLDS_WIDTH, // ceillog(NUM_FOLDS)
	parameter FOLD_WIDTH  // 2000 means no folding. FOLD_WIDTH should be a factor of 2000
) (
	input 								clk,
	input 								rst,

	input 								din_valid,
	output 								din_ready,
	input 		[FOLD_WIDTH-1:0]		im,
	input 		[FOLD_WIDTH-1:0]		projm,
	
	output 								hvout_valid,
	input 								hvout_ready,
	output reg 	[FOLD_WIDTH-1:0] 		hvout,
	output reg 	[NUM_FOLDS_WIDTH-1:0]	fold_counter,
	output reg							done
);

	wire 		din_fire;
	reg			last_hvout;
	wire 		[FOLD_WIDTH-1:0] 					binded_im_projm;
	reg 		[FOLD_WIDTH-1:0] 					final_hv;

	// fold & channel counters are delayed from hv_gen's counter versions
	// fuser needs fold counter to decide which section of fuser.hvout to fill
	reg 		[`MAX_NUM_CHANNEL_WIDTH-1:0] 		channel_counter;
	reg 		[`MAX_HALF_NUM_CHANNEL_WIDTH-1:0]	accumulator [FOLD_WIDTH-1:0];

	reg			[1:0] 								curr_state;
	localparam 	IDLE 		= 2'b00;
	localparam 	PROCESS_GSR = 2'b01;
	localparam 	PROCESS_ECG = 2'b11;
	localparam 	PROCESS_EEG = 2'b10;

	assign din_fire = din_valid && din_ready;

	assign binded_im_projm = im ^ projm;

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			curr_state <= IDLE;
		end

		case (curr_state)
			IDLE: begin
				done <= 1'b0;

				if (din_fire) begin
					curr_state 		<= PROCESS_GSR;

					fold_counter 	<= 0; 
					channel_counter <= 0;
					for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
				end
			end

			PROCESS_GSR: begin
				if (channel_counter == 0) 
					final_hv <= binded_im_projm;
				else if (channel_counter == `GSR_NUM_CHANNEL-2) 
					final_hv <= final_hv ^ binded_im_projm;


				if (channel_counter == `GSR_NUM_CHANNEL) begin  // at cycle 32, we should do the majority count for hvout
					if (fold_counter == NUM_FOLDS-1) begin
						fold_counter 	<= 0;
						curr_state 		<= PROCESS_ECG;
					end else begin
						fold_counter 	<= fold_counter + 1;
					end

					for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					channel_counter <= 0;

				end else if (channel_counter == `GSR_NUM_CHANNEL-1) begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_GSR_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, final_hv[i]};
					end
					channel_counter <= channel_counter + 1;

				end else begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_GSR_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					end
					channel_counter <= channel_counter + 1;
				end
			end

			PROCESS_ECG: begin
				if (channel_counter == 0) 
					final_hv <= binded_im_projm;
				else if (channel_counter == `ECG_NUM_CHANNEL-2) 
					final_hv <= final_hv ^ binded_im_projm;


				if (channel_counter == `ECG_NUM_CHANNEL) begin  // at cycle 77, we should do the majority count for hvout
					if (fold_counter == NUM_FOLDS-1) begin
						fold_counter 	<= 0;
						curr_state 		<= PROCESS_EEG;
					end else begin
						fold_counter 	<= fold_counter + 1;
					end
					for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					channel_counter <= 0;

				end else if (channel_counter == `ECG_NUM_CHANNEL-1) begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_ECG_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, final_hv[i]};
					end
					channel_counter <= channel_counter + 1;

				end else begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_ECG_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					end
					channel_counter <= channel_counter + 1;
				end
			end

			PROCESS_EEG: begin
				if (channel_counter == 0) 
					final_hv <= binded_im_projm;
				else if (channel_counter == `EEG_NUM_CHANNEL-2) 
					final_hv <= final_hv ^ binded_im_projm;


				if (channel_counter == `EEG_NUM_CHANNEL) begin  // at cycle 105, we should do the majority count for hvout
					if (fold_counter == NUM_FOLDS-1) begin
						fold_counter 	<= 0;
						done			<= 1'b1;
						curr_state 		<= IDLE;
					end else begin
						fold_counter 	<= fold_counter + 1;
					end
					for (i = 0; i < FOLD_WIDTH; i = i + 1) accumulator[i] <= {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					channel_counter <= 0;

				end else if (channel_counter == `EEG_NUM_CHANNEL-1) begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_EEG_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, final_hv[i]};
					end
					channel_counter <= channel_counter + 1;

				end else begin
					for (i = 0; i < FOLD_WIDTH; i = i + 1) begin
						if (accumulator[i] <= `HALF_EEG_NUM_CHANNEL) accumulator[i] <= accumulator[i] + {{`MAX_HALF_NUM_CHANNEL_WIDTH-1{1'b0}}, binded_im_projm[i]};
					end
					channel_counter <= channel_counter + 1;
				end
			end

		endcase
	end

	assign din_ready 	= (curr_state == IDLE);
	assign hvout_valid 	= (curr_state == PROCESS_GSR && channel_counter == `GSR_NUM_CHANNEL) ||
						  (curr_state == PROCESS_ECG && channel_counter == `ECG_NUM_CHANNEL) ||
						  (curr_state == PROCESS_EEG && channel_counter == `EEG_NUM_CHANNEL);

	integer j;
	always @(*) begin
		if (curr_state == PROCESS_GSR)   // hvout section coming out depends on the fold, fuser must be aware of which fold
			for (j = 0; j < FOLD_WIDTH; j = j + 1) hvout[j] = (accumulator[j] > `HALF_GSR_NUM_CHANNEL) ? 1'b1 : 1'b0;
		else if (curr_state == PROCESS_ECG)
			for (j = 0; j < FOLD_WIDTH; j = j + 1) hvout[j] = (accumulator[j] > `HALF_ECG_NUM_CHANNEL) ? 1'b1 : 1'b0;
		else if (curr_state == PROCESS_EEG)
			for (j = 0; j < FOLD_WIDTH; j = j + 1) hvout[j] = (accumulator[j] > `HALF_EEG_NUM_CHANNEL) ? 1'b1 : 1'b0;
	end

endmodule : spatial_encoder
