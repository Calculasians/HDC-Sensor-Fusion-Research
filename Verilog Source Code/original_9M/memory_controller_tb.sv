`timescale 1ps / 1ps
`include "const.vh"

module memory_controller_tb;

	localparam num_channel         = 32;
	localparam sram_addr_width     = `ceilLog2(num_channel);
	localparam num_entry           = 380;
	localparam max_wait_time       = 16;
	localparam max_wait_time_width = `ceilLog2(max_wait_time);

	reg clk, rst;

	initial clk = 0;
	initial rst = 0;
	always #(5) clk = ~clk;

	reg  [`CHANNEL_WIDTH-1:0] features [num_channel-1:0];
	reg  fin_valid;
	wire fin_ready;

	wire [`HV_DIMENSION-1:0] im;
	wire [`HV_DIMENSION-1:0] projm;
	wire dout_valid;
	reg  dout_ready;

	// IM SRAM
	wire [sram_addr_width-1:0] im_sram_addr;
	wire im_sram_addr_valid;
	reg  im_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] im_sram_hvin;
	reg  im_sram_hvin_valid;
	wire im_sram_hvin_ready;

	// ProjM Pos SRAM
	wire [sram_addr_width-1:0] projm_pos_sram_addr;
	wire projm_pos_sram_addr_valid;
	reg  projm_pos_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] projm_pos_sram_hvin;
	reg  projm_pos_sram_hvin_valid;
	wire projm_pos_sram_hvin_ready;

	// ProjM Neg SRAM
	wire [sram_addr_width-1:0] projm_neg_sram_addr;
	wire projm_neg_sram_addr_valid;
	reg  projm_neg_sram_addr_ready;

	reg  [`HV_DIMENSION-1:0] projm_neg_sram_hvin;
	reg  projm_neg_sram_hvin_valid;
	wire projm_neg_sram_hvin_ready;

	memory_controller #(
		.num_channel 				(num_channel),
		.sram_addr_width			(sram_addr_width)
	) dut (
		.clk						(clk),
		.rst						(rst),

		.features					(features),
		.fin_valid					(fin_valid),
		.fin_ready					(fin_ready),

		.im							(im),
		.projm						(projm),
		.dout_valid					(dout_valid),
		.dout_ready					(dout_ready),

		// IM SRAM
		.im_sram_addr				(im_sram_addr),
		.im_sram_addr_valid			(im_sram_addr_valid),
		.im_sram_addr_ready			(im_sram_addr_ready),

		.im_sram_hvin				(im_sram_hvin),
		.im_sram_hvin_valid			(im_sram_hvin_valid),
		.im_sram_hvin_ready			(im_sram_hvin_ready),

		// ProjM Pos SRAM
		.projm_pos_sram_addr		(projm_pos_sram_addr),
		.projm_pos_sram_addr_valid	(projm_pos_sram_addr_valid),
		.projm_pos_sram_addr_ready	(projm_pos_sram_addr_ready),

		.projm_pos_sram_hvin		(projm_pos_sram_hvin),
		.projm_pos_sram_hvin_valid	(projm_pos_sram_hvin_valid),
		.projm_pos_sram_hvin_ready	(projm_pos_sram_hvin_ready),

		// ProjM Neg SRAM
		.projm_neg_sram_addr		(projm_neg_sram_addr),
		.projm_neg_sram_addr_valid	(projm_neg_sram_addr_valid),
		.projm_neg_sram_addr_ready	(projm_neg_sram_addr_ready),

		.projm_neg_sram_hvin		(projm_neg_sram_hvin),
		.projm_neg_sram_hvin_valid	(projm_neg_sram_hvin_valid),
		.projm_neg_sram_hvin_ready	(projm_neg_sram_hvin_ready)
	);

	//-------//
	// Files //
	//-------//

	integer im_file;
	integer feature_file;
	integer projm_pos_file;
	integer projm_neg_file;

	integer get_im;
	integer get_feature;
	integer get_projm_pos;
	integer get_projm_neg;

	//--------//
	// Memory //
	//--------//

	reg [`CHANNEL_WIDTH-1:0] feature_memory[num_entry-1:0][num_channel-1:0];
	reg [`HV_DIMENSION-1:0] projm_pos_memory[num_channel-1:0];
	reg [`HV_DIMENSION-1:0] projm_neg_memory[num_channel-1:0];
	reg [`HV_DIMENSION-1:0] item_memory[num_channel-1:0];

	//------------//
	// Statistics //
	//------------//

	integer fin_valid_high_ready_low  = 0;
	integer fin_valid_low_ready_high  = 0;
	integer dout_valid_high_ready_low = 0;
	integer dout_valid_low_ready_high = 0;

	integer num_fail                  = 0;

	integer done = 0;

	initial begin
		fin_valid  = 1'b0;
		dout_ready = 1'b0;

		im_sram_addr_ready = 1'b0;
		im_sram_hvin_valid = 1'b0;

		projm_pos_sram_addr_ready = 1'b0;
		projm_pos_sram_hvin_valid = 1'b0;

		projm_neg_sram_addr_ready = 1'b0;
		projm_neg_sram_hvin_valid = 1'b0;

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

			start_im_sram_bfm();
			start_projm_pos_sram_bfm();
			start_projm_neg_sram_bfm();
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

		$finish();

	end

	function void initialize_memory();
		integer i, j;

		im_file			= $fopen("im", "r");
		feature_file	= $fopen("GSR_fm", "r");
		projm_pos_file	= $fopen("GSR_proj_pos_D_2000_imrandom", "r");
		projm_neg_file	= $fopen("GSR_proj_neg_D_2000_imrandom", "r");

		if (im_file == 0 || feature_file == 0 || projm_pos_file == 0 || projm_neg_file == 0) begin
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

		end
	endfunction : initialize_memory

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
			if (fin_valid && fin_ready)  i = i + 1;

		end

	endtask : start_fin_monitor

	task start_dout_sequence;

		integer i = 0;

		reg [max_wait_time_width-1:0] wait_time;

		while (i < num_entry * num_channel) begin

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

		integer i, j;

		for (i = 0; i < num_entry; i = i + 1) begin

			j = 0;
			while (j < num_channel) begin

				@(negedge clk);

				if (dout_valid && ~dout_ready) dout_valid_high_ready_low = dout_valid_high_ready_low + 1;
				if (~dout_valid && dout_ready) dout_valid_low_ready_high = dout_valid_low_ready_high + 1;

				if (dout_valid && dout_ready) begin

					if (feature_memory[i][j] == 1) begin
						if (projm != projm_pos_memory[j]) begin
							$display("Test entry %d, Projm_pos %d does not match the expected hypervector", i, j);
							$display("Projm_pos: \n%b,\nExpected Projm_pos: \n%b\n", projm, projm_pos_memory[j]);
							num_fail = num_fail + 1;
						end
					end
					else if (feature_memory[i][j] == 2) begin
						if (projm != projm_neg_memory[j]) begin
							$display("Test entry %d, Projm_neg %d does not match the expected hypervector", i, j);
							$display("Projm_neg: \n%b,\nExpected Projm_neg: \n%b\n", projm, projm_neg_memory[j]);
							num_fail = num_fail + 1;
						end
					end
					else begin
						if (projm != {`HV_DIMENSION{1'b0}}) begin
							$display("Test entry %d, Projm_zero %d does not match the expected hypervector", i, j);
							$display("Projm_zero: \n%b,\nExpected Projm_zero: \n%b\n", projm, {`HV_DIMENSION{1'b0}});
							num_fail = num_fail + 1;
						end
					end

					if (im != item_memory[j]) begin
						$display("Output %d does not match the expected hypervector", j);
						$display("HVout: \n%b,\nExpected HVout: \n%b\n", im, item_memory[j]);
						num_fail = num_fail + 1;
					end

					j = j + 1;
				end

			end

		end

		done = 1;

	endtask : start_dout_monitor

	task start_im_sram_bfm;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;
		reg [sram_addr_width-1:0] sram_addr;

		while (done == 0) begin

			im_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (im_sram_addr_valid) begin
				sram_addr = im_sram_addr;

				@(posedge clk);
				im_sram_addr_ready = 1'b0;

				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);

				im_sram_hvin_valid = 1'b1;
				im_sram_hvin       = item_memory[sram_addr];

				@(negedge clk);
				while (!im_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				im_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_im_sram_bfm

	task start_projm_pos_sram_bfm;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;
		reg [sram_addr_width-1:0] sram_addr;

		while (done == 0) begin

			projm_pos_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (projm_pos_sram_addr_valid) begin
				sram_addr = projm_pos_sram_addr;

				@(posedge clk);
				projm_pos_sram_addr_ready = 1'b0;

				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);


				projm_pos_sram_hvin_valid = 1'b1;
				projm_pos_sram_hvin       = projm_pos_memory[sram_addr];

				@(negedge clk);
				while (!projm_pos_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				projm_pos_sram_hvin_valid = 1'b0;
			end

		end

	endtask : start_projm_pos_sram_bfm

	task start_projm_neg_sram_bfm;

		reg [1:0] do_wait; // do_wait < 2 == wait, else do not wait
		reg [max_wait_time_width-1:0] wait_time;
		reg [sram_addr_width-1:0] sram_addr;

		while (done == 0) begin

			projm_neg_sram_addr_ready = 1'b1;

			@(negedge clk);
			if (projm_neg_sram_addr_valid) begin
				sram_addr = projm_neg_sram_addr;

				@(posedge clk);
				projm_neg_sram_addr_ready = 1'b0;

				wait_time = $random() % max_wait_time;
				repeat (wait_time) @(posedge clk);

				projm_neg_sram_hvin_valid = 1'b1;
				projm_neg_sram_hvin       = projm_neg_memory[sram_addr];

				@(negedge clk);
				while (!projm_neg_sram_hvin_ready) @(negedge clk);

				@(posedge clk);
				projm_neg_sram_hvin_valid = 1'b0;
			end
		end

	endtask : start_projm_neg_sram_bfm

endmodule : memory_controller_tb
