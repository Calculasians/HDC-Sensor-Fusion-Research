`timescale 1ps / 1ps
`include "const.vh"

module hdc_sensor_fusion_tb;

	localparam num_entry				= 380;
	localparam max_wait_time			= 128;
	localparam max_wait_time_width		= `ceilLog2(max_wait_time);
	localparam max_sram_hold_time		= 16;
	localparam max_sram_hold_time_width	= `ceilLog2(max_sram_hold_time);
	localparam randomize_sram_time      = 1;

	reg clk, rst;

	initial clk = 0;
	initial rst = 0;
	always #(5) clk = ~clk;

	reg  [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0];
	reg  fin_valid;
	wire fin_ready;

	wire dout_valid;
	reg  dout_ready;
	wire valence;
	wire arousal;

	// IM SRAM
	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_im_sram_addr;
	wire GSR_im_sram_addr_valid;
	reg  GSR_im_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] GSR_im_sram_hvin;
	reg  GSR_im_sram_hvin_valid;
	wire GSR_im_sram_hvin_ready;

	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_im_sram_addr;
	wire ECG_im_sram_addr_valid;
	reg  ECG_im_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] ECG_im_sram_hvin;
	reg  ECG_im_sram_hvin_valid;
	wire ECG_im_sram_hvin_ready;

	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_im_sram_addr;
	wire EEG_im_sram_addr_valid;
	reg  EEG_im_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] EEG_im_sram_hvin;
	reg  EEG_im_sram_hvin_valid;
	wire EEG_im_sram_hvin_ready;

	// ProjM Pos SRAM
	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_projm_pos_sram_addr;
	wire GSR_projm_pos_sram_addr_valid;
	reg  GSR_projm_pos_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] GSR_projm_pos_sram_hvin;
	reg  GSR_projm_pos_sram_hvin_valid;
	wire GSR_projm_pos_sram_hvin_ready;

	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_projm_pos_sram_addr;
	wire EGC_projm_pos_sram_addr_valid;
	reg  ECG_projm_pos_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] ECG_projm_pos_sram_hvin;
	reg  ECG_projm_pos_sram_hvin_valid;
	wire ECG_projm_pos_sram_hvin_ready;

	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_projm_pos_sram_addr;
	wire EEC_projm_pos_sram_addr_valid;
	reg  EEG_projm_pos_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] EEG_projm_pos_sram_hvin;
	reg  EEG_projm_pos_sram_hvin_valid;
	wire EEG_projm_pos_sram_hvin_ready;

	// ProjM Neg SRAM
	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_projm_neg_sram_addr;
	wire GSR_projm_neg_sram_addr_valid;
	reg  GSR_projm_neg_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] GSR_projm_neg_sram_hvin;
	reg  GSR_projm_neg_sram_hvin_valid;
	wire GSR_projm_neg_sram_hvin_ready;

	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_projm_neg_sram_addr;
	wire ECG_projm_neg_sram_addr_valid;
	reg  ECG_projm_neg_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] ECG_projm_neg_sram_hvin;
	reg  ECG_projm_neg_sram_hvin_valid;
	wire ECG_projm_neg_sram_hvin_ready;

	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_projm_neg_sram_addr;
	wire EEG_projm_neg_sram_addr_valid;
	reg  EEG_projm_neg_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] EEG_projm_neg_sram_hvin;
	reg  EEG_projm_neg_sram_hvin_valid;
	wire EEG_projm_neg_sram_hvin_ready;

	hdc_sensor_fusion dut (
		.clk							(clk),
		.rst							(rst),

		.features						(features),
		.fin_valid						(fin_valid),
		.fin_ready						(fin_ready),

		.valence						(valence),
		.arousal						(arousal),
		.dout_valid						(dout_valid),
		.dout_ready						(dout_ready),

		//---------------//
		// Item Memories //
		//---------------//

		// GSR IM SRAM
		.GSR_im_sram_addr				(GSR_im_sram_addr),
		.GSR_im_sram_addr_valid			(GSR_im_sram_addr_valid),
		.GSR_im_sram_addr_ready			(GSR_im_sram_addr_ready),

		.GSR_im_sram_hvin				(GSR_im_sram_hvin),
		.GSR_im_sram_hvin_valid			(GSR_im_sram_hvin_valid),
		.GSR_im_sram_hvin_ready			(GSR_im_sram_hvin_ready),

		// ECG IM SRAM
		.ECG_im_sram_addr				(ECG_im_sram_addr),
		.ECG_im_sram_addr_valid			(ECG_im_sram_addr_valid),
		.ECG_im_sram_addr_ready			(ECG_im_sram_addr_ready),

		.ECG_im_sram_hvin				(ECG_im_sram_hvin),
		.ECG_im_sram_hvin_valid			(ECG_im_sram_hvin_valid),
		.ECG_im_sram_hvin_ready			(ECG_im_sram_hvin_ready),

		// EEG IM SRAM
		.EEG_im_sram_addr				(EEG_im_sram_addr),
		.EEG_im_sram_addr_valid			(EEG_im_sram_addr_valid),
		.EEG_im_sram_addr_ready			(EEG_im_sram_addr_ready),

		.EEG_im_sram_hvin				(EEG_im_sram_hvin),
		.EEG_im_sram_hvin_valid			(EEG_im_sram_hvin_valid),
		.EEG_im_sram_hvin_ready			(EEG_im_sram_hvin_ready),

		//------------------------------//
		// Projection Positive Memories //
		//------------------------------//

		// GSR ProjM Pos SRAM
		.GSR_projm_pos_sram_addr		(GSR_projm_pos_sram_addr),
		.GSR_projm_pos_sram_addr_valid	(GSR_projm_pos_sram_addr_valid),
		.GSR_projm_pos_sram_addr_ready	(GSR_projm_pos_sram_addr_ready),

		.GSR_projm_pos_sram_hvin		(GSR_projm_pos_sram_hvin),
		.GSR_projm_pos_sram_hvin_valid	(GSR_projm_pos_sram_hvin_valid),
		.GSR_projm_pos_sram_hvin_ready	(GSR_projm_pos_sram_hvin_ready),

		// ECG ProjM Pos SRAM
		.ECG_projm_pos_sram_addr		(ECG_projm_pos_sram_addr),
		.ECG_projm_pos_sram_addr_valid	(ECG_projm_pos_sram_addr_valid),
		.ECG_projm_pos_sram_addr_ready	(ECG_projm_pos_sram_addr_ready),

		.ECG_projm_pos_sram_hvin		(ECG_projm_pos_sram_hvin),
		.ECG_projm_pos_sram_hvin_valid	(ECG_projm_pos_sram_hvin_valid),
		.ECG_projm_pos_sram_hvin_ready	(ECG_projm_pos_sram_hvin_ready),

		// EEG ProjM Pos SRAM
		.EEG_projm_pos_sram_addr		(EEG_projm_pos_sram_addr),
		.EEG_projm_pos_sram_addr_valid	(EEG_projm_pos_sram_addr_valid),
		.EEG_projm_pos_sram_addr_ready	(EEG_projm_pos_sram_addr_ready),

		.EEG_projm_pos_sram_hvin		(EEG_projm_pos_sram_hvin),
		.EEG_projm_pos_sram_hvin_valid	(EEG_projm_pos_sram_hvin_valid),
		.EEG_projm_pos_sram_hvin_ready	(EEG_projm_pos_sram_hvin_ready),

		//------------------------------//
		// Projection Negative Memories //
		//------------------------------//

		// GSR ProjM Neg SRAM
		.GSR_projm_neg_sram_addr		(GSR_projm_neg_sram_addr),
		.GSR_projm_neg_sram_addr_valid	(GSR_projm_neg_sram_addr_valid),
		.GSR_projm_neg_sram_addr_ready	(GSR_projm_neg_sram_addr_ready),

		.GSR_projm_neg_sram_hvin		(GSR_projm_neg_sram_hvin),
		.GSR_projm_neg_sram_hvin_valid	(GSR_projm_neg_sram_hvin_valid),
		.GSR_projm_neg_sram_hvin_ready	(GSR_projm_neg_sram_hvin_ready),

		// ECG ProjM Neg SRAM
		.ECG_projm_neg_sram_addr		(ECG_projm_neg_sram_addr),
		.ECG_projm_neg_sram_addr_valid	(ECG_projm_neg_sram_addr_valid),
		.ECG_projm_neg_sram_addr_ready	(ECG_projm_neg_sram_addr_ready),

		.ECG_projm_neg_sram_hvin		(ECG_projm_neg_sram_hvin),
		.ECG_projm_neg_sram_hvin_valid	(ECG_projm_neg_sram_hvin_valid),
		.ECG_projm_neg_sram_hvin_ready	(ECG_projm_neg_sram_hvin_ready),

		// EEG ProjM Neg SRAM
		.EEG_projm_neg_sram_addr		(EEG_projm_neg_sram_addr),
		.EEG_projm_neg_sram_addr_valid	(EEG_projm_neg_sram_addr_valid),
		.EEG_projm_neg_sram_addr_ready	(EEG_projm_neg_sram_addr_ready),

		.EEG_projm_neg_sram_hvin		(EEG_projm_neg_sram_hvin),
		.EEG_projm_neg_sram_hvin_valid	(EEG_projm_neg_sram_hvin_valid),
		.EEG_projm_neg_sram_hvin_ready	(EEG_projm_neg_sram_hvin_ready)
	);

	//-------//
	// Files //
	//-------//

	integer GSR_im_file;
	integer GSR_feature_file;
	integer GSR_projm_pos_file;
	integer GSR_projm_neg_file;

	integer ECG_im_file;
	integer ECG_feature_file;
	integer ECG_projm_pos_file;
	integer ECG_projm_neg_file;

	integer EEG_im_file;
	integer EEG_feature_file;
	integer EEG_projm_pos_file;
	integer EEG_projm_neg_file;

	integer expected_v_file;
	integer expected_a_file;

	integer get_GSR_im;
	integer get_GSR_feature;
	integer get_GSR_projm_pos;
	integer get_GSR_projm_neg;

	integer get_ECG_im;
	integer get_ECG_feature;
	integer get_ECG_projm_pos;
	integer get_ECG_projm_neg;

	integer get_EEG_im;
	integer get_EEG_feature;
	integer get_EEG_projm_pos;
	integer get_EEG_projm_neg;

	integer get_expected_v;
	integer get_expected_a;

	//--------//
	// Memory //
	//--------//

	reg [`CHANNEL_WIDTH-1:0] feature_memory[num_entry-1:0][`TOTAL_NUM_CHANNEL-1:0];

	reg [`HV_DIMENSION-1:0] GSR_projm_pos_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] GSR_projm_neg_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_projm_pos_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_projm_neg_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_projm_pos_memory[`EEG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_projm_neg_memory[`EEG_NUM_CHANNEL-1:0];

	reg [`HV_DIMENSION-1:0] GSR_item_memory[`GSR_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] ECG_item_memory[`ECG_NUM_CHANNEL-1:0];
	reg [`HV_DIMENSION-1:0] EEG_item_memory[`EEG_NUM_CHANNEL-1:0];

	integer expected_v_memory[num_entry-1:0];
	integer expected_a_memory[num_entry-1:0];

	//------------//
	// Statistics //
	//------------//

	integer fin_valid_high_ready_low  = 0;
	integer fin_valid_low_ready_high  = 0;
	integer dout_valid_high_ready_low = 0;
	integer dout_valid_low_ready_high = 0;

	integer start_time[num_entry-1:0];
	integer end_time[num_entry-1:0];
	integer cycle                     = 0;

	integer num_fail                  = 0;

	integer done = 0;
	integer total = 0;
	integer i;

	initial begin
		fin_valid  = 1'b0;
		dout_ready = 1'b0;

		GSR_im_sram_addr_ready = 1'b0;
		GSR_im_sram_hvin_valid = 1'b0;

		GSR_projm_pos_sram_addr_ready = 1'b0;
		GSR_projm_pos_sram_hvin_valid = 1'b0;

		GSR_projm_neg_sram_addr_ready = 1'b0;
		GSR_projm_neg_sram_hvin_valid = 1'b0;

		ECG_im_sram_addr_ready = 1'b0;
		ECG_im_sram_hvin_valid = 1'b0;

		ECG_projm_pos_sram_addr_ready = 1'b0;
		ECG_projm_pos_sram_hvin_valid = 1'b0;

		ECG_projm_neg_sram_addr_ready = 1'b0;
		ECG_projm_neg_sram_hvin_valid = 1'b0;

		EEG_im_sram_addr_ready = 1'b0;
		EEG_im_sram_hvin_valid = 1'b0;

		EEG_projm_pos_sram_addr_ready = 1'b0;
		EEG_projm_pos_sram_hvin_valid = 1'b0;

		EEG_projm_neg_sram_addr_ready = 1'b0;
		EEG_projm_neg_sram_hvin_valid = 1'b0;

		initialize_memory();

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

			start_GSR_im_sram_bfm();
			start_GSR_projm_pos_sram_bfm();
			start_GSR_projm_neg_sram_bfm();

			start_ECG_im_sram_bfm();
			start_ECG_projm_pos_sram_bfm();
			start_ECG_projm_neg_sram_bfm();

			start_EEG_im_sram_bfm();
			start_EEG_projm_pos_sram_bfm();
			start_EEG_projm_neg_sram_bfm();

			start_cycle_counter();
		join

		$display("Statistics:\n");
		if (num_fail == 0)
			$display("All entries matched!\n");
		else
			$display("%d entries does not matched\n\n!", num_fail);

		$display("fin_valid_high_ready_low  = %d\n", fin_valid_high_ready_low);
		$display("fin_valid_low_ready_high  = %d\n", fin_valid_low_ready_high);
		$display("dout_valid_high_ready_low = %d\n", dout_valid_high_ready_low);
		$display("dout_valid_low_ready_high = %d\n", dout_valid_low_ready_high);

		for (i = 0; i < num_entry; i = i + 1) begin
			$display("Time taken to process entry %d : %d\n", i, end_time[i] - start_time[i]);
			total = total + end_time[i] - start_time[i];
		end
		$display("Average time taken to process a SINGLE entry : %d\n", total / num_entry);

		$finish();
	end

	function void initialize_memory();
		integer i, j;

		GSR_im_file			= $fopen("GSR_im", "r");
		GSR_feature_file	= $fopen("GSR_fm", "r");
		GSR_projm_pos_file	= $fopen("GSR_proj_pos_D_2000_imrandom", "r");
		GSR_projm_neg_file	= $fopen("GSR_proj_neg_D_2000_imrandom", "r");

		ECG_im_file			= $fopen("ECG_im", "r");
		ECG_feature_file	= $fopen("ECG_fm", "r");
		ECG_projm_pos_file	= $fopen("ECG_proj_pos_D_2000_imrandom", "r");
		ECG_projm_neg_file	= $fopen("ECG_proj_neg_D_2000_imrandom", "r");

		EEG_im_file			= $fopen("EEG_im", "r");
		EEG_feature_file	= $fopen("EEG_fm", "r");
		EEG_projm_pos_file	= $fopen("EEG_proj_pos_D_2000_imrandom", "r");
		EEG_projm_neg_file	= $fopen("EEG_proj_neg_D_2000_imrandom", "r");

		expected_v_file 	= $fopen("output_V_label_D_2000_imrandom", "r");
		expected_a_file 	= $fopen("output_A_label_D_2000_imrandom", "r");

		if (GSR_im_file == 0 || GSR_feature_file == 0 || GSR_projm_pos_file == 0 || GSR_projm_neg_file == 0 ||
			ECG_im_file == 0 || ECG_feature_file == 0 || ECG_projm_pos_file == 0 || ECG_projm_neg_file == 0 ||
			EEG_im_file == 0 || EEG_feature_file == 0 || EEG_projm_pos_file == 0 || EEG_projm_neg_file == 0 ||
			expected_v_file == 0  || expected_a_file == 0) begin
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

			for (j = 0; j < `GSR_NUM_CHANNEL; j = j + 1) begin
				get_GSR_feature			= $fgetc(GSR_feature_file);
				feature_memory[i][j] 	= (get_GSR_feature == 50) ? 2'b10 : (get_GSR_feature == 49) ? 2'b01 : 2'b00;
			end
			get_GSR_feature = $fgetc(GSR_feature_file); // should be a '\n' character

			for (j = `GSR_NUM_CHANNEL; j < `ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL; j = j + 1) begin
				get_ECG_feature			= $fgetc(ECG_feature_file);
				feature_memory[i][j] 	= (get_ECG_feature == 50) ? 2'b10 : (get_ECG_feature == 49) ? 2'b01 : 2'b00;
			end
			get_ECG_feature = $fgetc(ECG_feature_file); // should be a '\n' character

			for (j = `ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL; j < `EEG_NUM_CHANNEL+`ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL; j = j + 1) begin
				get_EEG_feature			= $fgetc(EEG_feature_file);
				feature_memory[i][j] 	= (get_EEG_feature == 50) ? 2'b10 : (get_EEG_feature == 49) ? 2'b01 : 2'b00;
			end
			get_EEG_feature = $fgetc(EEG_feature_file); // should be a '\n' character

		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_expected_v	= $fscanf(expected_v_file, "%b\n", expected_v_memory[i]);
			get_expected_a	= $fscanf(expected_a_file, "%b\n", expected_a_memory[i]);
		end

	endfunction : initialize_memory

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
			features  = feature_memory[i];

			@(negedge clk);
			if (fin_ready) i = i + 1;

			@(posedge clk);
			fin_valid = 1'b0;

		end

	endtask : start_fin_sequence

	task start_fin_monitor;

		integer i = 0;

		while (i < num_entry) begin

			@(negedge clk);

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

	task start_GSR_im_sram_bfm;

		reg [`GSR_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			GSR_im_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (GSR_im_sram_addr_valid) begin
				sram_addr = GSR_im_sram_addr;

				@(posedge clk);
				GSR_im_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				GSR_im_sram_hvin_valid = 1'b1;
				GSR_im_sram_hvin       = GSR_item_memory[sram_addr];

				@(negedge clk);
				while (!GSR_im_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				GSR_im_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_GSR_im_sram_bfm

	task start_GSR_projm_pos_sram_bfm;

		reg [`GSR_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			GSR_projm_pos_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (GSR_projm_pos_sram_addr_valid) begin
				sram_addr = GSR_projm_pos_sram_addr;

				@(posedge clk);
				GSR_projm_pos_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				GSR_projm_pos_sram_hvin_valid = 1'b1;
				GSR_projm_pos_sram_hvin       = GSR_projm_pos_memory[sram_addr];

				@(negedge clk);
				while (!GSR_projm_pos_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				GSR_projm_pos_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_GSR_projm_pos_sram_bfm

	task start_GSR_projm_neg_sram_bfm;

		reg [`GSR_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			GSR_projm_neg_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (GSR_projm_neg_sram_addr_valid) begin
				sram_addr = GSR_projm_neg_sram_addr;

				@(posedge clk);
				GSR_projm_neg_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				GSR_projm_neg_sram_hvin_valid = 1'b1;
				GSR_projm_neg_sram_hvin       = GSR_projm_neg_memory[sram_addr];

				@(negedge clk);
				while (!GSR_projm_neg_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				GSR_projm_neg_sram_hvin_valid = 1'b0;
			end
		end

	endtask : start_GSR_projm_neg_sram_bfm

	task start_ECG_im_sram_bfm;

		reg [`ECG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			ECG_im_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (ECG_im_sram_addr_valid) begin
				sram_addr = ECG_im_sram_addr;

				@(posedge clk);
				ECG_im_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				ECG_im_sram_hvin_valid = 1'b1;
				ECG_im_sram_hvin       = ECG_item_memory[sram_addr];

				@(negedge clk);
				while (!ECG_im_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				ECG_im_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_ECG_im_sram_bfm

	task start_ECG_projm_pos_sram_bfm;

		reg [`ECG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			ECG_projm_pos_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (ECG_projm_pos_sram_addr_valid) begin
				sram_addr = ECG_projm_pos_sram_addr;

				@(posedge clk);
				ECG_projm_pos_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				ECG_projm_pos_sram_hvin_valid = 1'b1;
				ECG_projm_pos_sram_hvin       = ECG_projm_pos_memory[sram_addr];

				@(negedge clk);
				while (!ECG_projm_pos_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				ECG_projm_pos_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_ECG_projm_pos_sram_bfm

	task start_ECG_projm_neg_sram_bfm;

		reg [`ECG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			ECG_projm_neg_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (ECG_projm_neg_sram_addr_valid) begin
				sram_addr = ECG_projm_neg_sram_addr;

				@(posedge clk);
				ECG_projm_neg_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				ECG_projm_neg_sram_hvin_valid = 1'b1;
				ECG_projm_neg_sram_hvin       = ECG_projm_neg_memory[sram_addr];

				@(negedge clk);
				while (!ECG_projm_neg_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				ECG_projm_neg_sram_hvin_valid = 1'b0;
			end
		end

	endtask : start_ECG_projm_neg_sram_bfm

	task start_EEG_im_sram_bfm;

		reg [`EEG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			EEG_im_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (EEG_im_sram_addr_valid) begin
				sram_addr = EEG_im_sram_addr;

				@(posedge clk);
				EEG_im_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				EEG_im_sram_hvin_valid = 1'b1;
				EEG_im_sram_hvin       = EEG_item_memory[sram_addr];

				@(negedge clk);
				while (!EEG_im_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				EEG_im_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_EEG_im_sram_bfm

	task start_EEG_projm_pos_sram_bfm;

		reg [`EEG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			EEG_projm_pos_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (EEG_projm_pos_sram_addr_valid) begin
				sram_addr = EEG_projm_pos_sram_addr;

				@(posedge clk);
				EEG_projm_pos_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				EEG_projm_pos_sram_hvin_valid = 1'b1;
				EEG_projm_pos_sram_hvin       = EEG_projm_pos_memory[sram_addr];

				@(negedge clk);
				while (!EEG_projm_pos_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				EEG_projm_pos_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_EEG_projm_pos_sram_bfm

	task start_EEG_projm_neg_sram_bfm;

		reg [`EEG_SRAM_ADDR_WIDTH-1:0] sram_addr;
		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_sram_hold_time_width-1:0] wait_time;

		while (done == 0) begin

			EEG_projm_neg_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (EEG_projm_neg_sram_addr_valid) begin
				sram_addr = EEG_projm_neg_sram_addr;

				@(posedge clk);
				EEG_projm_neg_sram_addr_ready = 1'b0;

				do_wait = $random() % 4;
				if (randomize_sram_time && do_wait < 2) begin
					wait_time = $random() % max_sram_hold_time;
					repeat (wait_time) @(posedge clk);
				end

				EEG_projm_neg_sram_hvin_valid = 1'b1;
				EEG_projm_neg_sram_hvin       = EEG_projm_neg_memory[sram_addr];

				@(negedge clk);
				while (!EEG_projm_neg_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				EEG_projm_neg_sram_hvin_valid = 1'b0;
			end
		end

	endtask : start_EEG_projm_neg_sram_bfm

endmodule : hdc_sensor_fusion_tb