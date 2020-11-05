`include "const.vh"

module memory_controller #(
	parameter num_channel     = 32,
	parameter sram_addr_width = `ceilLog2(num_channel)
) (
	input  clk,
	input  rst,

	input  [`CHANNEL_WIDTH-1:0] features [num_channel-1:0],
	input  fin_valid,
	output reg fin_ready,

	output [`HV_DIMENSION-1:0] im,
	output reg [`HV_DIMENSION-1:0] projm,
	output dout_valid,
	input  dout_ready,

	// IM SRAM
	output reg [sram_addr_width-1:0] im_sram_addr,
	output reg im_sram_addr_valid,
	input  im_sram_addr_ready,

	input  [`HV_DIMENSION-1:0] im_sram_hvin,
	input  im_sram_hvin_valid,
	output im_sram_hvin_ready,

	// ProjM Pos SRAM
	output [sram_addr_width-1:0] projm_pos_sram_addr,
	output projm_pos_sram_addr_valid,
	input  projm_pos_sram_addr_ready,

	input  [`HV_DIMENSION-1:0] projm_pos_sram_hvin,
	input  projm_pos_sram_hvin_valid,
	output projm_pos_sram_hvin_ready,

	// ProjM Neg SRAM
	output [sram_addr_width-1:0] projm_neg_sram_addr,
	output projm_neg_sram_addr_valid,
	input  projm_neg_sram_addr_ready,

	input  [`HV_DIMENSION-1:0] projm_neg_sram_hvin,
	input  projm_neg_sram_hvin_valid,
	output projm_neg_sram_hvin_ready
);

	//---------------------//
	// Registers and Wires //
	//---------------------//

	wire fin_fire;
	wire im_sram_addr_fire;
	wire dout_fire;

	reg  [`CHANNEL_WIDTH-1:0] feature_memory [num_channel-1:0];

	reg  [sram_addr_width-1:0] active_sram_addr;

	wire [`CHANNEL_WIDTH-1:0] request_projm;
	reg  [`CHANNEL_WIDTH-1:0] active_projm;
	reg  projm_sram_hvin_valid;

	//---------------//
	// General Logic //
	//---------------//

	assign fin_fire  = fin_valid && fin_ready;

	always @(posedge clk) begin
		if (rst)
			fin_ready <= 1'b1;
		else if (fin_fire)
			fin_ready <= 1'b0;
		else if (active_sram_addr == num_channel-1 && dout_fire)
			fin_ready <= 1'b1;
	end

	integer i;
	always @(posedge clk) begin
		if (rst)
			for (i = 0; i < num_channel; i = i + 1) feature_memory[i] <= {`CHANNEL_WIDTH{1'b0}};
		else if (fin_fire)
			for (i = 0; i < num_channel; i = i + 1) feature_memory[i] <= features[i];
	end

	assign dout_fire  = dout_valid && dout_ready;
	assign dout_valid = im_sram_hvin_valid && projm_sram_hvin_valid;

	//-------------------//
	// Item Memory Logic //
	//-------------------//

	assign im_sram_addr_fire = im_sram_addr_valid && im_sram_addr_ready;

	always @(posedge clk) begin
		if (fin_fire)
			im_sram_addr_valid <= 1'b1;
		else if (im_sram_addr == num_channel-1 && im_sram_addr_ready)
			im_sram_addr_valid <= 1'b0;
	end

	always @(posedge clk) begin
		if (fin_fire)
			im_sram_addr <= {sram_addr_width{1'b0}};
		else if (im_sram_addr_fire && im_sram_addr < num_channel-1)
			im_sram_addr <= im_sram_addr + 1;
	end

	assign im_sram_hvin_ready = dout_ready && projm_sram_hvin_valid;
	assign im                 = im_sram_hvin;

	//-------------------------//
	// Projection Memory Logic //
	//-------------------------//

	assign request_projm = feature_memory[im_sram_addr];

	assign projm_pos_sram_addr_valid = im_sram_addr_valid && request_projm == 1;
	assign projm_pos_sram_addr       = im_sram_addr;
	assign projm_pos_sram_hvin_ready = dout_ready && im_sram_hvin_valid;

	assign projm_neg_sram_addr_valid = im_sram_addr_valid && request_projm == 2;
	assign projm_neg_sram_addr       = im_sram_addr;
	assign projm_neg_sram_hvin_ready = dout_ready && im_sram_hvin_valid;

	always @(posedge clk) begin
		if (im_sram_addr_fire) begin
			active_sram_addr <= im_sram_addr;
			active_projm     <= request_projm;
		end
	end

	always @(*) begin
		if (active_projm == 1) begin
			projm_sram_hvin_valid = projm_pos_sram_hvin_valid;
			projm                 = projm_pos_sram_hvin;
		end
		else if (active_projm == 2) begin
			projm_sram_hvin_valid = projm_neg_sram_hvin_valid;
			projm                 = projm_neg_sram_hvin;
		end
		else begin
			projm_sram_hvin_valid = ~fin_ready;
			projm                 = {`HV_DIMENSION{1'b0}};
		end
	end

endmodule : memory_controller