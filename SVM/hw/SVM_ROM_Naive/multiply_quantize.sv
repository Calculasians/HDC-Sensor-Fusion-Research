module multiply_quantize #(
    parameter NBITS,
    parameter NPARALLEL
) (
    input signed [NBITS-1:0]    ina [0:NPARALLEL-1],
    input signed [NBITS-1:0]    inb,
    output reg signed [NBITS-1:0]   vout [0:NPARALLEL-1]
);

    reg signed [2*NBITS-1:0] temp [0:NPARALLEL-1];

    integer p;
    always @(*) begin
        for (p = 0; p < NPARALLEL; p = p + 1) begin
            temp[p] = (ina[p] * inb) >> NBITS;
            vout[p] = temp[p][NBITS-1:0];
        end
    end

endmodule : multiply_quantize
