`include "/tools/B/daniels/hammer-tsmc28/src/SVM_ROM_Naive/const.vh"

module SVM_memories_214 #(
	parameter NBITS				= 9,
	parameter VSUP_WIDTH 		= 120,
	parameter ASUP_WIDTH		= 155,
	parameter ROM_DEPTH			= 1024,
	parameter LOG_ROM_DEPTH		= `ceilLog2(ROM_DEPTH),
	parameter ROM_WIDTH 		= 128,
	parameter ROM_TOTAL_WIDTH	= 1408
) (
	input 									clk,

	input 			[LOG_ROM_DEPTH-1:0]		addr,

	output signed 	[ROM_TOTAL_WIDTH-1:0]	mem_out
);

	wire [ROM_WIDTH-1:0]		R0Q;
	wire [ROM_WIDTH-1:0]		R1Q;
	wire [ROM_WIDTH-1:0]		R2Q;
	wire [ROM_WIDTH-1:0]		R3Q;
	wire [ROM_WIDTH-1:0]		R4Q;
	wire [ROM_WIDTH-1:0]		R5Q;
	wire [ROM_WIDTH-1:0]		R6Q;
	wire [ROM_WIDTH-1:0]		R7Q;
	wire [ROM_WIDTH-1:0]		R8Q;
	wire [ROM_WIDTH-1:0]		R9Q;
	wire [ROM_WIDTH-1:0]		R10Q;

	assign mem_out = {R0Q, R1Q, R2Q, R3Q, R4Q, R5Q, R6Q, R7Q, R8Q, R9Q, R10Q};

	// 1024 x 128
	imem0 ROM0 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R0Q)
	);

	imem1 ROM1 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R1Q)
	);

	imem2 ROM2 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R2Q)
	);

	imem3 ROM3 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R3Q)
	);

	imem4 ROM4 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R4Q)
	);

	imem5 ROM5 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R5Q)
	);

	imem6 ROM6 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R6Q)
	);

	imem7 ROM7 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R7Q)
	);

	imem8 ROM8 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R8Q)
	);

	imem9 ROM9 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R9Q)
	);

	imem10 ROM10 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R10Q)
	);

endmodule : SVM_memories_214
