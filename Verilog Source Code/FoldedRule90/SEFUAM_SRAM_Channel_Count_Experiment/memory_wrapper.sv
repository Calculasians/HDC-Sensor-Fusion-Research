`include "const.vh"

module memory_wrapper #(
	parameter FOLD_WIDTH,
	parameter SRAM_ADDR_WIDTH
) (
	input 		clk, 

	input		we,

	input 		[SRAM_ADDR_WIDTH-1:0] 	im_addr,
	input 		[FOLD_WIDTH-1:0] 		im_din,
	output 		[FOLD_WIDTH-1:0]		im_dout
);

	localparam sram_width = 144;
	localparam last_sram_width = 68;

	wire [sram_width-1:0] im_Q1;
	wire [sram_width-1:0] im_Q2;
	wire [sram_width-1:0] im_Q3;
	wire [last_sram_width-1:0] im_Q4;

	assign im_dout = {im_Q4,im_Q3,im_Q2,im_Q1};

	imem1 IM_SRAM1 (
		.RTSEL		(2'b00),
		.PTSEL		(2'b01),
		.TRB		(2'b10),

		.A 		(im_addr),
		//.D 		(im_din[sram_width-1:0]),

		//.BWEB	({sram_width{1'b0}}),
		//.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q1)
	);

	imem2 IM_SRAM2 (
		.RTSEL		(2'b00),
		.PTSEL		(2'b01),
		.TRB		(2'b10),

		.A 		(im_addr),
		//.D 		(im_din[sram_width*2-1:sram_width]),

		//.BWEB	({sram_width{1'b0}}),
		//.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q2)
	);

	imem3 IM_SRAM3 (
		.RTSEL		(2'b00),
		.PTSEL		(2'b01),
		.TRB		(2'b10),

		.A 		(im_addr),
		//.D 		(im_din[sram_width*3-1:sram_width*2]),

		//.BWEB	({sram_width{1'b0}}),
		//.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q3)
	);

	imem4 IM_SRAM4 (
		.RTSEL		(2'b00),
		.PTSEL		(2'b01),
		.TRB		(2'b10),

		.A 		(im_addr),
		//.D 		(im_din[FOLD_WIDTH-1:sram_width*3]),

		//.BWEB	({last_sram_width{1'b0}}),
		//.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q4)
	);

endmodule : memory_wrapper
