`include "const.vh"

module hdc_sensor_fusion (
	input clk,
	input rst,

	input [`TOTAL_NUM_CHANNEL*`CHANNEL_WIDTH-1:0] features_top,
	//input  [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0],
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

	input  [2:0] addr_1,
	input  [`HV_DIMENSION-1:0] hv_1,

	input  [2:0] addr_2,
	input  [`HV_DIMENSION-1:0] hv_2,

	input  [2:0] addr_3,
	input  [`HV_DIMENSION-1:0] hv_3
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
	reg  [2:0] addr_1_reg;
	reg  [2:0] addr_2_reg;
	reg  [2:0] addr_3_reg;
	reg  [`HV_DIMENSION-1:0] hv_1_reg;
	reg  [`HV_DIMENSION-1:0] hv_2_reg;
	reg  [`HV_DIMENSION-1:0] hv_3_reg;

	always @(posedge clk) begin
		if (write_enable_valid) begin
			write_mode <= write_enable;
			addr_1_reg <= addr_1;
			addr_2_reg <= addr_2;
			addr_3_reg <= addr_3;
			hv_1_reg <= hv_1;
			hv_2_reg <= hv_2;
			hv_3_reg <= hv_3;
		end
	end

	//---------------------//
	// Registers and Wires //
	//---------------------//

	// MEM_CONTROLLER
	wire mc_fin_ready;

	wire [`HV_DIMENSION-1:0] GSR_im, GSR_projm;
	wire GSR_dout_valid;

	wire [`HV_DIMENSION-1:0] ECG_im, ECG_projm;
	wire ECG_dout_valid;
	
	wire [`HV_DIMENSION-1:0] EEG_im, EEG_projm;
	wire EEG_dout_valid;

	wire [2:0] mc_addr_1;
	wire [`HV_DIMENSION-1:0] mc_hv_1;

	wire [2:0] mc_addr_2;
	wire [`HV_DIMENSION-1:0] mc_hv_2;

	wire [2:0] mc_addr_3;
	wire [`HV_DIMENSION-1:0] mc_hv_3;

	// GSR_SE
	wire GSR_se_din_ready;

	wire GSR_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] GSR_se_hvout;

	// ECG_SE
	wire ECG_se_din_ready;

	wire ECG_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] ECG_se_hvout;

	// EEG_SE
	wire EEG_se_din_ready;

	wire EEG_se_hvout_valid;
	wire [`HV_DIMENSION-1:0] EEG_se_hvout;

	// FUSER
	wire fuser_hvin_ready;

	wire fuser_hvout_valid;
	wire [`HV_DIMENSION-1:0] fuser_hvout;

	// TE
	wire te_hvin_ready;

	wire te_hvout_valid;
	wire [`HV_DIMENSION-1:0] te_hvout;

	// AM
	wire am_hvin_ready;

	//---------//
	// Modules //
	//---------//

	assign fin_ready = write_mode && mc_fin_ready;

	memory_controller MEM_CONTROLLER (
		.clk			(clk),
		.rst			(rst),

		.features		(features),
		.fin_valid		(fin_valid),
		.fin_ready		(mc_fin_ready),

		.GSR_im			(GSR_im),
		.GSR_projm		(GSR_projm),
		.GSR_dout_valid	(GSR_dout_valid),
		.GSR_dout_ready	(GSR_se_din_ready),

		.ECG_im			(ECG_im),
		.ECG_projm		(ECG_projm),
		.ECG_dout_valid	(ECG_dout_valid),
		.ECG_dout_ready	(ECG_se_din_ready),

		.EEG_im			(EEG_im),
		.EEG_projm		(EEG_projm),
		.EEG_dout_valid	(EEG_dout_valid),
		.EEG_dout_ready	(EEG_se_din_ready),

		.addr_1			(mc_addr_1),
		.hv_1			(mc_hv_1),

		.addr_2			(mc_addr_2),
		.hv_2			(mc_hv_2),

		.addr_3			(mc_addr_3),
		.hv_3			(mc_hv_3)
	);

	spatial_encoder #(
		.num_channel	(`GSR_NUM_CHANNEL)
	) GSR_SE (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(GSR_dout_valid),
		.din_ready		(GSR_se_din_ready),
		.im				(GSR_im),
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

		.din_valid		(ECG_dout_valid),
		.din_ready		(ECG_se_din_ready),
		.im				(ECG_im),
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

		.din_valid		(EEG_dout_valid),
		.din_ready		(EEG_se_din_ready),
		.im				(EEG_im),
		.projm			(EEG_projm),

		.hvout_valid	(EEG_se_hvout_valid),
		.hvout_ready	(fuser_hvin_ready && ECG_se_hvout_valid && GSR_se_hvout_valid),
		.hvout			(EEG_se_hvout)
	);

	memory_wrapper MEMORY_1 (
		.clk	(clk),

		.we		(write_mode),
		.addr	(write_mode ? mc_addr_1 : addr_1_reg),
		.din	(hv_1_reg),
		.dout	(mc_hv_1)
	);

	memory_wrapper MEMORY_2 (
		.clk	(clk),

		.we		(write_mode),
		.addr	(write_mode ? mc_addr_2 : addr_2_reg),
		.din	(hv_2_reg),
		.dout	(mc_hv_2)
	);

	memory_wrapper MEMORY_3 (
		.clk	(clk),

		.we		(write_mode),
		.addr	(write_mode ? mc_addr_3 : addr_3_reg),
		.din	(hv_3_reg),
		.dout	(mc_hv_3)
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
