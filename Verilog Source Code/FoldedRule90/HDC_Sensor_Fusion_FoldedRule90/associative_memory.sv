`include "const.vh"

module associative_memory #(
	parameter NUM_FOLDS, 
	parameter NUM_FOLDS_WIDTH, 
	parameter FOLD_WIDTH,

	parameter AM_NUM_FOLDS,
	parameter AM_NUM_FOLDS_WIDTH,
	parameter AM_FOLD_WIDTH
) (
	input						clk,
	input						rst,

	input						hvin_valid,
	output						hvin_ready,
	input	[FOLD_WIDTH-1:0]	hvin,

	output						dout_valid, 
	input						dout_ready,
	output reg					valence,
	output reg					arousal
);

	reg   	[AM_FOLD_WIDTH-1:0]			similarity_hv; 
	reg  	[`DISTANCE_WIDTH-1:0]		distance_vp;
	reg  	[`DISTANCE_WIDTH-1:0]		distance_vn; 
	reg  	[`DISTANCE_WIDTH-1:0]		distance_ap;
	reg  	[`DISTANCE_WIDTH-1:0]		distance_an;
	wire  	[`DISTANCE_WIDTH-1:0]		distance;

	reg 	[NUM_FOLDS_WIDTH-1:0] 		fold_counter; 
	reg 	[AM_NUM_FOLDS_WIDTH-1:0]	am_fold_counter;

	reg 	[2:0]						curr_state;
	localparam IDLE				= 3'b000;
	localparam PROCESS_V_PLUS	= 3'b001;
	localparam PROCESS_V_MIN	= 3'b010;
	localparam PROCESS_A_HIGH	= 3'b011;
	localparam PROCESS_A_LOW	= 3'b100;
	localparam WAIT_NEXT_FOLD	= 3'b101;
	localparam OUTPUT_VALID		= 3'b110;
  
	wire 	hvin_fire; 
	wire  	dout_fire;

	// // NUM_FOLDS 1
	// localparam PROTOTYPE_V_PLUS =   2000'b00111011010010110000110101010010010100111110111001110100011000101111000111101010100111101010010010001111110001011110100001100100010100010111111100100100010100011101011100000000111011011011010101001010000100111100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001110001111000101100111111001111011001010111010011111010100000010110110010111010001000001100000100111011010111110001100110010101011110101100001111101011110011100011100100001101111000111111101100000001101110010111011110001110001001100100111001000101011101110010110111110010100001011011101101101010100101000100110001010000101011111111101010011010101011100001111000010100011010111110000101010000000100010101110110100011011010011001001000100011011111000110111001001100100001111000110111011110011010011100111000111110000001010001110001000110011000011011111100000010001110110010101011010101000000101010001011101001100110000010010111100010000111110101010001011000010101001111001110100000100101100101100010011010001111001001100101010100000110101101100010000111110100000011101100000011100101101100010101100101001101100001101000010010011011010001010011000100100110010100000111100100101111001000001011011001101010010001011011110111001101001010001000000111111110110100011011001001111010101110010101101000011100011110111111010010101101001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101110001111011001010111001010110010000111001111001010000011011010111110000000001101101001100001010100100000001100011001100101001001011000100000010100011000010111111010001100111111000110100001000011010000100101010011001101000011010110000001001010101001111100000111001000001110000000000110111011011011100101100001000000000001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010100100111100000101100000000110101010110010101010110110000011011111110110110110010000101010010100110000101011010010111101111101000000000;
	// localparam PROTOTYPE_V_MIN  =   2000'b00111011010001110000110100100010010100011110111000010100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010101111101011100000000000011011011010101001010000100010100011110110000000101110100010010000111001111110011011100110000110101001101010011111011010100110110100001110111011100110001001011111000101100111111001111011001010001010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000101001110010111011110001110001001111100011000110101011101110010110111010010100111011000001101101001000100101000110001010101011010111000101010011010101011100001111000010100011010111110000101011100010100101101110110100011011010011001001000101101011111000110100010101100100001100000110111011110000000011100111000111110000001010001110001000110011000011011111100000010010010110010101011010110101010110110001011101001100110000000010111100010000111110101110001011000001001001111110110100000100101100101100010011010001111001001100101010100000110101101100010000000110100010011001100000000000101101100010101100101110101100001101000010010011011010001010010001010011110010100000111100100101111001000001101011001101010010000011011100111001010001010001000000111111010110000011110001001111011011110010101101000011100011110111110100010101101001111001101101001100011110001011001110011010101111011100101010111011001011101001000101100000001111011001010111001001101010000111001110111011110011011010111110000000001101101001100001101100100110001100011001100101001011011000100000010010011000010111111010001100111111000110100001000011010010100101010011001101000011011100000001001010101001111000000111001000101110000110001110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101111110110000101000000010000111010000010000100111100000101100000001000101010110010101010110110000011010001110110110101010000101010010101000000101011010010111101111101011110001;
	// localparam PROTOTYPE_A_HIGH =   2000'b00111011010010101000110100100010010110011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010100011101011100000000111011011011010101001010000100011100011110110000000101110100010010000111001101110011011100110000110001001101010011111011110100110101000001110111011100110001001101111000101100111111000001011001011111010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000001101110010111011110001110010101100111111001000101011101110010110111000010100110011000001101101010100101011000110001010101011000111000101010011001001011100001111000010100011010111110000101101100000100101101110110100011011010011001001000101101011000000110100001001100100101001000110111000010101010011100111000111100000001010001110001000110011000011011111100010110001110110010101011010110101000101010001011101001100110000010010111100010000111110001010001011001100101001111001110100000100101100101100010011010001111001001100101010000000110101101100010000000110100001100001100000011100101101100010101100101110001100001101000011010011011010001010011001100111110010100000111100100101111001000001101011001101010010000011011101011001010001010001000000111111010110011011011001001111011101110010101101000011100011110111110010010101101001111001101101001100011101101011001110011010100001011100101010111011011011101001000101101110011111011001010111001001001010000111001111011010000011011010111110000000001101101001100001010100100110001100011001100101001011011000100000010100011000010111111010001100111111000110100101000011010010100101010011001101000011101110000001001010101001111000000111001000001010001000000110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101110110110000101000000010000111010000010100100111100000101100000001010110110110010101010110110000011010001110110110001010000101010010100110000101011010010111101111101011110000;
	// localparam PROTOTYPE_A_LOW  =   2000'b00111011010001110000110100100010010100011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100110100010101101101011100000000000011011011010101001010000100001100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001100101111000101100111111001111011001010111010011111010100000010110110010111010001000001111000000111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000011101110010111011110001110001001111100111001000101011101110010110111000010100001011001001101101010100101001000110001011110101010111111101010011010101011100001111000010100011010111110000101001100010100010101110110100011011010011001001000100011011111000110111001001100100001110000110111011110011010011100111000111110000001010001110001000110011000011011111100000010000110110010101011010110100110110110001011101001100110000010010111100010000111110101110001011000010101001111000110100000100101100101100010011010001111001001100101010000000110101101100010000000110100010011101100000000000101101100010101100101101101100001101000010010011011010001010010001010000110010100000111100100101111001000001011011001101010010000011011110111001101001010001000000111111010110100011011111001111011101110010101101000011100011110111111010010101011001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101101101111011001010111001010110010000111001111011011110011011010111110000000001101101001100001010100100110001100011001100101001011011000100000011010011000010111111010001100111111000110100010100011010010100101010011001101000011010110000001001010101001111100000111001000101110000110001110111011011011100101100001000000001001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010000100111100000101100000000100101010110010101010110110000011101001110110110001010000101010010101110000101011010010111101111101000001001;
	// // NUM_FOLDS 2
	// localparam PROTOTYPE_V_PLUS =   2000'b00111011010010110000110101010010010100111110111001110100011000101111000111101010100111101010010010001111110001011110100001100100010100010111111100100100010100011101011100000000111011011011010101001010000100111100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001110001111000101100111111001111011001010111010011111010100000010110110010111010001000001100000100111011010111110001100110010101011110101100001111101011110011100011100100001101111000111111101100000001101110010111011110001110001001100100111001000101011101110010110111110010100001011011101101101010100101000100110001010000101011111111101010011010101011100001111000010100011010111110000101010000000100010101110110100011011010011001001000100011011111000110111001001100100001111000110111011110011010011100111000111110000001010001110001000110011000011011111100000010001110110010101011010101001000110110110011101000000101110010010111100110101010010011111000001100111000100110111110111100010011100110111100101010001100101001110111001110011011101101100010000111110100010001110000000011100101101100010101100101001101100001101000010010011011010001010011000100100110010100000111100100101111001000001011011001101010010001011011110111001101001010001000000111111110110100011011001001111010101110010101101000011100011110111111010010101101001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101110001111011001010111001010110010000111001111001010000011011010111110000000001101101001100001010100100000001100011001100101001001011000100000010100011000010111111010001100111111000110100001000011010000100101010011001101000011010110000001001010101001111100000111001000001110000000000110111011011011100101100001000000000001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010100100111100000101100000000110101010110010101010110110000011011111110110110110010000101010010100110000101011010010111101111101000000000;
	// localparam PROTOTYPE_V_MIN  =   2000'b00111011010001110000110100100010010100011110111000010100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010101111101011100000000000011011011010101001010000100010100011110110000000101110100010010000111001111110011011100110000110101001101010011111011010100110110100001110111011100110001001011111000101100111111001111011001010001010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000101001110010111011110001110001001111100011000110101011101110010110111010010100111011000001101101001000100101000110001010101011010111000101010011010101011100001111000010100011010111110000101011100010100101101110110100011011010011001001000101101011111000110100010101100100001100000110111011110000000011100111000111110000001010001110001000110011000011011111100000010010010110010101011010110101000110110110011101000000101110010010111100001101010011001111000001100111000100110111000111000010101111110111100101010001101001001101111010111100011101101100001100000110100010011110000000000000101101100010101100101110101100001101000010010011011010001010010001010011110010100000111100100101111001000001101011001101010010000011011100111001010001010001000000111111010110000011110001001111011011110010101101000011100011110111110100010101101001111001101101001100011110001011001110011010101111011100101010111011001011101001000101100000001111011001010111001001101010000111001110111011110011011010111110000000001101101001100001101100100110001100011001100101001011011000100000010010011000010111111010001100111111000110100001000011010010100101010011001101000011011100000001001010101001111000000111001000101110000110001110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101111110110000101000000010000111010000010000100111100000101100000001000101010110010101010110110000011010001110110110101010000101010010101000000101011010010111101111101011110001;
	// localparam PROTOTYPE_A_HIGH =   2000'b00111011010010101000110100100010010110011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010100011101011100000000111011011011010101001010000100011100011110110000000101110100010010000111001101110011011100110000110001001101010011111011110100110101000001110111011100110001001101111000101100111111000001011001011111010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000001101110010111011110001110010101100111111001000101011101110010110111000010100110011000001101101010100101011000110001010101011000111000101010011001001011100001111000010100011010111110000101101100000100101101110110100011011010011001001000101101011000000110100001001100100101001000110111000010101010011100111000111100000001010001110001000110011000011011111100010110001110110010101011010110101000110110110011101000000101110010010111100001101010011101111000001100111000100110111000110000010011011110111100101010001100101001110111110111011111101101100001100000110100010011110000000011100101101100010101100101110001100001101000011010011011010001010011001100111110010100000111100100101111001000001101011001101010010000011011101011001010001010001000000111111010110011011011001001111011101110010101101000011100011110111110010010101101001111001101101001100011101101011001110011010100001011100101010111011011011101001000101101110011111011001010111001001001010000111001111011010000011011010111110000000001101101001100001010100100110001100011001100101001011011000100000010100011000010111111010001100111111000110100101000011010010100101010011001101000011101110000001001010101001111000000111001000001010001000000110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101110110110000101000000010000111010000010100100111100000101100000001010110110110010101010110110000011010001110110110001010000101010010100110000101011010010111101111101011110000;
	// localparam PROTOTYPE_A_LOW  =   2000'b00111011010001110000110100100010010100011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100110100010101101101011100000000000011011011010101001010000100001100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001100101111000101100111111001111011001010111010011111010100000010110110010111010001000001111000000111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000011101110010111011110001110001001111100111001000101011101110010110111000010100001011001001101101010100101001000110001011110101010111111101010011010101011100001111000010100011010111110000101001100010100010101110110100011011010011001001000100011011111000110111001001100100001110000110111011110011010011100111000111110000001010001110001000110011000011011111100000010000110110010101011010110101000110110110011101000000101110010010111100001101010010011111000001100111000100110110000111100010101100110111100101010001100101001110111101111101011101101100010000000110100010000010000000000000101101100010101100101101101100001101000010010011011010001010010001010000110010100000111100100101111001000001011011001101010010000011011110111001101001010001000000111111010110100011011111001111011101110010101101000011100011110111111010010101011001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101101101111011001010111001010110010000111001111011011110011011010111110000000001101101001100001010100100110001100011001100101001011011000100000011010011000010111111010001100111111000110100010100011010010100101010011001101000011010110000001001010101001111100000111001000101110000110001110111011011011100101100001000000001001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010000100111100000101100000000100101010110010101010110110000011101001110110110001010000101010010101110000101011010010111101111101000001001;
	// // NUM_FOLDS 4
	localparam PROTOTYPE_V_PLUS =   2000'b00111011010010110000110101010010010100111110111001110100011000101111000111101010100111101010010010001111110001011110100001100100010100010111111100100100010100011101011100000000111011011011010101001010000100111100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001110001111000101100111111001111011001010111010011111010100000010110001010111010100100000010000101100100001111101101110110011001011110101101000001100000100100101100101001001001001000110100110101110000101001100011000100001001001110111000100101100001010011110010110111010010100001011011101101101010100101000100110001010000101011111111101010011010101011100001111000010100011010111110000101010000000100010101110110100011011010011001001000100011011111000110111001001100100001111000110111011110011010011100111000111110000001010001110001000110011000011011111100000010001110110010101011010101001000110110110011101000000101110010010111100110101010010011111000001100111000100110111110111100010011100110111100101010001100101001110111001110011011101101100010000111110100010001110000000011100101101100010101100101001101100001101000010010011011010001010011000100100110010100000111100100101111001000001011011001101010010001011011110111001101001010001000000111111110110100011011001001111010101110010101101000011100011110111111010010101101001111001101101001100011101101011001110011010101111011100101001011010111000010101001100011001100111011110011001011110010100010111111101010011110101011010011101010100000100100110010011001100010001111100001011100011001100011111010000011010011011110111111010001100111111000110100001000011010000100101010011001101000011010110000001001010101001111100000111001000001110000000000110111011011011100101100001000000000001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010100100111100000101100000000110101010110010101010110110000011011111110110110110010000101010010100110000101011010010111101111101000000000;
	localparam PROTOTYPE_V_MIN  =   2000'b00111011010001110000110100100010010100011110111000010100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010101111101011100000000000011011011010101001010000100010100011110110000000101110100010010000111001111110011011100110000110101001101010011111011010100110110100001110111011100110001001011111000101100111111001111011001010001010011111010100000010001110010111010110100010101000101100100001111101101110110011001011110101101001111010000100100101100101001011111001100110100110101110011001001110011000100001001001110111000000100010101010011110010110111001010100111011000001101101001000100101000110001010101011010111000101010011010101011100001111000010100011010111110000101011100010100101101110110100011011010011001001000101101011111000110100010101100100001100000110111011110000000011100111000111110000001010001110001000110011000011011111100000010010010110010101011010110101000110110110011101000000101110010010111100001101010011001111000001100111000100110111000111000010101111110111100101010001101001001101111010111100011101101100001100000110100010011110000000000000101101100010101100101110101100001101000010010011011010001010010001010011110010100000111100100101111001000001101011001101010010000011011100111001010001010001000000111111010110000011110001001111011011110010101101000011100011110111110100010101101001111001101101001100011110001011001110011010101111011100101000111010111000000101001100011011101111011110011001011110010100101111111101010011110101011010011101011010000100100110010011001100010001111100001011100101001000001000100000011010011011110111111010001100111111000110100001000011010010100101010011001101000011011100000001001010101001111000000111001000101110000110001110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101111110110000101000000010000111010000010000100111100000101100000001000101010110010101010110110000011010001110110110101010000101010010101000000101011010010111101111101011110001;
	localparam PROTOTYPE_A_HIGH =   2000'b00111011010010101000110100100010010110011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010100011101011100000000111011011011010101001010000100011100011110110000000101110100010010000111001101110011011100110000110001001101010011111011110100110101000001110111011100110001001101111000101100111111000001011001011111010011111010100000010001110010111011100100010011000101100100101110101101110110011001011110101001000001000011010100101100101001010111001000110100110101110011001001110011000100001001001110111000001101100101010011110010110111010010100110011000001101101010100101011000110001010101011000111000101010011001001011100001111000010100011010111110000101101100000100101101110110100011011010011001001000101101011000000110100001001100100101001000110111000010101010011100111000111100000001010001110001000110011000011011111100010110001110110010101011010110101000110110110011101000000101110010010111100001101010011101111000001100111000100110111000110000010011011110111100101010001100101001110111110111011111101101100001100000110100010011110000000011100101101100010101100101110001100001101000011010011011010001010011001100111110010100000111100100101111001000001101011001101010010000011011101011001010001010001000000111111010110011011011001001111011101110010101101000011100011110111110010010101101001111001101101001100011101101011001110011010101111011100101010111010111000010101001100011011101111011110011001011110110100010111111101010011110101011010011101011000000100100110010011001100010001111100001011100101001011011111011000011010011011110111111010001100111111000110100101000011010010100101010011001101000011101110000001001010101001111000000111001000001010001000000110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101110110110000101000000010000111010000010100100111100000101100000001010110110110010101010110110000011010001110110110001010000101010010100110000101011010010111101111101011110000;
	localparam PROTOTYPE_A_LOW  =   2000'b00111011010001110000110100100010010100011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100110100010101101101011100000000000011011011010101001010000100001100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001100101111000101100111111001111011001010111010011111010100000010110001010111010110100010011000101100111001111101101110110011001011110101001001111100000100100101100101001011111001100110100110101110000101001110011000100001001001110111000100101100101010011110010110111010010100001011001001101101010100101001000110001011110101010111111101010011010101011100001111000010100011010111110000101001100010100010101110110100011011010011001001000100011011111000110111001001100100001110000110111011110011010011100111000111110000001010001110001000110011000011011111100000010000110110010101011010110101000110110110011101000000101110010010111100001101010010011111000001100111000100110110000111100010101100110111100101010001100101001110111101111101011101101100010000000110100010000010000000000000101101100010101100101101101100001101000010010011011010001010010001010000110010100000111100100101111001000001011011001101010010000011011110111001101001010001000000111111010110100011011111001111011101110010101101000011100011110111111010010101011001111001101101001100011101101011001110011010101111011100101001011010111000010101001100011011100111011110101001011110010100010111111101010011110101011010011101011110000110100110010011001100010001111100001011100101001100011000100000011010011011110111111010001100111111000110100010100011010010100101010011001101000011010110000001001010101001111100000111001000101110000110001110111011011011100101100001000000001001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010000100111100000101100000000100101010110010101010110110000011101001110110110001010000101010010101110000101011010010111101111101000001001;
	// NUM_FOLDS 8	
	// localparam PROTOTYPE_V_PLUS =   2000'b00111011010010110000110101010010010100111110111001110100011000101111000111101010100111101010010010001111110001011110100001100100010100010111111100100011001111001101011100011000111011011011010110010010000100100011111000110101100010001100101000110100011101111001000000000111101101011111010001100111111010110100101101110111100100110001000011111000101101001111001111011001010111010011111010100000010110001010111010100100000010000101100100001111101101110110011001011110101101000001100000100100101100101001001001001000110100110101110000101001100011000100001001001110111000100101100001010011110010110111010010100001011011101101101010100101000100110001011101101100111111101000001010101011100001111001100100111001111110111101101001111111110110011101100111000111100111010011110100001101010110011000110101011001100001110101010010100010011100111010101110000001010001110001000110011000011011111100000010001110110010101011010101001000110110110011101000000101110010010111100110101010010011111000001100111000100110111110111100010011100110111100101010001100101001110111001110011011101101100010000111110100010001110000000011100101101100010101100101001101100001101000010010001011010001010101000011100110010111111011100110110001101100101100110010110110001010000001010100100011001101101101100110011101011000100010111110111001110110010100100011111100011101010000011010101101001111001101101001100011101101011001110011010101111011100101001011010111000010101001100011001100111011110011001011110010100010111111101010011110101011010011101010100000100100110010011001100010001111100001011100011001100011111010000011010011011110111111010001100111111000110100001000011010000100101010011001101000011010110011010000100101001111000011100011010110110000000111000010010001001110001000011100111100110100010011110100011100101000101001011100000110100101101010110110011110110000101000000000000111010000010100100111100000101100000000110101010110010101010110110000011011111110110110110010000101010010100110000101011010010111101111101000000000;
	// localparam PROTOTYPE_V_MIN  =   2000'b00111011010001110000110100100010010100011110111000010100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000011001110101101011100011000000011011011010110010001100100100011111000110101100010001100100000111000011101111001000000000111101101011111010001101011011010110100101101110111100100110001110111111000101101001111001111011001010001010011111010100000010001110010111010110100010101000101100100001111101101110110011001011110101101001111010000100100101100101001011111001100110100110101110011001001110011000100001001001110111000000100010101010011110010110111001010100111011000001101101001000100101000110001011101011100111000101000001010001011100001111001100100000001111110111100001001111111010010011100000111000111111011010011010100001101010110001000110101011001000001110101001110100000011100111010101110000001010001110001000110011000011011111100000010010010110010101011010110101000110110110011101000000101110010010111100001101010011001111000001100111000100110111000111000010101111110111100101010001101001001101111010111100011101101100001100000110100010011110000000000000101101100010101100101110101100001101000010010011011010001010101000011100110010111111011100110110001101011101100110010110110001010000001010100100011001101101101100110011101010000100010111110111000000110010100100011111100011101010000011010101101001111001101101001100011110001011001110011010101111011100101000111010111000000101001100011011101111011110011001011110010100101111111101010011110101011010011101011010000100100110010011001100010001111100001011100101001000001000100000011010011011110111111010001100111111000110100001000011010010100101010011001101000011011100011101000100101001111000011111111010110110000110111000010010001001111001000011100111100110100010010100100111100101000101001011100000110100101101010110110011110110000101000000010000111010000010000100111100000101100000001000101010110010101010110110000011010001110110110101010000101010010101000000101011010010111101111101011110001;
	// localparam PROTOTYPE_A_HIGH =   2000'b00111011010010101000110100100010010110011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000011001111011101011100011100111011011011010110010001100100100011111000110101100010001100101100111000011101111001000000000111101101011111010001101011111010110100101101110111100100110001001111111000101101001111000001011001011111010011111010100000010001110010111011100100010011000101100100101110101101110110011001011110101001000001000011010100101100101001010111001000110100110101110011001001110011000100001001001110111000001101100101010011110010110111010010100110011000001101101010100101011000110001011101011100111000101000001001001011100001111001100100110001111110111101111001111111110110011100000111000111111011010011000100001101010110000000110101011001000001110101001110100010011100111010101100000001010001110001000110011000011011111100010110001110110010101011010110101000110110110011101000000101110010010111100001101010011101111000001100111000100110111000110000010011011110111100101010001100101001110111110111011111101101100001100000110100010011110000000011100101101100010101100101110001100001101000011010011011010101010100000011100110010111111011100110110001101011101100110010110110001010000001010100100011001101101101100110011101010000100011111110111010000110010100100011111100011101010000011010101101001111001101101001100011101101011001110011010101111011100101010111010111000010101001100011011101111011110011001011110110100010111111101010011110101011010011101011000000100100110010011001100010001111100001011100101001011011111011000011010011011110111111010001100111111000110100101000011010010100101010011001101000011101110011010000100101001111000011100011010110110001000111000010010001001110111000011100111100110100010011100110111100101000101001011100000110100101101010110110011110110000101000000010000111010000010100100111100000101100000001010110110110010101010110110000011010001110110110001010000101010010100110000101011010010111101111101011110000;
	// localparam PROTOTYPE_A_LOW  =   2000'b00111011010001110000110100100010010100011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100110011001110101101011100011011000011011011001010010010000100100011111000110101100010001100101000100100011101111001000000000111101101011111010001101001011010110100101101110111100100110001101011111000100101001111001111011001010111010011111010100000010110001010111010110100010011000101100111001111101101110110011001011110101001001111100000100100101100101001011111001100110100110101110000101001110011000100001001001110111000100101100101010011110010110111010010100001011001001101101010100101001000110001011100101100111111101000001010101011100001111001100100110001111110111101111001111111010110011101100111000111100111010011110100001101010110011000110101011001101001110101010010100010011100111010101110000001010001110001000110011000011011111100000010000110110010101011010110101000110110110011101000000101110010010111100001101010010011111000001100111000100110110000111100010101100110111100101010001100101001110111101111101011101101100010000000110100010000010000000000000101101100010101100101101101100001101000010010011011010001010101001011100110010111111011100110110001101011101100110010110110001010000001010100100011001101101101100110011101010000100010111110111001110110010100100011111100011101010000011010101011001111001101101001100011101101011001110011010101111011100101001011010111000010101001100011011100111011110101001011110010100010111111101010011110101011010011101011110000110100110010011001100010001111100001011100101001100011000100000011010011011110111111010001100111111000110100010100011010010100101010011001101000011010110011101000100101001100000011101111010110110000110111000010010001001111001000011100111100110100010110101000111100101000101001011100000110100101101010110110011110110000101000000010000111010000010000100111100000101100000000100101010110010101010110110000011101001110110110001010000101010010101110000101011010010111101111101000001001;

	always @(posedge clk) begin
		if (rst) begin
			curr_state		<= IDLE;
			am_fold_counter	<= 0;
			fold_counter	<= NUM_FOLDS-1;
		end

		case (curr_state)
			IDLE: begin
				if (hvin_fire) begin
					curr_state		<= PROCESS_V_PLUS;
					am_fold_counter	<= 0;
					fold_counter	<= NUM_FOLDS-1;
				end
			end

			PROCESS_V_PLUS: begin
				if (am_fold_counter == AM_NUM_FOLDS-1) begin
					curr_state		<= PROCESS_V_MIN;
					am_fold_counter	<= 0;
				end else begin
					am_fold_counter	<= am_fold_counter + 1;
				end
			end

			PROCESS_V_MIN: begin
				if (am_fold_counter == AM_NUM_FOLDS-1) begin
					curr_state		<= PROCESS_A_HIGH;
					am_fold_counter	<= 0;
				end else begin
					am_fold_counter	<= am_fold_counter + 1;
				end
			end

			PROCESS_A_HIGH: begin
				if (am_fold_counter == AM_NUM_FOLDS-1) begin
					curr_state		<= PROCESS_A_LOW;
					am_fold_counter	<= 0;
				end else begin
					am_fold_counter	<= am_fold_counter + 1;
				end
			end

			PROCESS_A_LOW: begin
				if (am_fold_counter == AM_NUM_FOLDS-1) begin
					if (fold_counter == 0) begin
						curr_state		<= OUTPUT_VALID;
						am_fold_counter	<= 0;
						fold_counter	<= NUM_FOLDS-1;
					end else begin
						curr_state		<= WAIT_NEXT_FOLD;
						am_fold_counter	<= 0;
						fold_counter	<= fold_counter - 1;
					end
				end else begin
					am_fold_counter	<= am_fold_counter + 1;
				end
			end

			WAIT_NEXT_FOLD: begin
				if (hvin_fire) begin
					curr_state	<= PROCESS_V_PLUS;
				end
			end

			OUTPUT_VALID: begin
				if (dout_fire) begin
					curr_state	<= IDLE;
				end
			end

		endcase
	end

	assign hvin_fire 	= hvin_valid && hvin_ready;
	assign hvin_ready 	= (curr_state == IDLE) || (curr_state == WAIT_NEXT_FOLD);

	assign dout_fire	= dout_valid && dout_ready;
	assign dout_valid 	= (curr_state == OUTPUT_VALID);

	hv_binary_adder #(
		.NUM_FOLDS			(AM_NUM_FOLDS),
		.NUM_FOLDS_WIDTH	(AM_NUM_FOLDS_WIDTH),
		.FOLD_WIDTH			(AM_FOLD_WIDTH)
    ) BIN_ADDER (
		.hv			(similarity_hv),
		.distance	(distance)
	);

	always @(*) begin
		if (curr_state == PROCESS_V_PLUS) begin
			similarity_hv = hvin[(am_fold_counter * AM_FOLD_WIDTH) +: AM_FOLD_WIDTH] ^ PROTOTYPE_V_PLUS[((fold_counter * FOLD_WIDTH) + (am_fold_counter * AM_FOLD_WIDTH)) +: AM_FOLD_WIDTH];
		end
		else if (curr_state == PROCESS_V_MIN) begin
			similarity_hv = hvin[(am_fold_counter * AM_FOLD_WIDTH) +: AM_FOLD_WIDTH] ^ PROTOTYPE_V_MIN[((fold_counter * FOLD_WIDTH) + (am_fold_counter * AM_FOLD_WIDTH)) +: AM_FOLD_WIDTH];
		end
		else if (curr_state == PROCESS_A_HIGH) begin
			similarity_hv = hvin[(am_fold_counter * AM_FOLD_WIDTH) +: AM_FOLD_WIDTH] ^ PROTOTYPE_A_HIGH[((fold_counter * FOLD_WIDTH) + (am_fold_counter * AM_FOLD_WIDTH)) +: AM_FOLD_WIDTH];
		end
		else if (curr_state == PROCESS_A_LOW) begin
			similarity_hv = hvin[(am_fold_counter * AM_FOLD_WIDTH) +: AM_FOLD_WIDTH] ^ PROTOTYPE_A_LOW[((fold_counter * FOLD_WIDTH) + (am_fold_counter * AM_FOLD_WIDTH)) +: AM_FOLD_WIDTH];
		end
	end

	always @(posedge clk) begin
		if (curr_state == PROCESS_V_PLUS) begin
			if (fold_counter == NUM_FOLDS-1 && am_fold_counter == 0)
				distance_vp	<= distance;
			else 
				distance_vp <= distance_vp + distance;
		end

		if (curr_state == PROCESS_V_MIN) begin
			if (fold_counter == NUM_FOLDS-1 && am_fold_counter == 0)
				distance_vn	<= distance;
			else 
				distance_vn <= distance_vn + distance;
		end

		if (curr_state == PROCESS_A_HIGH) begin
			if (fold_counter == NUM_FOLDS-1 && am_fold_counter == 0)
				distance_ap	<= distance;
			else 
				distance_ap <= distance_ap + distance;
		end

		if (curr_state == PROCESS_A_LOW) begin
			if (fold_counter == NUM_FOLDS-1 && am_fold_counter == 0)
				distance_an	<= distance;
			else 
				distance_an <= distance_an + distance;
		end
	end

	always @(posedge clk) begin
		if (curr_state == PROCESS_A_LOW && fold_counter == 0 && am_fold_counter == AM_NUM_FOLDS-1) begin
			valence <= distance_vp >= distance_vn;
			arousal	<= distance_ap >= (distance_an + distance); // last cycle of PROCESS_A_LOW gives us the last "distance"
		end
	end

endmodule : associative_memory
