`timescale 1ns / 1ps
`include "const.vh"

module hdc_sensor_fusion_tb;

	localparam num_entry				= 10;
	localparam max_wait_time			= 128;
	localparam total_hv					= 23;
	localparam max_wait_time_width		= `ceilLog2(max_wait_time);

	reg clk, rst;

	initial clk = 0;
	initial rst = 0;
	always #(`CLOCK_PERIOD/2) clk = ~clk;

	reg  [`TOTAL_NUM_CHANNEL*`CHANNEL_WIDTH-1:0] features_top;
	reg  fin_valid;
	wire fin_ready;

	wire dout_valid;
	reg  dout_ready;
	wire valence;
	wire arousal;

	reg  write_enable;
	reg  write_enable_valid;

	reg  [2:0] addr_1;
	reg  [`HV_DIMENSION-1:0] hv_1;

	reg  [2:0] addr_2;
	reg  [`HV_DIMENSION-1:0] hv_2;

	reg  [2:0] addr_3;
	reg  [`HV_DIMENSION-1:0] hv_3;

	hdc_sensor_fusion dut (
		.clk				(clk),
		.rst				(rst),
		
		.features_top		(features_top),
		.fin_valid			(fin_valid),
		.fin_ready			(fin_ready),

		.valence			(valence),
		.arousal			(arousal),
		.dout_valid			(dout_valid),
		.dout_ready			(dout_ready),

		.write_enable		(write_enable),
		.write_enable_valid	(write_enable_valid),

		.addr_1				(addr_1),
		.hv_1				(hv_1),

		.addr_2				(addr_2),
		.hv_2				(hv_2),

		.addr_3				(addr_3),
		.hv_3				(hv_3)
	);

	//-------//
	// Files //
	//-------//

	integer hv_file;
	integer feature_file;
	integer expected_v_file;
	integer expected_a_file;

	integer get_hv;
	integer get_feature;
	integer get_expected_v;
	integer get_expected_a;

	//--------//
	// Memory //
	//--------//

	reg  [`HV_DIMENSION-1:0] hv_memory[total_hv-1:0];
	reg  [`TOTAL_NUM_CHANNEL*`CHANNEL_WIDTH-1:0] feature_memory[num_entry-1:0];
	reg  expected_v_memory[num_entry-1:0];
	reg  expected_a_memory[num_entry-1:0];

	//------------//
	// Statistics //
	//------------//

	integer num_fail                  = 0;

	integer fin_valid_high_ready_low  = 0;
	integer fin_valid_low_ready_high  = 0;
	integer dout_valid_high_ready_low = 0;
	integer dout_valid_low_ready_high = 0;

	integer start_time[num_entry-1:0];
	integer end_time[num_entry-1:0];
	integer cycle                     = 0;

	integer done = 0;
	integer total = 0;
	integer i;

	initial begin
		$vcdpluson;
		$set_toggle_region(dut);
		$toggle_start();

		initialize_memory();

		fin_valid  = 1'b0;
		dout_ready = 1'b0;

		repeat (2) @(posedge clk);
		rst = 1'b1;
		repeat (5) @(posedge clk);
		rst = 1'b0;
		repeat (2) @(posedge clk);

		write_srams();

		fork
			start_fin_sequence();
			start_fin_monitor();

			start_dout_sequence();
			start_dout_monitor();

			start_cycle_counter();
		join

		$display("Statistics:\n");
		$display("fin_valid_high_ready_low  = %d\n", fin_valid_high_ready_low);
		$display("fin_valid_low_ready_high  = %d\n", fin_valid_low_ready_high);
		$display("dout_valid_high_ready_low = %d\n", dout_valid_high_ready_low);
		$display("dout_valid_low_ready_high = %d\n", dout_valid_low_ready_high);

		for (i = 0; i < num_entry; i = i + 1) begin
			$display("Time taken to process entry %d : %d\n", i, end_time[i] - start_time[i]);
			total = total + end_time[i] - start_time[i];
		end
		$display("Average time taken to process a SINGLE entry : %d\n", total / num_entry);

		if (num_fail == 0)
			$display("All entries matched!\n");
		else
			$display("%d entries does not matched\n\n!", num_fail);

		$toggle_stop();
		$toggle_report("../../build/sim-par-rundir/hdc_sensor_fusion.saif", 1.0e-9, dut);
		$vcdplusoff;
		$finish();
	end

	function void initialize_memory();
		integer i, j, k;

		hv_file			= $fopen("../../src/HDC_Sensor_Fusion_3M1P/23hv.txt","r");
		feature_file	= $fopen("../../src/HDC_Sensor_Fusion_3M1P/feature_binary.txt","r");
		expected_v_file	= $fopen("../../src/HDC_Sensor_Fusion_3M1P/expected_v.txt","r");
		expected_a_file	= $fopen("../../src/HDC_Sensor_Fusion_3M1P/expected_a.txt","r");

		if (hv_file == 0 || feature_file == 0 || expected_v_file == 0 || expected_a_file == 0) begin
			$display("Data Fetch Error");
			$finish();
		end

		for (k = 0; k < total_hv; k = k + 1) begin
			get_hv = $fscanf(hv_file, "%b\n", hv_memory[k]);
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_feature = $fscanf(feature_file, "%b\n", feature_memory[i]);
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_expected_v	= $fscanf(expected_v_file, "%b\n", expected_v_memory[i]);
			get_expected_a	= $fscanf(expected_a_file, "%b\n", expected_a_memory[i]);
		end

	endfunction : initialize_memory

	task write_srams;
		integer i = 0;

		@(negedge clk);

		write_enable_valid = 1'b1;
		write_enable = 1'b0;

		@(negedge clk);

		addr_1 = 3'b000;
		addr_2 = 3'b000;
		addr_3 = 3'b000;
		hv_1   = hv_memory[1];	// B
		hv_2   = hv_memory[0];	// A
		hv_3   = hv_memory[4];	// E

		@(negedge clk);

		addr_1 = 3'b001;
		addr_2 = 3'b001;
		addr_3 = 3'b001;
		hv_1   = hv_memory[2];	// C
		hv_2   = hv_memory[3];	// D
		hv_3   = hv_memory[7];	// H

		@(negedge clk);

		addr_1 = 3'b010;
		addr_2 = 3'b010;
		addr_3 = 3'b010;
		hv_1   = hv_memory[5];	// F
		hv_2   = hv_memory[6];	// G
		hv_3   = hv_memory[10];	// K

		@(negedge clk);

		addr_1 = 3'b011;
		addr_2 = 3'b011;
		addr_3 = 3'b011;
		hv_1   = hv_memory[8];	// I
		hv_2   = hv_memory[9];	// J
		hv_3   = hv_memory[13];	// N

		@(negedge clk);

		addr_1 = 3'b100;
		addr_2 = 3'b100;
		addr_3 = 3'b100;
		hv_1   = hv_memory[11];	// L
		hv_2   = hv_memory[12];	// M
		hv_3   = hv_memory[16];	// Q

		@(negedge clk);

		addr_1 = 3'b101;
		addr_2 = 3'b101;
		addr_3 = 3'b101;
		hv_1   = hv_memory[14];	// O
		hv_2   = hv_memory[15];	// P
		hv_3   = hv_memory[19];	// T

		@(negedge clk);

		addr_1 = 3'b110;
		addr_2 = 3'b110;
		addr_3 = 3'b110;
		hv_1   = hv_memory[17];	// R
		hv_2   = hv_memory[18];	// S
		hv_3   = hv_memory[22];	// W

 		@(negedge clk);

		addr_1 = 3'b111;
		addr_2 = 3'b111;
		addr_3 = 3'b111;
		hv_1   = hv_memory[20];	// U
		hv_2   = hv_memory[21];	// V
		hv_3   = {`HV_DIMENSION{1'b0}};

		@(negedge clk);

		write_enable = 1'b1;
      
		@(negedge clk);

		write_enable_valid = 1'b0;

		@(posedge clk);
		@(posedge clk);

	endtask : write_srams

	task start_cycle_counter;
		while (done == 0) begin
			@(negedge clk)
			cycle = cycle + 1;
		end
	endtask : start_cycle_counter

	task start_fin_sequence;

		integer i = 0;
		integer j;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			do_wait = $random() % 4;
			if (do_wait < 2) begin
				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);
			end

			fin_valid = 1'b1;

			features_top = feature_memory[i];

			@(negedge clk);
			if (fin_ready) begin
				@(posedge clk); // add this during post-par sim
				i = i + 1;
				$display("Starting iteration %d", i);
			end

			@(posedge clk);
			fin_valid = 1'b0;

		end

	endtask : start_fin_sequence

	task start_fin_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge clk);
			//@(posedge clk);

			if (fin_valid && ~fin_ready) fin_valid_high_ready_low = fin_valid_high_ready_low + 1;
			if (~fin_valid && fin_ready) fin_valid_low_ready_high = fin_valid_low_ready_high + 1;
			if (fin_valid && fin_ready) begin
				start_time[i] = cycle;
				i = i + 1;
				@(posedge clk); // add these 2 posedge clks during post-par sim
				@(posedge clk);
			end

		end

	endtask : start_fin_monitor

	task start_dout_sequence;

		integer i = 0;

		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			wait_time = $random() % max_wait_time;
			repeat (wait_time) @(posedge dut.AM.clk);

			dout_ready = 1'b1;

			@(negedge dut.AM.clk);

			if (dout_valid) i = i + 1;

			@(posedge dut.AM.clk);
			dout_ready = 1'b0;

		end

	endtask : start_dout_sequence

	task start_dout_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge dut.AM.clk);

			if (dout_valid && ~dout_ready) dout_valid_high_ready_low = dout_valid_high_ready_low + 1;
			if (~dout_valid && dout_ready) dout_valid_low_ready_high = dout_valid_low_ready_high + 1;

			if (dout_valid && dout_ready) begin
				end_time[i] = cycle;

				if (valence != expected_v_memory[i]) begin
					$display("Output %d does not match the expected VALENCE label", i);
					$display("Label %d: \n%b,\nExpected Label: \n%b\n", i, valence, expected_v_memory[i]);
					num_fail = num_fail + 1;
				end

				if (arousal != expected_a_memory[i]) begin
					$display("Output %d does not match the expected AROUSAL label", i);
					$display("Label %d: \n%b,\nExpected Label: \n%b\n", i, arousal, expected_a_memory[i]);
					num_fail = num_fail + 1;
				end

				i = i + 1;
			end

		end

		done = 1;

	endtask : start_dout_monitor

endmodule : hdc_sensor_fusion_tb
