`include "const.vh"

module hdc_sensor_fusion (
	input clk,
	input rst,

	input [`TOTAL_NUM_CHANNEL*`CHANNEL_WIDTH-1:0] features_top,
	input  fin_valid,
	output fin_ready,

	output valence,
	output arousal,
	output dout_valid,
	input  dout_ready,

	//------------------//
	// FPGA Connections //
	//------------------//

	input  write_enable,
	input  write_enable_valid,

	input  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_im_sram_addr,
	input  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_projm_pos_sram_addr,
	input  [`GSR_SRAM_ADDR_WIDTH-1:0] FPGA_GSR_projm_neg_sram_addr,
	input  [`HV_DIMENSION-1:0] FPGA_GSR_im_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_GSR_projm_pos_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_GSR_projm_neg_sram_hvin,

	input  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_im_sram_addr,
	input  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_projm_pos_sram_addr,
	input  [`ECG_SRAM_ADDR_WIDTH-1:0] FPGA_ECG_projm_neg_sram_addr,
	input  [`HV_DIMENSION-1:0] FPGA_ECG_im_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_ECG_projm_pos_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_ECG_projm_neg_sram_hvin,

	input  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_im_sram_addr,
	input  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_projm_pos_sram_addr,
	input  [`EEG_SRAM_ADDR_WIDTH-1:0] FPGA_EEG_projm_neg_sram_addr,
	input  [`HV_DIMENSION-1:0] FPGA_EEG_im_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_EEG_projm_pos_sram_hvin,
	input  [`HV_DIMENSION-1:0] FPGA_EEG_projm_neg_sram_hvin
);

	//----------//
	// Features //
	//----------//

	wire [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0];

	genvar i;
	for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) 
		assign features[`TOTAL_NUM_CHANNEL-1-i] = features_top[i*2+1:i*2];

	//---------------//
	// Miscellaneous //
	//---------------//

	reg  write_mode;  // write mode is active low

	always @(posedge clk) begin
		if (write_enable_valid) begin
			write_mode <= write_enable;
		end
	end

	//---------------------//
	// Registers and Wires //
	//---------------------//

	// Memory Controller Wires
	wire GSR_fin_valid, GSR_fin_ready;
	wire [`HV_DIMENSION-1:0] GSR_im, GSR_projm;
	wire GSR_mem_control_dout_valid;

	wire ECG_fin_valid, ECG_fin_ready;
	wire [`HV_DIMENSION-1:0] ECG_im, ECG_projm;
	wire ECG_mem_control_dout_valid;

	wire EEG_fin_valid, EEG_fin_ready;
	wire [`HV_DIMENSION-1:0] EEG_im, EEG_projm;
	wire EEG_mem_control_dout_valid;

	// Memory Wrapper Wires
	// GSR
	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_im_sram_addr;
	wire GSR_im_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] GSR_im_sram_hvin;
	reg  GSR_im_sram_hvin_valid;

	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_projm_pos_sram_addr;
	wire GSR_projm_pos_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] GSR_projm_pos_sram_hvin;
	reg  GSR_projm_pos_sram_hvin_valid;

	wire [`GSR_SRAM_ADDR_WIDTH-1:0] GSR_projm_neg_sram_addr;
	wire GSR_projm_neg_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] GSR_projm_neg_sram_hvin;
	reg  GSR_projm_neg_sram_hvin_valid;

	// ECG
	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_im_sram_addr;
	wire ECG_im_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] ECG_im_sram_hvin;
	reg  ECG_im_sram_hvin_valid;

	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_projm_pos_sram_addr;
	wire ECG_projm_pos_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] ECG_projm_pos_sram_hvin;
	reg  ECG_projm_pos_sram_hvin_valid;

	wire [`ECG_SRAM_ADDR_WIDTH-1:0] ECG_projm_neg_sram_addr;
	wire ECG_projm_neg_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] ECG_projm_neg_sram_hvin;
	reg  ECG_projm_neg_sram_hvin_valid;

	// EEG
	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_im_sram_addr;
	wire EEG_im_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] EEG_im_sram_hvin;
	reg  EEG_im_sram_hvin_valid;

	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_projm_pos_sram_addr;
	wire EEG_projm_pos_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] EEG_projm_pos_sram_hvin;
	reg  EEG_projm_pos_sram_hvin_valid;

	wire [`EEG_SRAM_ADDR_WIDTH-1:0] EEG_projm_neg_sram_addr;
	wire EEG_projm_neg_sram_addr_valid;
	wire [`HV_DIMENSION-1:0] EEG_projm_neg_sram_hvin;
	reg  EEG_projm_neg_sram_hvin_valid;

	// Spatial Encoder Wires
	wire GSR_se_din_ready;
	wire GSR_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] GSR_se_hvout;

	wire ECG_se_din_ready;
	wire ECG_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] ECG_se_hvout;

	wire EEG_se_din_ready;
	wire EEG_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] EEG_se_hvout;

	// Fuser Wires
	wire fuser_hvin_ready;
	wire fuser_hvout_valid;
	wire [`HV_DIMENSION-1:0] fuser_hvout;

	// Temporal Encoder Wires
	wire te_hvin_ready;
	wire te_hvout_valid;
	wire [`HV_DIMENSION-1:0] te_hvout;

	// Associative Memory Wire
	wire am_hvin_ready;

	//---------//
	// Modules //
	//---------//

	assign fin_ready = write_mode && GSR_fin_ready && ECG_fin_ready && EEG_fin_ready;

	always @(posedge clk) begin
		if (write_mode) begin
			GSR_im_sram_hvin_valid 			<= GSR_im_sram_addr_valid;
			GSR_projm_pos_sram_hvin_valid 	<= GSR_projm_pos_sram_addr_valid;
			GSR_projm_neg_sram_hvin_valid 	<= GSR_projm_neg_sram_addr_valid;
		end
	end

	memory_controller #(
		.num_channel				(`GSR_NUM_CHANNEL),
		.sram_addr_width			(`GSR_SRAM_ADDR_WIDTH)
	) GSR_MEM_CONTROLLER (
		.clk 						(clk),
		.rst 						(rst),
		
		.features 					(features[`GSR_NUM_CHANNEL-1:0]),
		.fin_valid 					(fin_valid && ECG_fin_ready && EEG_fin_ready),
		.fin_ready 					(GSR_fin_ready),

		.im 						(GSR_im),
		.projm 						(GSR_projm),
		.dout_valid					(GSR_mem_control_dout_valid),
		.dout_ready					(GSR_se_din_ready),

		// IM SRAM
		.im_sram_addr 				(GSR_im_sram_addr),
		.im_sram_addr_valid			(GSR_im_sram_addr_valid),  
		.im_sram_addr_ready			(1'b1),  

		.im_sram_hvin 				(GSR_im_sram_hvin), 
		.im_sram_hvin_valid 		(GSR_im_sram_hvin_valid),
		.im_sram_hvin_ready 		(),

		// ProjM Pos SRAM
		.projm_pos_sram_addr		(GSR_projm_pos_sram_addr),
		.projm_pos_sram_addr_valid	(GSR_projm_pos_sram_addr_valid),
		.projm_pos_sram_addr_ready	(1'b1),

		.projm_pos_sram_hvin		(GSR_projm_pos_sram_hvin),
		.projm_pos_sram_hvin_valid	(GSR_projm_pos_sram_hvin_valid),
		.projm_pos_sram_hvin_ready	(),

		// ProjM Neg SRAM
		.projm_neg_sram_addr		(GSR_projm_neg_sram_addr),
		.projm_neg_sram_addr_valid	(GSR_projm_neg_sram_addr_valid),
		.projm_neg_sram_addr_ready	(1'b1),

		.projm_neg_sram_hvin		(GSR_projm_neg_sram_hvin),
		.projm_neg_sram_hvin_valid	(GSR_projm_neg_sram_hvin_valid),
		.projm_neg_sram_hvin_ready	()
	);

	memory_wrapper_gsr #(
		.sram_addr_width		(`GSR_SRAM_ADDR_WIDTH),
		.sram_width				(144),
		.last_sram_width 		(128)
	) GSR_MEMORY_WRAPPER (
		.clk 			(clk),

		.we 			(write_mode),

		.im_addr 		(write_mode ? GSR_im_sram_addr : FPGA_GSR_im_sram_addr),
		.projm_pos_addr (write_mode ? GSR_projm_pos_sram_addr : FPGA_GSR_projm_pos_sram_addr),
		.projm_neg_addr (write_mode ? GSR_projm_neg_sram_addr : FPGA_GSR_projm_neg_sram_addr),

		.im_din 		(FPGA_GSR_im_sram_hvin),
		.projm_pos_din	(FPGA_GSR_projm_pos_sram_hvin),
		.projm_neg_din 	(FPGA_GSR_projm_neg_sram_hvin),

		.im_dout 		(GSR_im_sram_hvin),
		.projm_pos_dout	(GSR_projm_pos_sram_hvin),
		.projm_neg_dout	(GSR_projm_neg_sram_hvin)
	);

	always @(posedge clk) begin
		if (write_mode) begin
			ECG_im_sram_hvin_valid 			<= ECG_im_sram_addr_valid;
			ECG_projm_pos_sram_hvin_valid 	<= ECG_projm_pos_sram_addr_valid;
			ECG_projm_neg_sram_hvin_valid 	<= ECG_projm_neg_sram_addr_valid;
		end
	end

	memory_controller #(
		.num_channel				(`ECG_NUM_CHANNEL),
		.sram_addr_width			(`ECG_SRAM_ADDR_WIDTH)
	) ECG_MEM_CONTROLLER (
		.clk 						(clk),
		.rst 						(rst),
		
		.features 					(features[`ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL-1:`GSR_NUM_CHANNEL]),
		.fin_valid 					(fin_valid && GSR_fin_ready && EEG_fin_ready),
		.fin_ready 					(ECG_fin_ready),

		.im 						(ECG_im),
		.projm 						(ECG_projm),
		.dout_valid					(ECG_mem_control_dout_valid),
		.dout_ready					(ECG_se_din_ready),

		// IM SRAM
		.im_sram_addr 				(ECG_im_sram_addr),
		.im_sram_addr_valid			(ECG_im_sram_addr_valid),  
		.im_sram_addr_ready			(1'b1),  

		.im_sram_hvin 				(ECG_im_sram_hvin), 
		.im_sram_hvin_valid 		(ECG_im_sram_hvin_valid),
		.im_sram_hvin_ready 		(),

		// ProjM Pos SRAM
		.projm_pos_sram_addr		(ECG_projm_pos_sram_addr),
		.projm_pos_sram_addr_valid	(ECG_projm_pos_sram_addr_valid),
		.projm_pos_sram_addr_ready	(1'b1),

		.projm_pos_sram_hvin		(ECG_projm_pos_sram_hvin),
		.projm_pos_sram_hvin_valid	(ECG_projm_pos_sram_hvin_valid),
		.projm_pos_sram_hvin_ready	(),

		// ProjM Neg SRAM
		.projm_neg_sram_addr		(ECG_projm_neg_sram_addr),
		.projm_neg_sram_addr_valid	(ECG_projm_neg_sram_addr_valid),
		.projm_neg_sram_addr_ready	(1'b1),

		.projm_neg_sram_hvin		(ECG_projm_neg_sram_hvin),
		.projm_neg_sram_hvin_valid	(ECG_projm_neg_sram_hvin_valid),
		.projm_neg_sram_hvin_ready	()
	);

	memory_wrapper_ecg #(
		.sram_addr_width		(`ECG_SRAM_ADDR_WIDTH),
		.sram_width				(144),
		.last_sram_width 		(128)
	) ECG_MEMORY_WRAPPER (
		.clk 			(clk),

		.we 			(write_mode),

		.im_addr 		(write_mode ? ECG_im_sram_addr : FPGA_ECG_im_sram_addr),
		.projm_pos_addr (write_mode ? ECG_projm_pos_sram_addr : FPGA_ECG_projm_pos_sram_addr),
		.projm_neg_addr (write_mode ? ECG_projm_neg_sram_addr : FPGA_ECG_projm_neg_sram_addr),

		.im_din 		(FPGA_ECG_im_sram_hvin),
		.projm_pos_din	(FPGA_ECG_projm_pos_sram_hvin),
		.projm_neg_din 	(FPGA_ECG_projm_neg_sram_hvin),

		.im_dout 		(ECG_im_sram_hvin),
		.projm_pos_dout	(ECG_projm_pos_sram_hvin),
		.projm_neg_dout	(ECG_projm_neg_sram_hvin)
	);

	always @(posedge clk) begin
		if (write_mode) begin
			EEG_im_sram_hvin_valid 			<= EEG_im_sram_addr_valid;
			EEG_projm_pos_sram_hvin_valid 	<= EEG_projm_pos_sram_addr_valid;
			EEG_projm_neg_sram_hvin_valid 	<= EEG_projm_neg_sram_addr_valid;
		end
	end

	memory_controller #(
		.num_channel				(`EEG_NUM_CHANNEL),
		.sram_addr_width			(`EEG_SRAM_ADDR_WIDTH)
	) EEG_MEM_CONTROLLER (
		.clk 						(clk),
		.rst 						(rst),
		
		.features 					(features[`EEG_NUM_CHANNEL+`ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL-1:`ECG_NUM_CHANNEL+`GSR_NUM_CHANNEL]),
		.fin_valid 					(fin_valid && GSR_fin_ready && ECG_fin_ready),
		.fin_ready 					(EEG_fin_ready),

		.im 						(EEG_im),
		.projm 						(EEG_projm),
		.dout_valid					(EEG_mem_control_dout_valid),
		.dout_ready					(EEG_se_din_ready),

		// IM SRAM
		.im_sram_addr 				(EEG_im_sram_addr),
		.im_sram_addr_valid			(EEG_im_sram_addr_valid),  
		.im_sram_addr_ready			(1'b1),  

		.im_sram_hvin 				(EEG_im_sram_hvin), 
		.im_sram_hvin_valid 		(EEG_im_sram_hvin_valid),
		.im_sram_hvin_ready 		(),

		// ProjM Pos SRAM
		.projm_pos_sram_addr		(EEG_projm_pos_sram_addr),
		.projm_pos_sram_addr_valid	(EEG_projm_pos_sram_addr_valid),
		.projm_pos_sram_addr_ready	(1'b1),

		.projm_pos_sram_hvin		(EEG_projm_pos_sram_hvin),
		.projm_pos_sram_hvin_valid	(EEG_projm_pos_sram_hvin_valid),
		.projm_pos_sram_hvin_ready	(),

		// ProjM Neg SRAM
		.projm_neg_sram_addr		(EEG_projm_neg_sram_addr),
		.projm_neg_sram_addr_valid	(EEG_projm_neg_sram_addr_valid),
		.projm_neg_sram_addr_ready	(1'b1),

		.projm_neg_sram_hvin		(EEG_projm_neg_sram_hvin),
		.projm_neg_sram_hvin_valid	(EEG_projm_neg_sram_hvin_valid),
		.projm_neg_sram_hvin_ready	()
	);

	memory_wrapper_eeg #(
		.sram_addr_width		(`EEG_SRAM_ADDR_WIDTH),
		.sram_width				(144),
		.last_sram_width 		(128)
	) EEG_MEMORY_WRAPPER (
		.clk 			(clk),

		.we 			(write_mode),

		.im_addr 		(write_mode ? EEG_im_sram_addr : FPGA_EEG_im_sram_addr),
		.projm_pos_addr (write_mode ? EEG_projm_pos_sram_addr : FPGA_EEG_projm_pos_sram_addr),
		.projm_neg_addr (write_mode ? EEG_projm_neg_sram_addr : FPGA_EEG_projm_neg_sram_addr),

		.im_din 		(FPGA_EEG_im_sram_hvin),
		.projm_pos_din	(FPGA_EEG_projm_pos_sram_hvin),
		.projm_neg_din 	(FPGA_EEG_projm_neg_sram_hvin),

		.im_dout 		(EEG_im_sram_hvin),
		.projm_pos_dout	(EEG_projm_pos_sram_hvin),
		.projm_neg_dout	(EEG_projm_neg_sram_hvin)
	);

	spatial_encoder #(
		.num_channel	(`GSR_NUM_CHANNEL)
	) GSR_SE (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(GSR_mem_control_dout_valid),
		.din_ready		(GSR_se_din_ready),
		.im 			(GSR_im),
		.projm			(GSR_projm),

		.hvout_valid	(GSR_se_hvout_valid),
		.hvout_ready	(fuser_hvin_ready && ECG_se_hvout_valid && EEG_se_hvout_valid),
		.hvout			(GSR_se_hvout)
	);

	spatial_encoder #(
		.num_channel	(`ECG_NUM_CHANNEL)
	) ECG_SE (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(ECG_mem_control_dout_valid),
		.din_ready		(ECG_se_din_ready),
		.im 			(ECG_im),
		.projm			(ECG_projm),

		.hvout_valid	(ECG_se_hvout_valid),
		.hvout_ready	(fuser_hvin_ready && GSR_se_hvout_valid && EEG_se_hvout_valid),
		.hvout			(ECG_se_hvout)
	);

	spatial_encoder #(
		.num_channel	(`EEG_NUM_CHANNEL)
	) EEG_SE (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(EEG_mem_control_dout_valid),
		.din_ready		(EEG_se_din_ready),
		.im 			(EEG_im),
		.projm			(EEG_projm),

		.hvout_valid	(EEG_se_hvout_valid),
		.hvout_ready	(fuser_hvin_ready && GSR_se_hvout_valid && ECG_se_hvout_valid),
		.hvout			(EEG_se_hvout)
	);

	fuser FUSER (
		.hvin_ready		(fuser_hvin_ready),

		.hvin1_valid	(GSR_se_hvout_valid),
		.hvin1			(GSR_se_hvout),

		.hvin2_valid	(ECG_se_hvout_valid),
		.hvin2			(ECG_se_hvout),

		.hvin3_valid	(EEG_se_hvout_valid),
		.hvin3			(EEG_se_hvout),

		.hvout_valid	(fuser_hvout_valid),
		.hvout_ready	(te_hvin_ready),
		.hvout			(fuser_hvout)
	);

	temporal_encoder TE (
		.clk			(clk),
		.rst			(rst),

		.hvin_valid		(fuser_hvout_valid),
		.hvin_ready		(te_hvin_ready),
		.hvin			(fuser_hvout),

		.hvout_valid	(te_hvout_valid),
		.hvout_ready	(am_hvin_ready),
		.hvout			(te_hvout)
	);

	associative_memory AM (
		.clk			(clk),
		.rst			(rst),

		.hvin_valid		(te_hvout_valid),
		.hvin_ready		(am_hvin_ready),
		.hvin			(te_hvout),

		.dout_valid		(dout_valid),
		.dout_ready		(dout_ready),
		.valence		(valence),
		.arousal		(arousal)
	);

endmodule : hdc_sensor_fusion