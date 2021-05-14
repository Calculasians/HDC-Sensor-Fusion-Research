`include "const.vh"

module hv_generator_serial_circular #(
	parameter NUM_FOLDS, // 1 means no folding. Equivalent to #accumulators
	parameter NUM_FOLDS_WIDTH, // ceillog(NUM_FOLDS)
	parameter FOLD_WIDTH,  // 2000 means no folding. FOLD_WIDTH should be a factor of 2000
	parameter SRAM_ADDR_WIDTH
) (
	input 		clk,
	input 		rst,

	input 		fin_valid, 
	output 		fin_ready,
	input 		[`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0],

	output 		dout_valid,
	input 		dout_ready,
	output 		[FOLD_WIDTH-1:0] im_out,
	output	 	[FOLD_WIDTH-1:0] projm_out,

	// MEMORY_WRAPPER signals
	input 		we,
	input 		[SRAM_ADDR_WIDTH-1:0] im_write_addr,
	input 		[FOLD_WIDTH-1:0] im_din
);

	localparam 	projm_pos = `SEED_HV;
	localparam 	projm_neg = {projm_pos[`HV_DIMENSION-2:0],projm_pos[`HV_DIMENSION-1]} ^ {projm_pos[0],projm_pos[`HV_DIMENSION-1:1]};

	wire 		fin_fire;

	reg			[`CHANNEL_WIDTH-1:0] 			feature_memory [`TOTAL_NUM_CHANNEL-1:0];
	reg 		[NUM_FOLDS_WIDTH-1:0]			fold_counter;
	reg 		[`MAX_NUM_CHANNEL_WIDTH-1:0] 	channel_counter;
	wire		[FOLD_WIDTH-1:0] 				im;
	reg 		[`HV_DIMENSION-1:0] 			projm;

	reg  		[SRAM_ADDR_WIDTH-1:0]			im_read_addr;
	wire  		[SRAM_ADDR_WIDTH-1:0]			im_addr;

	reg			[1:0] 							curr_state;
	localparam 	IDLE 		= 2'b00;
	localparam 	PROCESS_GSR = 2'b01;
	localparam 	PROCESS_ECG = 2'b11;
	localparam 	PROCESS_EEG = 2'b10; 

	assign fin_fire = fin_valid && fin_ready;

	assign im_addr 	= (~we) ? im_write_addr : im_read_addr;

	memory_wrapper #(
		.FOLD_WIDTH			(FOLD_WIDTH),
		.SRAM_ADDR_WIDTH	(SRAM_ADDR_WIDTH)
	) MW (
		.clk 				(clk),
		.we					(we),

		.im_addr 			(im_addr),
		.im_din 			(im_din),
		.im_dout 			(im)
	);

	integer i;
	always @(posedge clk) begin
		if (rst) begin
			curr_state 		<= IDLE;
			fold_counter 	<= 0;
			channel_counter	<= 0; 
			im_read_addr	<= 0;
		end

		case (curr_state)
			IDLE: begin
				if (fin_fire) begin
					curr_state		<= PROCESS_GSR;

					im_read_addr	<= 1;
					fold_counter 	<= 0;
					channel_counter <= 0;
					for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) feature_memory[i] <= features[i];
				end
			end

			PROCESS_GSR: begin
				if (channel_counter == `GSR_NUM_CHANNEL) begin
					channel_counter <= 0;
					curr_state 		<= PROCESS_ECG;
				end else begin
					channel_counter <= channel_counter + 1;
				end

				if (channel_counter != `GSR_NUM_CHANNEL-2) begin
					im_read_addr	<= im_read_addr + 1;
				end
			end

			PROCESS_ECG: begin
				if (channel_counter == `ECG_NUM_CHANNEL) begin
					channel_counter <= 0;
					curr_state 		<= PROCESS_EEG;
				end else begin
					channel_counter <= channel_counter + 1;
				end

				if (channel_counter != `ECG_NUM_CHANNEL-2) begin 
					im_read_addr	<= im_read_addr + 1;
				end
			end

			PROCESS_EEG: begin
				if (channel_counter == `EEG_NUM_CHANNEL) begin
					if (fold_counter == NUM_FOLDS-1) begin
						fold_counter 	<= 0;
						curr_state 		<= IDLE;
					end else begin
						fold_counter 	<= fold_counter + 1;
						curr_state 		<= PROCESS_GSR;
					end

					channel_counter <= 0;
				end else begin
					channel_counter <= channel_counter + 1;
				end

				if (channel_counter != `EEG_NUM_CHANNEL-2) begin
					if (channel_counter == `EEG_NUM_CHANNEL && fold_counter == NUM_FOLDS-1) 
						im_read_addr 	<= 0;
					else if (channel_counter == `EEG_NUM_CHANNEL-1 && fold_counter == NUM_FOLDS-1) // prevent im_addr overflow
						im_read_addr 	<= 0;
					else
						im_read_addr 	<= im_read_addr + 1;
				end
			end

		endcase
	end

	always @(*) begin
		if (curr_state == PROCESS_GSR) begin
			if (feature_memory[channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (curr_state == PROCESS_ECG) begin
			if (feature_memory[`GSR_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[`GSR_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
		else if (curr_state == PROCESS_EEG) begin
			if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 1)
				projm = projm_pos;
			else if (feature_memory[`GSR_NUM_CHANNEL + `ECG_NUM_CHANNEL + channel_counter] == 2)
				projm = projm_neg;
			else
				projm = {`HV_DIMENSION{1'b0}};
		end
	end

	assign fin_ready 	= (curr_state == IDLE);
	assign dout_valid 	= (curr_state != IDLE);

	assign im_out 		= im;
	assign projm_out 	= projm[(fold_counter * FOLD_WIDTH) +: FOLD_WIDTH];

endmodule : hv_generator_serial_circular

