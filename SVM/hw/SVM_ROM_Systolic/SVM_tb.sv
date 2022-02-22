`timescale 1ns / 1ps
`include "const.vh"
`define GL_SIM 1

module SVM_tb;

    localparam num_entry        = 4; // total = 159

    localparam NBITS            = `NBITS;

    localparam VSUP_WIDTH       = `VSUP_WIDTH;
    localparam LOG_VSUP_WIDTH   = `ceilLog2(VSUP_WIDTH);

    localparam ASUP_WIDTH       = `ASUP_WIDTH;
    localparam LOG_ASUP_WIDTH   = `ceilLog2(ASUP_WIDTH);

	localparam F_WIDTH			= `F_WIDTH;
	localparam LOG_F_WIDTH 		= `ceilLog2(F_WIDTH);

    localparam SUP_WIDTH        = (ASUP_WIDTH > VSUP_WIDTH) ? ASUP_WIDTH : VSUP_WIDTH;
    localparam LOG_SUP_WIDTH    = (LOG_ASUP_WIDTH > LOG_VSUP_WIDTH) ? LOG_ASUP_WIDTH : LOG_VSUP_WIDTH;

    reg clk, rst;
	initial clk = 0;
	initial rst = 0;
	always #(`CLOCK_PERIOD/2) clk = ~clk;

    reg signed [NBITS*F_WIDTH-1:0]					in_features;
    reg fin_valid;
    wire fin_ready;

    wire valence;
    wire arousal;

    wire dout_valid;
    reg dout_ready;

    SVM 
    `ifndef GL_SIM
        #(
            .NBITS          (NBITS),
            .VSUP_WIDTH     (VSUP_WIDTH),
            .LOG_VSUP_WIDTH (LOG_VSUP_WIDTH),
            .ASUP_WIDTH     (ASUP_WIDTH),
            .LOG_ASUP_WIDTH (LOG_ASUP_WIDTH),
			.F_WIDTH		(F_WIDTH),
			.LOG_F_WIDTH	(LOG_F_WIDTH),
            .SUP_WIDTH      (SUP_WIDTH),
            .LOG_SUP_WIDTH  (LOG_SUP_WIDTH)
        ) dut (
    `else
        dut (
	`endif
        .clk            (clk),
        .rst            (rst),

        .in_features		(in_features),
        .fin_valid      	(fin_valid),
        .fin_ready      	(fin_ready),
        
        .valence        	(valence),
        .arousal        	(arousal),
        
        .dout_valid     	(dout_valid),
        .dout_ready     	(dout_ready)
    );

	string v_feature_filename;
	string a_feature_filename;
	string v_expected_filename, a_expected_filename;

	integer power_yml_file;
    integer v_feature_file;
    integer a_feature_file;
    integer v_expected_file, a_expected_file;
    integer get_v_feature;
    integer get_a_feature;
    integer get_v_expected, get_a_expected;

    reg signed [NBITS-1:0]                 v_feature_memory   [0:num_entry-1][0:F_WIDTH-1];
    reg signed [NBITS-1:0]                 a_feature_memory   [0:num_entry-1][0:F_WIDTH-1];

	reg                                    v_expected_memory  [num_entry-1:0];
	reg                                    a_expected_memory  [num_entry-1:0];

    integer num_fail    = 0;
    integer done        = 0;
	integer start_time[num_entry-1:0];
	integer end_time[num_entry-1:0];
	integer cycle       = 0;
    integer total       = 0;
    integer i;
	integer modality	= 0; // 0 - valence, 1 - arousal

    initial begin
		$vcdpluson();
		$dumpfile("svm.vcd");
		$dumpvars(1, SVM_tb.dut);
		$vcdplusmemon();
		$set_toggle_region(dut);
		$toggle_start();
		initialize_memory();

		@(posedge clk);
		fin_valid  		= 1'b0;
		dout_ready 		= 1'b1;

		repeat (2) @(posedge clk);
		rst = 1'b1;
		repeat (5) @(posedge clk);
		rst = 1'b0;
		repeat (2) @(posedge clk);

		fork
			start_fin_sequence();
			start_fin_monitor();

			start_dout_monitor();

			start_cycle_counter();
		join

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
		$toggle_report("../../build/sim-par-rundir/svm.saif", 1.0e-9, dut);
		$vcdplusoff();
		$vcdplusmemoff();
		$finish();
    end

    function void initialize_memory();
        integer i;
		integer j;

		$sformat(v_feature_filename, "../../src/SVM_ROM_Systolic/RFE_%0d_nbits_%0d_v_features.txt", F_WIDTH, NBITS);
        v_feature_file = $fopen(v_feature_filename, "r");

		$sformat(a_feature_filename, "../../src/SVM_ROM_Systolic/RFE_%0d_nbits_%0d_a_features.txt", F_WIDTH, NBITS);
        a_feature_file = $fopen(a_feature_filename, "r");

		$sformat(v_expected_filename, "../../src/SVM_ROM_Systolic/RFE_%0d_nbits_%0d_v_expected.txt", F_WIDTH, NBITS);
		$sformat(a_expected_filename, "../../src/SVM_ROM_Systolic/RFE_%0d_nbits_%0d_a_expected.txt", F_WIDTH, NBITS);
        v_expected_file = $fopen(v_expected_filename, "r");
        a_expected_file = $fopen(a_expected_filename, "r");

        // if (v_feature_file == 0 || v_support_file == 0 || v_alpha_file == 0 || v_intercept_file ||
        //     a_feature_file == 0 || a_support_file == 0 || a_alpha_file == 0 || a_intercept_file ||
        //     v_expected_file == 0 || a_expected_file == 0) begin
		// 	$display("Data Fetch Error");
		// 	$finish();
		// end

		for (i = 0; i < num_entry; i = i + 1) begin
			for (j = 0; j < F_WIDTH; j = j + 1) begin
				get_v_feature = $fscanf(v_feature_file, "%d\n", v_feature_memory[i][j]);
				get_a_feature = $fscanf(a_feature_file, "%d\n", a_feature_memory[i][j]);
			end
		end

		for (i = 0; i < num_entry; i = i + 1) begin
			get_v_expected = $fscanf(v_expected_file, "%b\n", v_expected_memory[i]);
			get_a_expected = $fscanf(a_expected_file, "%b\n", a_expected_memory[i]);
		end

    endfunction : initialize_memory

	function void write_power_yml_file();
		power_yml_file = $fopen("../../src/SVM_ROM_Systolic/svm_power.yml","w");
		$fwrite(power_yml_file, "power.inputs.waveforms_meta: \"append\"\n");
		$fwrite(power_yml_file, "power.inputs.waveforms:\n");
		$fwrite(power_yml_file, "   - \"/tools/B/daniels/hammer-tsmc28/build/sim-par-rundir/svm.vcd\"\n\n");
		$fwrite(power_yml_file, "power.inputs.database: \"/tools/B/daniels/hammer-tsmc28/build/par-rundir/latest\"\n");
		$fwrite(power_yml_file, "power.inputs.tb_name: \"SVM_tb\"\n\n");
		$fwrite(power_yml_file, "power.inputs.saifs_meta: \"append\"\n");
		$fwrite(power_yml_file, "power.inputs.saifs:\n");
		$fwrite(power_yml_file, "   - \"/tools/B/daniels/hammer-tsmc28/build/sim-par-rundir/svm.saif\"\n\n");
		$fwrite(power_yml_file, "power.inputs.start_times: [\"0\"]\n");
		$fwrite(power_yml_file, "power.inputs.end_times: [\"%0d\"]\n", $time); 
		$fwrite(power_yml_file, "power.inputs.resolution: %0d", `CLOCK_PERIOD / 2);
		$fclose(power_yml_file);
	endfunction : write_power_yml_file

	task start_cycle_counter;
		while (done == 0) begin
			@(negedge clk);
			cycle = cycle + 1;
		end
	endtask : start_cycle_counter

	task start_fin_sequence;

		integer i = 0;
        integer j;
		integer k;
		while (i < num_entry) begin

			fin_valid       = 1'b1;

			if (modality == 0) begin  // valence
				for (j = 0; j < F_WIDTH; j = j + 1) begin
					in_features[j*NBITS +: NBITS]	= v_feature_memory[i][j];
				end
			end else begin  // arousal
				for (j = 0; j < F_WIDTH; j = j + 1) begin
					in_features[j*NBITS +: NBITS]	= a_feature_memory[i][j];
				end
			end

			@(negedge clk);
			if (fin_ready) begin
				@(posedge clk);
				if (modality == 0) begin
					$display("Starting iteration %d", i);
					modality = 1;
				end else begin
					i = i + 1;
					modality = 0;
				end
			end

			@(posedge clk);
			fin_valid = 1'b0;

		end

	endtask : start_fin_sequence

	task start_fin_monitor;

		integer i = 0;
		while (i < num_entry) begin

			@(negedge clk);

			if (fin_valid && fin_ready && modality == 0) begin
				start_time[i] = cycle;
				i = i + 1;
			end

		end

	endtask : start_fin_monitor

	task start_dout_monitor;

		integer i = 0;
		while (i < num_entry) begin

			@(negedge clk);

			if (dout_valid && dout_ready) begin
				end_time[i] = cycle;

				if (valence != v_expected_memory[i]) begin
					$display("Output %d does not match the expected VALENCE label", i);
					$display("Label %d: \n%b,\nExpected Label: \n%b\n", i, valence, v_expected_memory[i]);
					num_fail = num_fail + 1;
				end

				if (arousal != a_expected_memory[i]) begin
					$display("Output %d does not match the expected AROUSAL label", i);
					$display("Label %d: \n%b,\nExpected Label: \n%b\n", i, arousal, a_expected_memory[i]);
					num_fail = num_fail + 1;
				end

				i = i + 1;
			end
		end

		done = 1;

	endtask : start_dout_monitor

endmodule : SVM_tb
