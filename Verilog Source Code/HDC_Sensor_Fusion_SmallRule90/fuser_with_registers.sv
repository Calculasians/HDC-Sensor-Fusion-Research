`include "const.vh"

module fuser (
	input							clk,
	input							rst,

	input							hvin_valid,
	output							hvin_ready,
	input		[`HV_DIMENSION-1:0]	hvin,

	output							hvout_valid,
	input							hvout_ready,
	output reg	[`HV_DIMENSION-1:0]	hvout
);

	//---------------------//
	// Registers and Wires //
	//---------------------//

	reg		[`NUM_MODALITY_WIDTH-1:0] counter;
	reg		[`NUM_MODALITY_WIDTH-1:0] accumulator [`HV_DIMENSION-1:0];

	wire	hvin_fire;
	wire	hvout_fire;

	//----------------------------------------------------------------------------------------------------//
	//----------------------------------------------------------------------------------------------------//

	assign hvin_fire	= hvin_valid && hvin_ready;
	assign hvin_ready	= counter < `NUM_MODALITY;

	assign hvout_fire	= hvout_valid && hvout_ready;
	assign hvout_valid	= counter == `NUM_MODALITY + 1;

	always @(posedge clk) begin
		if (rst || hvout_fire) begin
			counter <= 0;
		end
		else if (hvin_fire || counter == `NUM_MODALITY) begin
			counter <= counter + 1;
		end
	end

	integer i;
	always @(posedge clk) begin
		if (hvin_fire) begin
			if (counter == 0) begin
				for (i = 0; i < `HV_DIMENSION/2; i = i + 1) accumulator[i] <= {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};
				for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};
			end
			else begin
				for (i = 0; i < `HV_DIMENSION/2; i = i + 1) accumulator[i] <= accumulator[i] + {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};
				for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) accumulator[i] <= accumulator[i] + {{`NUM_MODALITY_WIDTH-1{1'b0}}, hvin[i]};
			end
		end
	end

	always @(posedge clk) begin
		if (counter == `NUM_MODALITY) begin
			for (i = 0; i < `HV_DIMENSION/2; i = i + 1)  hvout[i] <= (accumulator[i] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
			for (i = `HV_DIMENSION/2; i < `HV_DIMENSION; i = i + 1) hvout[i] <= (accumulator[i] > (`NUM_MODALITY >> 1)) ? 1'b1 : 1'b0;
		end
	end

endmodule : fuser