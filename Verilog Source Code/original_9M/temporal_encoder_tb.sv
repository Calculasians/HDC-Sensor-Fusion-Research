`timescale 1ps / 1ps
`include "const.vh"

module temporal_encoder_tb;

	localparam num_entry			= 380;
	localparam max_wait_time		= 16;
	localparam max_wait_time_width	= `ceilLog2(max_wait_time);

	reg  clk, rst;

	initial clk = 0;
	initial rst = 0;
	always #(5) clk = ~clk;

	// Inputs
	reg  hvin_valid;
	wire hvin_ready;
	reg  [`HV_DIMENSION-1:0] hvin;
	
	// Outputs
	wire hvout_valid;
	reg  hvout_ready;
	wire [`HV_DIMENSION-1:0] hvout;

	temporal_encoder dut (
		.clk			(clk),
		.rst			(rst),

		.hvin_valid		(hvin_valid),
		.hvin_ready		(hvin_ready),
		.hvin			(hvin),

		.hvout_valid	(hvout_valid),
		.hvout_ready	(hvout_ready),
		.hvout			(hvout)
	);

	//-------//
	// Files //
	//-------//

	integer input_file;
	integer expected_output_file;

	integer get_input;
	integer get_expected_output;

	//--------//
	// Memory //
	//--------//

	reg [`HV_DIMENSION-1:0] input_memory[num_entry-1:0];
	reg [`HV_DIMENSION-1:0] expected_output_memory[num_entry-1:0];

	//------------//
	// Statistics //
	//------------//

	integer hvin_valid_high_ready_low  = 0;
	integer hvin_valid_low_ready_high  = 0;
	integer hvout_valid_high_ready_low = 0;
	integer hvout_valid_low_ready_high = 0;

	integer num_fail                   = 0;

	initial begin
		hvin_valid  = 1'b0;
		hvout_ready = 1'b0;

		initialize_memory();

		repeat (2) @(posedge clk);
		rst = 1'b1;
		repeat (5) @(posedge clk);
		rst = 1'b0;
		repeat (2) @(posedge clk);

		fork
			start_hvin_sequence();
			start_hvin_monitor();

			start_hvout_sequence();
			start_hvout_monitor();
		join

		$display("Statistics:\n");
		if (num_fail == 0)
			$display("All entries matched!\n");
		else
			$display("%d entries does not matched\n\n!", num_fail);

		$display("hvin_valid_high_ready_low  = %d\n", hvin_valid_high_ready_low);
		$display("hvin_valid_low_ready_high  = %d\n", hvin_valid_low_ready_high);
		$display("hvout_valid_high_ready_low = %d\n", hvout_valid_high_ready_low);
		$display("hvout_valid_low_ready_high = %d\n", hvout_valid_low_ready_high);

		$finish();
	end

	function void initialize_memory();
		integer i;

		input_file            = $fopen("output_R_fused_D_2000_imrandom", "r");
		expected_output_file  = $fopen("output_T_D_2000_imrandom", "r");

		if (input_file == 0 || expected_output_file == 0) begin
			$display("Data Fetch Error");
			$finish();
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_input           = $fscanf(input_file, "%b\n", input_memory[i]);
			get_expected_output = $fscanf(expected_output_file, "%b\n", expected_output_memory[i]);
		end

	endfunction : initialize_memory

	task start_hvin_sequence;

		integer i = 0;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			do_wait = $random() % 4;
			if (do_wait < 2) begin
				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);
			end

			hvin_valid = 1'b1;
			hvin       = input_memory[i];

			@(negedge clk);
			if (hvin_ready) i = i + 1;

			@(posedge clk);
			hvin_valid = 1'b0;

		end

	endtask : start_hvin_sequence

	task start_hvin_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge clk);

			if (hvin_valid && ~hvin_ready) hvin_valid_high_ready_low = hvin_valid_high_ready_low + 1;
			if (~hvin_valid && hvin_ready) hvin_valid_low_ready_high = hvin_valid_low_ready_high + 1;
			if (hvin_valid && hvin_ready)  i = i + 1;

		end

	endtask : start_hvin_monitor

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

endmodule : temporal_encoder_tb