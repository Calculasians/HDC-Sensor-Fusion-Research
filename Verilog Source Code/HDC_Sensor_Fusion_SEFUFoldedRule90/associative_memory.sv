`include "const.vh"

module associative_memory (
	input						clk,
	input						rst,

	input						hvin_valid,
	output						hvin_ready,
	input	[`HV_DIMENSION-1:0]	hvin,

	output						dout_valid,
	input						dout_ready,
	output reg					valence,
	output reg					arousal
);

	//---------------------//
	// Registers and Wires //
	//---------------------//

	reg		[2:0]					counter;
	reg		[`HV_DIMENSION-1:0]		hvin_stored;
	reg		[`DISTANCE_WIDTH-1:0]	distance_pos;

	wire	hvin_fire;
	wire 	dout_fire;

	//-----------------//
	// Internal Module //
	//-----------------//

	reg		[`HV_DIMENSION-1:0]		similarity_hv;
	wire	[`DISTANCE_WIDTH-1:0]	distance;

	hv2000_binary_adder BIN_ADDER (
		.hv		(similarity_hv),
		.weight	(distance)
	);

	//----------------------------------------------------------------------------------------------------//
	//----------------------------------------------------------------------------------------------------//

	assign hvin_fire	= hvin_valid && hvin_ready;
	assign hvin_ready	= counter == 0;

	assign dout_fire	= dout_valid && dout_ready;
	assign dout_valid	= counter == 4;

	always @(posedge clk) begin
		if (rst || dout_fire) begin
			counter <= 0;
		end
		else if (hvin_fire || (counter > 0 && counter < 4)) begin
			counter <= counter + 1;
		end
	end

	always @(posedge clk) begin
		if (hvin_fire) begin
			hvin_stored <= hvin;
		end
	end

	always @(*) begin
		if (hvin_fire) begin
			similarity_hv = hvin ^ `PROTOTYPE_V_PLUS;
		end
		else if (counter == 1) begin
			similarity_hv = hvin_stored ^ `PROTOTYPE_V_MIN;
		end
		else if (counter == 2) begin
			similarity_hv = hvin_stored ^ `PROTOTYPE_A_HIGH;
		end
		else if (counter == 3) begin
			similarity_hv = hvin_stored ^ `PROTOTYPE_A_LOW;
		end
	end

	always @(posedge clk) begin
		if (counter == 0 || counter == 2) begin
			distance_pos <= distance;
		end
	end

	always @(posedge clk) begin
		if (counter == 1) begin
			valence <= distance_pos >= distance;
		end
		
		if (counter == 3) begin
			arousal <= distance_pos >= distance;
		end
	end

endmodule : associative_memory