`include "const.vh"

module SVM_memories_214 #(
	parameter NBITS 		= 9,
	parameter VSUP_WIDTH	= 120,
	parameter ASUP_WIDTH 	= 155,
	parameter FMEM_WIDTH 	= 144,
	parameter LOG_FMEM_WIDTH = `ceilLog2(FMEM_WIDTH)
) (
    input                                   clk,
    input                                   rst,

    input           [LOG_FMEM_WIDTH-1:0]	addr,
    input                                   we,

    input signed    [NBITS*VSUP_WIDTH-1:0]  v_in_support,
    input signed    [NBITS-1:0]             v_in_alpha,

    input signed    [NBITS*ASUP_WIDTH-1:0]  a_in_support,
    input signed    [NBITS-1:0]             a_in_alpha,

	output signed 	[NBITS*VSUP_WIDTH-1:0]	v_out_support,
	output signed 	[NBITS-1:0]             v_out_alpha,

	output signed 	[NBITS*ASUP_WIDTH-1:0]	a_out_support,
	output signed 	[NBITS-1:0]             a_out_alpha
);

	wire [LOG_FMEM_WIDTH-1:0] v_alpha_addr;
	wire [LOG_FMEM_WIDTH-1:0] a_alpha_addr;

    wire valpha_we;
    wire aalpha_we;

	wire [71:0] 			vsQ7;
	wire [FMEM_WIDTH-1:0]   vsQ6;
	wire [FMEM_WIDTH-1:0]   vsQ5;
	wire [FMEM_WIDTH-1:0]   vsQ4;
	wire [FMEM_WIDTH-1:0]   vsQ3;
	wire [FMEM_WIDTH-1:0]   vsQ2;
	wire [FMEM_WIDTH-1:0]   vsQ1;
	wire [FMEM_WIDTH-1:0]   vsQ0;

	wire [98:0]				asQ9;
	wire [FMEM_WIDTH-1:0]   asQ8;
	wire [FMEM_WIDTH-1:0]   asQ7;
	wire [FMEM_WIDTH-1:0]   asQ6;
	wire [FMEM_WIDTH-1:0]   asQ5;
	wire [FMEM_WIDTH-1:0]   asQ4;
	wire [FMEM_WIDTH-1:0]   asQ3;
	wire [FMEM_WIDTH-1:0]   asQ2;
	wire [FMEM_WIDTH-1:0]   asQ1;
	wire [FMEM_WIDTH-1:0]   asQ0;

	assign v_alpha_addr			= (addr < 120) ? addr : 0;
	assign a_alpha_addr 		= (addr < 155) ? addr : 0;

	assign support_we 			= (addr < 214) ? we : 1'b1;
    assign valpha_we            = (addr < 120) ? we : 1'b1;
    assign aalpha_we            = (addr < 155) ? we : 1'b1;

	assign v_out_support = {vsQ7,vsQ6,vsQ5,vsQ4,vsQ3,vsQ2,vsQ1,vsQ0};
	assign a_out_support = {asQ9,asQ8,asQ7,asQ6,asQ5,asQ4,asQ3,asQ2,asQ1,asQ0};

	TS1N28HPMFHVTB128X9M4SW VALPHA_SRAM (
		.A 		(v_alpha_addr),
		.D 		(v_in_alpha),

		.BWEB	(9'd0),
		.WEB 	(valpha_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(v_out_alpha)
	);

	TS1N28HPMFHVTB160X9M4SW AALPHA_SRAM (
		.A 		(a_alpha_addr),
		.D 		(a_in_alpha),

		.BWEB	(9'd0),
		.WEB 	(aalpha_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(a_out_alpha)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM0 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH-1:0]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ0)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM1 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*2-1:FMEM_WIDTH]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ1)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM2 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*3-1:FMEM_WIDTH*2]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ2)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM3 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*4-1:FMEM_WIDTH*3]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ3)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM4 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*5-1:FMEM_WIDTH*4]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ4)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM5 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*6-1:FMEM_WIDTH*5]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ5)
	);

	TS1N28HPMFHVTB224X144M4SW VSUPPORT_SRAM6 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*7-1:FMEM_WIDTH*6]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ6)
	);

	TS1N28HPMFHVTB224X72M4SW VSUPPORT_SRAM7 (
		.A 		(addr),
		.D 		(v_in_support[FMEM_WIDTH*7 +: 72]),

		.BWEB	(72'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(vsQ7)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM0 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH-1:0]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ0)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM1 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*2-1:FMEM_WIDTH]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ1)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM2 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*3-1:FMEM_WIDTH*2]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ2)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM3 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*4-1:FMEM_WIDTH*3]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ3)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM4 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*5-1:FMEM_WIDTH*4]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ4)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM5 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*6-1:FMEM_WIDTH*5]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ5)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM6 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*7-1:FMEM_WIDTH*6]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ6)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM7 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*8-1:FMEM_WIDTH*7]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ7)
	);

	TS1N28HPMFHVTB224X144M4SW ASUPPORT_SRAM8 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*9-1:FMEM_WIDTH*8]),

		.BWEB	(144'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ8)
	);

	TS1N28HPMFHVTB224X99M4SW ASUPPORT_SRAM9 (
		.A 		(addr),
		.D 		(a_in_support[FMEM_WIDTH*9 +: 99]),

		.BWEB	(99'd0),
		.WEB 	(support_we),

		.CEB 	(1'b0),
		.CLK 	(clk),

		.Q		(asQ9)
	);

endmodule : SVM_memories_214
