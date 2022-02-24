`include "const.vh"

module SVM_memories_214 #(
	parameter NBITS,
	parameter VSUP_WIDTH,
	parameter ASUP_WIDTH,
	parameter ROM_DEPTH,
	parameter LOG_ROM_DEPTH,
	parameter ROM_WIDTH,
	parameter ROM_TOTAL_WIDTH
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
	wire [ROM_WIDTH-1:0]		R11Q;
	wire [ROM_WIDTH-1:0]		R12Q;
	wire [ROM_WIDTH-1:0]		R13Q;
	wire [ROM_WIDTH-1:0]		R14Q;
	wire [ROM_WIDTH-1:0]		R15Q;

	assign mem_out = {R0Q, R1Q, R2Q, R3Q, R4Q, R5Q, R6Q, R7Q, R8Q, R9Q, R10Q, R11Q, R12Q, R13Q, R14Q, R15Q};

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

	imem11 ROM11 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R11Q)
	);

	imem12 ROM12 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R12Q)
	);

	imem13 ROM13 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R13Q)
	);

	imem14 ROM14 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R14Q)
	);

	imem15 ROM15 (
		.RTSEL		(2'b00),
		.PTSEL 		(2'b01),
		.TRB 		(2'b10),

		.CLK 		(clk),
		.CEB 		(1'b0),

		.A 			(addr),
		.Q 			(R15Q)
	);

endmodule : SVM_memories_214
