`include "const.vh"

module memory_wrapper_ecg  #(
	parameter sram_addr_width = 7,
	parameter sram_width = 144,
	parameter last_sram_width = 128
) (
	input 		clk,

	input 		we,

	input 		[sram_addr_width-1:0] im_addr,
	input 		[sram_addr_width-1:0] projm_pos_addr,
	input 		[sram_addr_width-1:0] projm_neg_addr,

	input 		[`HV_DIMENSION-1:0] im_din,
	input 		[`HV_DIMENSION-1:0] projm_pos_din,
	input 		[`HV_DIMENSION-1:0] projm_neg_din,

	output 		[`HV_DIMENSION-1:0] im_dout,
	output 		[`HV_DIMENSION-1:0] projm_pos_dout,
	output 		[`HV_DIMENSION-1:0] projm_neg_dout
);

	wire [sram_width-1:0] im_Q1;
	wire [sram_width-1:0] im_Q2;
	wire [sram_width-1:0] im_Q3;
	wire [sram_width-1:0] im_Q4;
	wire [sram_width-1:0] im_Q5;
	wire [sram_width-1:0] im_Q6;
	wire [sram_width-1:0] im_Q7;
	wire [sram_width-1:0] im_Q8;
	wire [sram_width-1:0] im_Q9;
	wire [sram_width-1:0] im_Q10;
	wire [sram_width-1:0] im_Q11;
	wire [sram_width-1:0] im_Q12;
	wire [sram_width-1:0] im_Q13;
	wire [last_sram_width-1:0] im_Q14;

	wire [sram_width-1:0] projm_pos_Q1;
	wire [sram_width-1:0] projm_pos_Q2;
	wire [sram_width-1:0] projm_pos_Q3;
	wire [sram_width-1:0] projm_pos_Q4;
	wire [sram_width-1:0] projm_pos_Q5;
	wire [sram_width-1:0] projm_pos_Q6;
	wire [sram_width-1:0] projm_pos_Q7;
	wire [sram_width-1:0] projm_pos_Q8;
	wire [sram_width-1:0] projm_pos_Q9;
	wire [sram_width-1:0] projm_pos_Q10;
	wire [sram_width-1:0] projm_pos_Q11;
	wire [sram_width-1:0] projm_pos_Q12;
	wire [sram_width-1:0] projm_pos_Q13;
	wire [last_sram_width-1:0] projm_pos_Q14;

	wire [sram_width-1:0] projm_neg_Q1;
	wire [sram_width-1:0] projm_neg_Q2;
	wire [sram_width-1:0] projm_neg_Q3;
	wire [sram_width-1:0] projm_neg_Q4;
	wire [sram_width-1:0] projm_neg_Q5;
	wire [sram_width-1:0] projm_neg_Q6;
	wire [sram_width-1:0] projm_neg_Q7;
	wire [sram_width-1:0] projm_neg_Q8;
	wire [sram_width-1:0] projm_neg_Q9;
	wire [sram_width-1:0] projm_neg_Q10;
	wire [sram_width-1:0] projm_neg_Q11;
	wire [sram_width-1:0] projm_neg_Q12;
	wire [sram_width-1:0] projm_neg_Q13;
	wire [last_sram_width-1:0] projm_neg_Q14;

	assign im_dout = {im_Q14,im_Q13,im_Q12,im_Q11,im_Q10,im_Q9,im_Q8,im_Q7,im_Q6,
					  im_Q5,im_Q4,im_Q3,im_Q2,im_Q1};

	assign projm_pos_dout = {projm_pos_Q14,projm_pos_Q13,projm_pos_Q12,projm_pos_Q11,projm_pos_Q10,projm_pos_Q9,projm_pos_Q8,projm_pos_Q7,projm_pos_Q6,
					  projm_pos_Q5,projm_pos_Q4,projm_pos_Q3,projm_pos_Q2,projm_pos_Q1};

	assign projm_neg_dout = {projm_neg_Q14,projm_neg_Q13,projm_neg_Q12,projm_neg_Q11,projm_neg_Q10,projm_neg_Q9,projm_neg_Q8,projm_neg_Q7,projm_neg_Q6,
					  projm_neg_Q5,projm_neg_Q4,projm_neg_Q3,projm_neg_Q2,projm_neg_Q1};

	//----------//
	// IM SRAMS //
	//----------//

	TS1N28HPMFHVTB80X144M4SW IM_SRAM1 (
		.A 		(im_addr),
		.D 		(im_din[sram_width-1:0]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q1)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM2 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*2-1:sram_width]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q2)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM3 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*3-1:sram_width*2]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q3)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM4 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*4-1:sram_width*3]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q4)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM5 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*5-1:sram_width*4]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q5)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM6 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*6-1:sram_width*5]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q6)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM7 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*7-1:sram_width*6]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q7)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM8 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*8-1:sram_width*7]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q8)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM9 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*9-1:sram_width*8]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q9)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM10 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*10-1:sram_width*9]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q10)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM11 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*11-1:sram_width*10]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q11)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM12 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*12-1:sram_width*11]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q12)
	);

	TS1N28HPMFHVTB80X144M4SW IM_SRAM13 (
		.A 		(im_addr),
		.D 		(im_din[sram_width*13-1:sram_width*12]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q13)
	);

	TS1N28HPMFHVTB80X128M4SW IM_SRAM14 (
		.A 		(im_addr),
		.D 		(im_din[`HV_DIMENSION-1:sram_width*13]),

		.BWEB	({last_sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(im_Q14)
	);

	//----------------//
	// PROJMPOS SRAMS //
	//----------------//

	TS1N28HPMFHVTB80X144M4SW PROJM_POS1 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width-1:0]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q1)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS2 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*2-1:sram_width]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q2)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS3 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*3-1:sram_width*2]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q3)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS4 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*4-1:sram_width*3]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q4)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS5 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*5-1:sram_width*4]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q5)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS6 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*6-1:sram_width*5]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q6)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS7 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*7-1:sram_width*6]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q7)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS8 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*8-1:sram_width*7]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q8)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS9 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*9-1:sram_width*8]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q9)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS10 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*10-1:sram_width*9]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q10)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS11 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*11-1:sram_width*10]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q11)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS12 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*12-1:sram_width*11]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q12)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_POS13 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[sram_width*13-1:sram_width*12]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q13)
	);

	TS1N28HPMFHVTB80X128M4SW PROJM_POS14 (
		.A 		(projm_pos_addr),
		.D 		(projm_pos_din[`HV_DIMENSION-1:sram_width*13]),

		.BWEB	({last_sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_pos_Q14)
	);

	//----------------//
	// PROJMNEG SRAMS //
	//----------------//

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG1 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width-1:0]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q1)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG2 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*2-1:sram_width]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q2)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG3 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*3-1:sram_width*2]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q3)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG4 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*4-1:sram_width*3]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q4)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG5 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*5-1:sram_width*4]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q5)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG6 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*6-1:sram_width*5]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q6)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG7 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*7-1:sram_width*6]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q7)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG8 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*8-1:sram_width*7]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q8)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG9 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*9-1:sram_width*8]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q9)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG10 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*10-1:sram_width*9]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q10)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG11 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*11-1:sram_width*10]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q11)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG12 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*12-1:sram_width*11]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q12)
	);

	TS1N28HPMFHVTB80X144M4SW PROJM_NEG13 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[sram_width*13-1:sram_width*12]),

		.BWEB	({sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q13)
	);

	TS1N28HPMFHVTB80X128M4SW PROJM_NEG14 (
		.A 		(projm_neg_addr),
		.D 		(projm_neg_din[`HV_DIMENSION-1:sram_width*13]),

		.BWEB	({last_sram_width{1'b0}}),
		.WEB 	(we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(projm_neg_Q14)
	);


endmodule : memory_wrapper_ecg