`include "const.vh"

module memory_wrapper (
	input 		clk,

	input 		we,
	input 		[2:0] addr,
	input 		[`HV_DIMENSION-1:0] din,

	output 		[`HV_DIMENSION-1:0] dout
);

	localparam sram_depth = 16;
	localparam sram_width = 72;
	localparam sram_width64 = 64; 

	wire [1:0] WTSEL, RTSEL;
	wire VG, VS;

	wire [3:0] AA, AB;

	wire WEBA, WEBB;

	wire [`HV_DIMENSION/2-1:0] din_a;
	wire [`HV_DIMENSION/2-1:0] din_b;

	wire [sram_width-1:0] QA1;
	wire [sram_width-1:0] QA2;
	wire [sram_width-1:0] QA3;
	wire [sram_width-1:0] QA4;
	wire [sram_width-1:0] QA5;
	wire [sram_width-1:0] QA6;
	wire [sram_width-1:0] QA7;
	wire [sram_width-1:0] QA8;
	wire [sram_width-1:0] QA9;
	wire [sram_width-1:0] QA10;
	wire [sram_width-1:0] QA11;
	wire [sram_width-1:0] QA12;
	wire [sram_width-1:0] QA13;
	wire [sram_width64-1:0] QA14;

	wire [sram_width-1:0] QB1;
	wire [sram_width-1:0] QB2;
	wire [sram_width-1:0] QB3;
	wire [sram_width-1:0] QB4;
	wire [sram_width-1:0] QB5;
	wire [sram_width-1:0] QB6;
	wire [sram_width-1:0] QB7;
	wire [sram_width-1:0] QB8;
	wire [sram_width-1:0] QB9;
	wire [sram_width-1:0] QB10;
	wire [sram_width-1:0] QB11;
	wire [sram_width-1:0] QB12;
	wire [sram_width-1:0] QB13;
	wire [sram_width64-1:0] QB14;


	assign WTSEL = 2'b01;
	assign RTSEL = 2'b01;
	assign VG 	 = 1'b1;
	assign VS    = 1'b1;

	assign AA = {1'b0, addr};
	assign AB = {1'b1, addr};

	assign WEBA = we;
	assign WEBB = we;

	assign din_a = din[`HV_DIMENSION/2-1:0];
	assign din_b = din[`HV_DIMENSION-1:`HV_DIMENSION/2];

	assign dout = {QB14,QB13,QB12,QB11,QB10,QB9,QB8,QB7,QB6,QB5,QB4,QB3,QB2,QB1,
	               QA14,QA13,QA12,QA11,QA10,QA9,QA8,QA7,QA6,QA5,QA4,QA3,QA2,QA1};

	TSDN28HPMA16X72M4FW sram1 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width-1:0]),
		.DB		(din_b[sram_width-1:0]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA1),
		.QB		(QB1)
	);

	TSDN28HPMA16X72M4FW sram2 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*2-1:sram_width]),
		.DB		(din_b[sram_width*2-1:sram_width]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA2),
		.QB		(QB2)
	);

	TSDN28HPMA16X72M4FW sram3 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*3-1:sram_width*2]),
		.DB		(din_b[sram_width*3-1:sram_width*2]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA3),
		.QB		(QB3)
	);

	TSDN28HPMA16X72M4FW sram4 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*4-1:sram_width*3]),
		.DB		(din_b[sram_width*4-1:sram_width*3]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA4),
		.QB		(QB4)
	);

	TSDN28HPMA16X72M4FW sram5 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*5-1:sram_width*4]),
		.DB		(din_b[sram_width*5-1:sram_width*4]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA5),
		.QB		(QB5)
	);

	TSDN28HPMA16X72M4FW sram6 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*6-1:sram_width*5]),
		.DB		(din_b[sram_width*6-1:sram_width*5]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA6),
		.QB		(QB6)
	);

	TSDN28HPMA16X72M4FW sram7 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*7-1:sram_width*6]),
		.DB		(din_b[sram_width*7-1:sram_width*6]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),
		
		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA7),
		.QB		(QB7)
	);

	TSDN28HPMA16X72M4FW sram8 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*8-1:sram_width*7]),
		.DB		(din_b[sram_width*8-1:sram_width*7]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA8),
		.QB		(QB8)
	);

	TSDN28HPMA16X72M4FW sram9 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*9-1:sram_width*8]),
		.DB		(din_b[sram_width*9-1:sram_width*8]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA9),
		.QB		(QB9)
	);

	TSDN28HPMA16X72M4FW sram10 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*10-1:sram_width*9]),
		.DB		(din_b[sram_width*10-1:sram_width*9]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA10),
		.QB		(QB10)
	);

	TSDN28HPMA16X72M4FW sram11 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*11-1:sram_width*10]),
		.DB		(din_b[sram_width*11-1:sram_width*10]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA11),
		.QB		(QB11)
	);

	TSDN28HPMA16X72M4FW sram12 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*12-1:sram_width*11]),
		.DB		(din_b[sram_width*12-1:sram_width*11]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA12),
		.QB		(QB12)
	);

	TSDN28HPMA16X72M4FW sram13 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[sram_width*13-1:sram_width*12]),
		.DB		(din_b[sram_width*13-1:sram_width*12]),

		.BWEBA	({sram_width{1'b0}}),
		.BWEBB	({sram_width{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA13),
		.QB		(QB13)
	);

	TSDN28HPMA16X64M4FW sram14 (
		.WTSEL	(2'b01),
		.RTSEL	(2'b01),
		.VG		(1'b1),
		.VS 	(1'b1),

		.AA		(AA),
		.AB		(AB),

		.DA 	(din_a[`HV_DIMENSION/2-1:sram_width*13]),
		.DB		(din_b[`HV_DIMENSION/2-1:sram_width*13]),

		.BWEBA	({sram_width64{1'b0}}),
		.BWEBB	({sram_width64{1'b0}}),
		.WEBA	(WEBA),
		.WEBB	(WEBB),

		.CEBA	(1'b0),
		.CEBB	(1'b0),

		.CLKA	(clk),
		.CLKB	(clk),

		.QA		(QA14),
		.QB		(QB14)
	);

endmodule : memory_wrapper