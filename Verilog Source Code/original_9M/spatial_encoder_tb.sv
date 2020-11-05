`timescale 1ps / 1ps
`include "const.vh"

module spatial_encoder_tb;

	localparam num_channel         = 32;
	localparam num_entry           = 380;
	localparam max_wait_time       = 16;
	localparam max_wait_time_width = `ceilLog2(max_wait_time);

	reg  clk, rst;

	initial clk = 0;
	initial rst = 0;
	always #(5) clk = ~clk;

	// Inputs
	reg  din_valid;
	wire din_ready;
	reg  [`HV_DIMENSION-1:0] im;
	reg  [`HV_DIMENSION-1:0] projm;
	
	// Outputs
	wire hvout_valid;
	reg  hvout_ready;
	wire [`HV_DIMENSION-1:0] hvout;

	spatial_encoder #(.num_channel(num_channel)) dut (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(din_valid),
		.din_ready		(din_ready),
		.im				(im),
		.projm			(projm),

		.hvout_valid	(hvout_valid),
		.hvout_ready	(hvout_ready),
		.hvout			(hvout)
	);

	//-------//
	// Files //
	//-------//

	integer im_file;
	integer feature_file;
	integer projm_pos_file;
	integer projm_neg_file;
	integer expected_output_file;

	integer get_im;
	integer get_feature;
	integer get_projm_pos;
	integer get_projm_neg;
	integer get_expected_output;

	//--------//
	// Memory //
	//--------//

	integer feature_memory[num_entry-1:0][num_channel-1:0];
	reg     [`HV_DIMENSION-1:0] projm_pos_memory[num_channel-1:0];
	reg     [`HV_DIMENSION-1:0] projm_neg_memory[num_channel-1:0];
	reg     [`HV_DIMENSION-1:0] item_memory[num_channel-1:0];
	reg     [`HV_DIMENSION-1:0] expected_output_memory[num_entry-1:0];

	//------------//
	// Statistics //
	//------------//

	integer din_valid_high_ready_low   = 0;
	integer din_valid_low_ready_high   = 0;
	integer hvout_valid_high_ready_low = 0;
	integer hvout_valid_low_ready_high = 0;

	integer num_fail                   = 0;

	initial begin
		din_valid   = 1'b0;
		hvout_ready = 1'b0;

		initialize_memory();

		repeat (2) @(posedge clk);
		rst = 1'b1;
		repeat (5) @(posedge clk);
		rst = 1'b0;
		repeat (2) @(posedge clk);

		fork
			start_din_sequence();
			start_din_monitor();

			start_hvout_sequence();
			start_hvout_monitor();
		join

		$display("Statistics:\n");
		if (num_fail == 0)
			$display("All entries matched!\n");
		else
			$display("%d entries does not matched\n\n!", num_fail);

		$display("din_valid_high_ready_low   = %d\n", din_valid_high_ready_low);
		$display("din_valid_low_ready_high   = %d\n", din_valid_low_ready_high);
		$display("hvout_valid_high_ready_low = %d\n", hvout_valid_high_ready_low);
		$display("hvout_valid_low_ready_high = %d\n", hvout_valid_low_ready_high);

		$finish();
	end

	function void initialize_memory();
		integer i, j;

		im_file					= $fopen("im", "r");
		feature_file			= $fopen("GSR_fm", "r");
		projm_pos_file			= $fopen("GSR_proj_pos_D_2000_imrandom", "r");
		projm_neg_file			= $fopen("GSR_proj_neg_D_2000_imrandom", "r");
		expected_output_file	= $fopen("GSR_output_R_D_2000_imrandom", "r");

		if (im_file == 0 || feature_file == 0 || projm_pos_file == 0 || projm_neg_file == 0 || expected_output_file == 0) begin
			$display("Data Fetch Error");
			$finish();
		end

		for (j = 0; j < num_channel; j = j + 1) begin
			get_im        = $fscanf(im_file, "%b\n", item_memory[j]);
			get_projm_pos = $fscanf(projm_pos_file, "%b\n", projm_pos_memory[j]);
			get_projm_neg = $fscanf(projm_neg_file, "%b\n", projm_neg_memory[j]);
		end

		for (i = 0; i < num_entry; i = i + 1) begin

			for (j = 0; j < num_channel; j = j + 1) begin
				get_feature          = $fgetc(feature_file);
				feature_memory[i][j] = (get_feature == 50) ? 2'b10 : (get_feature == 49) ? 2'b01 : 2'b00;
			end
			get_feature = $fgetc(feature_file); // should be a '\n' character

			get_expected_output = $fscanf(expected_output_file, "%b\n", expected_output_memory[i]);
		end

	endfunction : initialize_memory

	task start_din_sequence;

		integer i, j;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;

		for (i = 0; i < num_entry; i = i + 1) begin

			j = 0;
			while (j < num_channel) begin

				do_wait = $random() % 4;
				if (do_wait < 2) begin
					wait_time = $random() % max_wait_time;
					repeat (wait_time) @(posedge clk);
				end
				din_valid = 1'b1;

				im = item_memory[j];

				if (feature_memory[i][j] == 2'b01)
					projm = projm_pos_memory[j];
				else if (feature_memory[i][j] == 2'b10)
					projm = projm_neg_memory[j];
				else
					projm = {`HV_DIMENSION{1'b0}};

				@(negedge clk);
				if (din_ready) j = j + 1;

				@(posedge clk);
				din_valid = 1'b0;

			end

		end

	endtask : start_din_sequence

	task start_din_monitor;

		integer i = 0;

		while (i < num_entry * num_channel) begin

			@(negedge clk);

			if (din_valid && ~din_ready) din_valid_high_ready_low = din_valid_high_ready_low + 1;
			if (~din_valid && din_ready) din_valid_low_ready_high = din_valid_low_ready_high + 1;
			if (din_valid && din_ready)  i = i + 1;

		end

	endtask : start_din_monitor

	task start_hvout_sequence;

		integer i = 0;

		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			wait_time = $random() % max_wait_time;
			repeat (wait_time) @(posedge clk);
			hvout_ready = 1'b1;

			@(negedge clk);
			if (hvout_valid) i = i + 1;

			@(posedge clk);
			hvout_ready = 1'b0;

		end

	endtask : start_hvout_sequence

	task start_hvout_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge clk);

			if (hvout_valid && ~hvout_ready) hvout_valid_high_ready_low = hvout_valid_high_ready_low + 1;
			if (~hvout_valid && hvout_ready) hvout_valid_low_ready_high = hvout_valid_low_ready_high + 1;

			if (hvout_valid && hvout_ready) begin
				if (hvout != expected_output_memory[i]) begin
					$display("Output %d does not match the expected hypervector", i);
					$display("HVout %d: \n%b,\nExpected HVout: \n%b\n", i, hvout, expected_output_memory[i]);
					num_fail = num_fail + 1;
				end
				i = i + 1;
			end

		end

	endtask : start_hvout_monitor

endmodule : spatial_encoder_tb