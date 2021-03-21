module hv2000_binary_adder (
	input  		[1999:0]	hv,
	output reg 	[10:0] 		weight
);

	reg  [1:0]	weight_0	[999:0];
	reg  [2:0]	weight_1	[499:0];
	reg  [3:0]	weight_2	[249:0];
	reg  [4:0]	weight_3	[124:0];
	reg  [5:0]	weight_4	[62:0];
	reg  [6:0]	weight_5	[31:0];
	reg  [7:0]	weight_6	[15:0];
	reg  [8:0]	weight_7	[7:0];
	reg  [9:0]	weight_8	[3:0];
	reg  [10:0]	weight_9	[1:0];

	integer i;
	always @(*) begin
		for (i = 0; i < 1000; i = i + 1) weight_0[i] = hv[2*i]			+ hv[2*i+1];
		for (i = 0; i < 500	; i = i + 1) weight_1[i] = weight_0[2*i] 	+ weight_0[2*i+1];
		for (i = 0; i < 250	; i = i + 1) weight_2[i] = weight_1[2*i] 	+ weight_1[2*i+1];
		for (i = 0; i < 125	; i = i + 1) weight_3[i] = weight_2[2*i] 	+ weight_2[2*i+1];
		for (i = 0; i < 62	; i = i + 1) weight_4[i] = weight_3[2*i] 	+ weight_3[2*i+1];
		weight_4[62] = weight_3[124];
		for (i = 0; i < 31	; i = i + 1) weight_5[i] = weight_4[2*i] 	+ weight_4[2*i+1];
		weight_5[31] = weight_4[62];
		for (i = 0; i < 16	; i = i + 1) weight_6[i] = weight_5[2*i] 	+ weight_5[2*i+1];
		for (i = 0; i < 8	; i = i + 1) weight_7[i] = weight_6[2*i] 	+ weight_6[2*i+1];
		for (i = 0; i < 4	; i = i + 1) weight_8[i] = weight_7[2*i] 	+ weight_7[2*i+1];
		for (i = 0; i < 2	; i = i + 1) weight_9[i] = weight_8[2*i] 	+ weight_8[2*i+1];
		weight = weight_9[0] + weight_9[1];
	end

endmodule : hv2000_binary_adder