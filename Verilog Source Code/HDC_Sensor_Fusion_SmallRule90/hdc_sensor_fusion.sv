`include "const.vh"

module hdc_sensor_fusion (
	input clk,
	input rst,

	input  fin_valid,
	output fin_ready,
	input [`TOTAL_NUM_CHANNEL*`CHANNEL_WIDTH-1:0] features_top,

	output dout_valid,
	input  dout_ready,
	output valence,
	output arousal
);

	//----------//
	// Features //
	//----------//

	wire [`CHANNEL_WIDTH-1:0] features [`TOTAL_NUM_CHANNEL-1:0];

	genvar i;
	for (i = 0; i < `TOTAL_NUM_CHANNEL; i = i + 1) 
		assign features[`TOTAL_NUM_CHANNEL-1-i] = features_top[i*2+1:i*2];

	//---------------------//
	// Registers and Wires //
	//---------------------//

	// HV GENERATOR

	wire	hv_gen_dout_valid;
	wire	[`HV_DIMENSION-1:0] im;
	wire 	[`HV_DIMENSION-1:0] projm;
	wire 	[`MAX_NUM_CHANNEL_WIDTH-1:0] num_channel;

	// SE

	wire	se_din_ready;
	wire	se_hvout_valid;
	wire	[`HV_DIMENSION-1:0] se_hvout;

	// FUSER

	wire	fuser_hvin_ready;
	wire	fuser_hvout_valid;
	wire	[`HV_DIMENSION-1:0] fuser_hvout;

	// TE

	wire	te_hvin_ready;
	wire	te_hvout_valid;
	wire	[`HV_DIMENSION-1:0] te_hvout;

	// AM

	wire	am_hvin_ready;

	//---------//
	// Modules //
	//---------//

	hv_generator HV_GEN (
		.clk			(clk),
		.rst			(rst),

		.fin_valid		(fin_valid),
		.fin_ready		(fin_ready),
		.features		(features),

		.dout_valid		(hv_gen_dout_valid),
		.dout_ready		(se_din_ready),
		.im				(im),
		.projm			(projm),
		.num_channel	(num_channel)
	);

	spatial_encoder SE (
		.clk			(clk),
		.rst			(rst),

		.din_valid		(hv_gen_dout_valid),
		.din_ready		(se_din_ready),
		.im				(im),
		.projm			(projm),
		.num_channel	(num_channel),

		.hvout_valid	(se_hvout_valid),
		.hvout_ready	(fuser_hvin_ready),
		.hvout			(se_hvout)
	);

	fuser FUSER (
		.clk			(clk),
		.rst			(rst),

		.hvin_valid		(se_hvout_valid),
		.hvin_ready		(fuser_hvin_ready),
		.hvin			(se_hvout),

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