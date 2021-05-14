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

	TS1N28HPMFHVTB864X144M4SW IM_SRAM1 (
		.A 		(im_addr),
		.D 		(im_din[sram_width-1:0]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q1)
	);

	TS1N28HPMFHVTB864X144M4SW IM_SRAM2 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*2-1:sram_width]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q2)
	);

	TS1N28HPMFHVTB864X144M4SW IM_SRAM3 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*3-1:sram_width*2]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q3)
	);

	TS1N28HPMFHVTB864X68M4SW IM_SRAM4 (
		.A 		(im_addr),
		.D 		(im_din[FOLD_WIDTH-1:sram_width*3]),

		.BWEB	({last_sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q4)
	);

endmodule : memory_wrapper
