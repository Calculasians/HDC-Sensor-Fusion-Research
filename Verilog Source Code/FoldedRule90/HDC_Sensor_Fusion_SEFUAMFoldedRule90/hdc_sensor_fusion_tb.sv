`timescale 1ns / 1ps
`include "const.vh"
`define GL_SIM 1 // keep if doing gate-level simulation
//`define FIN_USE_1MS_TARGET // keep if asserting fin_fire only at every 1ms. Comment out if you want to assert fin_fire at random intervals maxed by max_wait_time

// 1 if generating 214 unique ims and using circular shifts, 
// 0 if resetting im generation at the beginning of each modality
// change this in hdc_sensor_fusion.sv as well
`define SERIAL_CIRCULAR 1;

module hdc_sensor_fusion_tb;
 
	localparam num_entry				= 20;
	localparam max_wait_time			= 0;  // set to 0 to not wait between classifications
	localparam max_wait_time_width		= `ceilLog2(max_wait_time);

	// Should be a factor of 2000 (or `HV_DIMENSION)
	localparam num_folds 	= 4;
	localparam am_num_folds = 200;

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

	hdc_sensor_fusion
	`ifndef GL_SIM
	   #(	
            .NUM_FOLDS          (num_folds),
			.AM_NUM_FOLDS		(am_num_folds)
        ) dut (
	`else
		dut (
	`endif
		.clk				(clk),
		.rst				(rst),

		.features_top		(features_top),
		.fin_valid			(fin_valid),
		.fin_ready			(fin_ready),

		.valence			(valence),
		.arousal			(arousal),
		.dout_valid			(dout_valid),
		.dout_ready			(dout_ready)
	);

	//-------//
	// Files //
	//-------//
	
	integer power_yml_file;

	integer feature_file;
	string  expected_v_filename;
	string  expected_a_filename;
	integer expected_v_file;
	integer expected_a_file;

	integer get_feature;
	integer get_expected_v;
	integer get_expected_a;

	//--------//
	// Memory //
	//--------//

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
		$dumpfile("hdc_sensor_fusion.vcd");
		$dumpvars(1, hdc_sensor_fusion_tb.dut);
		$set_toggle_region(dut);
		$toggle_start();

		initialize_memory();

		@(posedge clk);

		fin_valid  = 1'b0;
		dout_ready = 1'b0;

		repeat (2) @(posedge clk);
		rst = 1'b1;
		repeat (5) @(posedge clk);
		rst = 1'b0;
		repeat (2) @(posedge clk);

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

		$display("Simulation ended at time : %0d ns\n", $time);
		write_power_yml_file();

		$toggle_stop();
		$toggle_report("../../build/sim-par-rundir/hdc_sensor_fusion.saif", 1.0e-9, dut);
		$vcdplusoff;
		$finish();
	end

	function void initialize_memory();
		integer i, j;

		feature_file	= $fopen("../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/feature_binary.txt","r");
		`ifdef SERIAL_CIRCULAR
		$sformat(expected_v_filename, "../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/expected_v_%0dfolds_serial_circular.txt", num_folds);
		$sformat(expected_a_filename, "../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/expected_a_%0dfolds_serial_circular.txt", num_folds);
		`else
		$sformat(expected_v_filename, "../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/expected_v_%0dfolds.txt", num_folds);
		$sformat(expected_a_filename, "../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/expected_a_%0dfolds.txt", num_folds);
		`endif
		expected_v_file	= $fopen(expected_v_filename,"r");
		expected_a_file	= $fopen(expected_a_filename,"r");

		if (feature_file == 0 || expected_v_file == 0 || expected_a_file == 0) begin
			$display("Data Fetch Error");
			$finish();
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_feature = $fscanf(feature_file, "%b\n", feature_memory[i]);
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_expected_v	= $fscanf(expected_v_file, "%b\n", expected_v_memory[i]);
			get_expected_a	= $fscanf(expected_a_file, "%b\n", expected_a_memory[i]);
		end

	endfunction : initialize_memory

	function void write_power_yml_file();
		power_yml_file = $fopen("../../src/HDC_Sensor_Fusion_SEFUAMFoldedRule90/hdc_sensor_fusion_power.yml","w");
		$fwrite(power_yml_file, "power.inputs.waveforms_meta: \"append\"\n");
		$fwrite(power_yml_file, "power.inputs.waveforms:\n");
		$fwrite(power_yml_file, "   - \"/tools/B/daniels/hammer-tsmc28/build/sim-par-rundir/hdc_sensor_fusion.vcd\"\n\n");
		$fwrite(power_yml_file, "power.inputs.database: \"/tools/B/daniels/hammer-tsmc28/build/par-rundir/latest\"\n");
		$fwrite(power_yml_file, "power.inputs.tb_name: \"hdc_sensor_fusion_tb\"\n\n");
		$fwrite(power_yml_file, "power.inputs.saifs_meta: \"append\"\n");
		$fwrite(power_yml_file, "power.inputs.saifs:\n");
		$fwrite(power_yml_file, "   - \"/tools/B/daniels/hammer-tsmc28/build/sim-par-rundir/hdc_sensor_fusion.saif\"\n\n");
		$fwrite(power_yml_file, "power.inputs.start_times: [\"0\"]\n");
		$fwrite(power_yml_file, "power.inputs.end_times: [\"%0d\"]\n", $time); 
		$fwrite(power_yml_file, "power.inputs.resolution: %0d", `CLOCK_PERIOD / 2);
		$fclose(power_yml_file);
	endfunction : write_power_yml_file

	task start_cycle_counter;
		while (done == 0) begin
			@(negedge clk)
			cycle = cycle + 1;
		end
	endtask : start_cycle_counter

	task start_fin_sequence;

		integer i = 0;

		`ifndef FIN_USE_1MS_TARGET
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;
		`else
		integer wait_time = $floor(1000000 / `CLOCK_PERIOD); // 1000000ns = 1ms
		`endif

		while (i < num_entry) begin

			`ifndef FIN_USE_1MS_TARGET
			do_wait = $random() % 4;
			if (do_wait < 2) begin
				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);
			end
			`else
			if (i != 0) begin
				repeat (wait_time) @(posedge clk);
			end
			`endif

			fin_valid = 1'b1;
			features_top = feature_memory[i];

			`ifdef GL_SIM
			@(negedge clk);
			`endif
			if (fin_ready) begin
				@(posedge clk);
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

			`ifdef GL_SIM
			@(negedge clk);
			`else
			@(posedge clk);
			`endif

			if (fin_valid && ~fin_ready) fin_valid_high_ready_low = fin_valid_high_ready_low + 1;
			if (~fin_valid && fin_ready) fin_valid_low_ready_high = fin_valid_low_ready_high + 1;
			if (fin_valid && fin_ready) begin
				start_time[i] = cycle;
				i = i + 1;
			end

		end

	endtask : start_fin_monitor

	task start_dout_sequence;

		integer i = 0;

		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			wait_time = $random() % max_wait_time;
			repeat (wait_time) @(posedge clk);
			dout_ready = 1'b1;

			`ifdef GL_SIM
			@(negedge clk);
			`endif
			if (dout_valid) i = i + 1;

			@(posedge clk);
			dout_ready = 1'b0;

		end

	endtask : start_dout_sequence

	task start_dout_monitor;

		integer i = 0;

		while (i < num_entry) begin

			`ifdef GL_SIM
			@(negedge clk);
			`else
			@(posedge clk);
			`endif

			if (dout_valid && ~dout_ready) dout_valid_high_ready_low = dout_valid_high_ready_low + 1;
			if (~dout_valid && dout_ready) dout_valid_low_ready_high = dout_valid_low_ready_high + 1;

			if (dout_valid && dout_ready) begin
				end_time[i] = cycle;

				if (valence != expected_v_memory[i] && i > 1) begin
					$display("Output %d does not match the expected VALENCE label", i);
					$display("Label %d: \n%b,\nExpected Label: \n%b\n", i, valence, expected_v_memory[i]);
					num_fail = num_fail + 1;
				end

				if (arousal != expected_a_memory[i] && i > 1) begin
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
