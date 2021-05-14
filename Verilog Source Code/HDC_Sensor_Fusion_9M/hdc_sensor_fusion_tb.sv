`timescale 1ns / 1ps
`include "const.vh"

module hdc_sensor_fusion_tb;

	localparam num_entry				= 20;
	localparam max_wait_time			= 0;
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

	reg  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_im_sram_addr;
	reg  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_projm_pos_sram_addr;
	reg  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_projm_neg_sram_addr;
	reg  [`HV_DIMENSION-1:0] FPGA_GSR_im_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_GSR_projm_pos_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_GSR_projm_neg_sram_hvin;

	reg  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_im_sram_addr;
	reg  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_projm_pos_sram_addr;
	reg  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_projm_neg_sram_addr;
	reg  [`HV_DIMENSION-1:0] FPGA_ECG_im_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_ECG_projm_pos_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_ECG_projm_neg_sram_hvin;

	reg  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_im_sram_addr;
	reg  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_projm_pos_sram_addr;
	reg  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_projm_neg_sram_addr;
	reg  [`HV_DIMENSION-1:0] FPGA_EEG_im_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_EEG_projm_pos_sram_hvin;
	reg  [`HV_DIMENSION-1:0] FPGA_EEG_projm_neg_sram_hvin;

	hdc_sensor_fusion dut (
		.clk							(clk),
		.rst							(rst),

		.features_top						(features_top),
		.fin_valid						(fin_valid),
		.fin_ready						(fin_ready),

		.valence						(valence),
		.arousal						(arousal),
		.dout_valid						(dout_valid),
		.dout_ready						(dout_ready),

		.write_enable					(write_enable),
		.write_enable_valid				(write_enable_valid),

		.FPGA_GSR_im_sram_addr			(FPGA_GSR_im_sram_addr),
		.FPGA_GSR_projm_pos_sram_addr	(FPGA_GSR_projm_pos_sram_addr),
		.FPGA_GSR_projm_neg_sram_addr	(FPGA_GSR_projm_neg_sram_addr),
		.FPGA_GSR_im_sram_hvin			(FPGA_GSR_im_sram_hvin),
		.FPGA_GSR_projm_pos_sram_hvin	(FPGA_GSR_projm_pos_sram_hvin),
		.FPGA_GSR_projm_neg_sram_hvin	(FPGA_GSR_projm_neg_sram_hvin),

		.FPGA_ECG_im_sram_addr			(FPGA_ECG_im_sram_addr),
		.FPGA_ECG_projm_pos_sram_addr	(FPGA_ECG_projm_pos_sram_addr),
		.FPGA_ECG_projm_neg_sram_addr	(FPGA_ECG_projm_neg_sram_addr),
		.FPGA_ECG_im_sram_hvin			(FPGA_ECG_im_sram_hvin),
		.FPGA_ECG_projm_pos_sram_hvin	(FPGA_ECG_projm_pos_sram_hvin),
		.FPGA_ECG_projm_neg_sram_hvin	(FPGA_ECG_projm_neg_sram_hvin),

		.FPGA_EEG_im_sram_addr			(FPGA_EEG_im_sram_addr),
		.FPGA_EEG_projm_pos_sram_addr	(FPGA_EEG_projm_pos_sram_addr),
		.FPGA_EEG_projm_neg_sram_addr	(FPGA_EEG_projm_neg_sram_addr),
		.FPGA_EEG_im_sram_hvin			(FPGA_EEG_im_sram_hvin),
		.FPGA_EEG_projm_pos_sram_hvin	(FPGA_EEG_projm_pos_sram_hvin),
		.FPGA_EEG_projm_neg_sram_hvin	(FPGA_EEG_projm_neg_sram_hvin)
	);

	//-------//
	// Files //
	//-------//

	integer power_yml_file;

	integer GSR_im_file;
	integer GSR_projm_pos_file;
	integer GSR_projm_neg_file;

	integer ECG_im_file;
	integer ECG_projm_pos_file;
	integer ECG_projm_neg_file;

	integer EEG_im_file;
	integer EEG_projm_pos_file;
	integer EEG_projm_neg_file;

	integer feature_file;
	integer expected_v_file;
	integer expected_a_file;

	integer get_GSR_im;
	integer get_GSR_projm_pos;
	integer get_GSR_projm_neg;

	integer get_ECG_im;
	integer get_ECG_projm_pos;
	integer get_ECG_projm_neg;

	integer get_EEG_im;
	integer get_EEG_projm_pos;
	integer get_EEG_projm_neg;

	integer get_feature;
	integer get_expected_v;
	integer get_expected_a;

	//--------//
	// Memory //
	//--------//

	reg [`HV_DIMENSION-1:0] GSR_projm_pos_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] GSR_projm_neg_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_projm_pos_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_projm_neg_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_projm_pos_memory[`EEG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_projm_neg_memory[`EEG_NUM_CHANNEL-1:0];

	reg [`HV_DIMENSION-1:0] GSR_item_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_item_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_item_memory[`EEG_NUM_CHANNEL-1:0];

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

		fin_valid  = 1'b0;
		dout_ready = 1'b0;

		write_srams();

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

		write_power_yml_file();

		$toggle_stop();
		$toggle_report("../../build/sim-par-rundir/hdc_sensor_fusion.saif", 1.0e-9, dut);
		$vcdplusoff;
		$finish();
	end

	function void initialize_memory();
		integer i, j;

		GSR_im_file 		= $fopen("../../src/HDC_Sensor_Fusion_9M/GSR_im.txt", "r");
		GSR_projm_pos_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/GSR_projm_pos.txt", "r");
		GSR_projm_neg_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/GSR_projm_neg.txt", "r");

		ECG_im_file 		= $fopen("../../src/HDC_Sensor_Fusion_9M/ECG_im.txt", "r");
		ECG_projm_pos_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/ECG_projm_pos.txt", "r");
		ECG_projm_neg_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/ECG_projm_neg.txt", "r");

		EEG_im_file 		= $fopen("../../src/HDC_Sensor_Fusion_9M/EEG_im.txt", "r");
		EEG_projm_pos_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/EEG_projm_pos.txt", "r");
		EEG_projm_neg_file 	= $fopen("../../src/HDC_Sensor_Fusion_9M/EEG_projm_neg.txt", "r");

		feature_file	= $fopen("../../src/HDC_Sensor_Fusion_9M/feature_binary.txt","r");
		expected_v_file	= $fopen("../../src/HDC_Sensor_Fusion_9M/expected_v.txt","r");
		expected_a_file	= $fopen("../../src/HDC_Sensor_Fusion_9M/expected_a.txt","r");

		if (GSR_im_file == 0 || GSR_projm_pos_file == 0 || GSR_projm_neg_file == 0 ||
			ECG_im_file == 0 || ECG_projm_pos_file == 0 || ECG_projm_neg_file == 0 ||
			EEG_im_file == 0 || EEG_projm_pos_file == 0 || EEG_projm_neg_file == 0 ||
			feature_file == 0 || expected_v_file == 0 || expected_a_file == 0) begin
			$display("Data Fetch Error");
			$finish();
		end

		for (j = 0; j < `GSR_NUM_CHANNEL; j = j + 1) begin
			get_GSR_im			= $fscanf(GSR_im_file, "%b\n", GSR_item_memory[j]);

			get_GSR_projm_pos	= $fscanf(GSR_projm_pos_file, "%b\n", GSR_projm_pos_memory[j]);
			get_GSR_projm_neg	= $fscanf(GSR_projm_neg_file, "%b\n", GSR_projm_neg_memory[j]);
		end

		for (j = 0; j < `ECG_NUM_CHANNEL; j = j + 1) begin
			get_ECG_im			= $fscanf(ECG_im_file, "%b\n", ECG_item_memory[j]);

			get_ECG_projm_pos	= $fscanf(ECG_projm_pos_file, "%b\n", ECG_projm_pos_memory[j]);
			get_ECG_projm_neg	= $fscanf(ECG_projm_neg_file, "%b\n", ECG_projm_neg_memory[j]);
		end

		for (j = 0; j < `EEG_NUM_CHANNEL; j = j + 1) begin
			get_EEG_im			= $fscanf(EEG_im_file, "%b\n", EEG_item_memory[j]);

			get_EEG_projm_pos	= $fscanf(EEG_projm_pos_file, "%b\n", EEG_projm_pos_memory[j]);
			get_EEG_projm_neg	= $fscanf(EEG_projm_neg_file, "%b\n", EEG_projm_neg_memory[j]);
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
		power_yml_file = $fopen("../../src/HDC_Sensor_Fusion_9M/hdc_sensor_fusion_power.yml","w");
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
		$fclose(power_yml_file);
	endfunction : write_power_yml_file

	task write_srams;
		integer i = 0;

		@(negedge clk);

		write_enable_valid = 1'b1;
		write_enable = 1'b0;

		@(negedge clk);

		for (i = 0; i < `GSR_NUM_CHANNEL; i = i + 1) begin
			FPGA_GSR_im_sram_addr 			= i;
			FPGA_GSR_projm_pos_sram_addr 	= i;
			FPGA_GSR_projm_neg_sram_addr 	= i;

			FPGA_GSR_im_sram_hvin 			= GSR_item_memory[i];
			FPGA_GSR_projm_pos_sram_hvin 	= GSR_projm_pos_memory[i];
			FPGA_GSR_projm_neg_sram_hvin 	= GSR_projm_neg_memory[i];

			FPGA_ECG_im_sram_addr 			= i;
			FPGA_ECG_projm_pos_sram_addr 	= i;
			FPGA_ECG_projm_neg_sram_addr 	= i;
	
			FPGA_ECG_im_sram_hvin 			= ECG_item_memory[i];
			FPGA_ECG_projm_pos_sram_hvin 	= ECG_projm_pos_memory[i];
			FPGA_ECG_projm_neg_sram_hvin 	= ECG_projm_neg_memory[i];

			FPGA_EEG_im_sram_addr 			= i;
			FPGA_EEG_projm_pos_sram_addr 	= i;
			FPGA_EEG_projm_neg_sram_addr 	= i;

			FPGA_EEG_im_sram_hvin 			= EEG_item_memory[i];
			FPGA_EEG_projm_pos_sram_hvin 	= EEG_projm_pos_memory[i];
			FPGA_EEG_projm_neg_sram_hvin 	= EEG_projm_neg_memory[i];

			@(negedge clk);
		end

		for (i = `GSR_NUM_CHANNEL; i < `ECG_NUM_CHANNEL; i = i + 1) begin
			FPGA_ECG_im_sram_addr 			= i;
			FPGA_ECG_projm_pos_sram_addr 	= i;
			FPGA_ECG_projm_neg_sram_addr 	= i;
	
			FPGA_ECG_im_sram_hvin 			= ECG_item_memory[i];
			FPGA_ECG_projm_pos_sram_hvin 	= ECG_projm_pos_memory[i];
			FPGA_ECG_projm_neg_sram_hvin 	= ECG_projm_neg_memory[i];

			FPGA_EEG_im_sram_addr 			= i;
			FPGA_EEG_projm_pos_sram_addr 	= i;
			FPGA_EEG_projm_neg_sram_addr 	= i;

			FPGA_EEG_im_sram_hvin 			= EEG_item_memory[i];
			FPGA_EEG_projm_pos_sram_hvin 	= EEG_projm_pos_memory[i];
			FPGA_EEG_projm_neg_sram_hvin 	= EEG_projm_neg_memory[i];

			@(negedge clk);
		end

		for (i = `ECG_NUM_CHANNEL; i < `EEG_NUM_CHANNEL; i = i + 1) begin
			FPGA_EEG_im_sram_addr 			= i;
			FPGA_EEG_projm_pos_sram_addr 	= i;
			FPGA_EEG_projm_neg_sram_addr 	= i;

			FPGA_EEG_im_sram_hvin 			= EEG_item_memory[i];
			FPGA_EEG_projm_pos_sram_hvin 	= EEG_projm_pos_memory[i];
			FPGA_EEG_projm_neg_sram_hvin 	= EEG_projm_neg_memory[i];

			@(negedge clk);
		end

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

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry) begin

			do_wait = $random() % 4;
			if (do_wait < 2) begin
				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);
			end

			fin_valid = 1'b1;
			features_top  = feature_memory[i];

			@(negedge clk);
			if (fin_ready) begin
				@(negedge clk);
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

			@(negedge clk);
			if (dout_valid) i = i + 1;

			@(posedge clk);
			dout_ready = 1'b0;

		end

	endtask : start_dout_sequence

	task start_dout_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge clk);
			//@(posedge clk);

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
