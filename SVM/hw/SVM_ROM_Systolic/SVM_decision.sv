`include "const.vh"

module SVM_decision #(
    parameter NBITS,
    parameter F_WIDTH,
    parameter LOG_F_WIDTH,
    parameter SUP_WIDTH,
    parameter LOG_SUP_WIDTH
) (
    input                                       clk,
    input                                       rst,

    input signed    [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result,
    input                                       matmul2_v_valid,
    input                                       matmul2_a_valid,

    input signed    [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept,
    input signed    [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept,
    
    output                                      dout_fire,
    input                                       dout_ready,
    output reg                                  dout_valid,
    output reg                                  valence,
    output reg                                  arousal
);

    wire dout_fire;

    assign dout_fire = dout_valid && dout_ready;

    always @(posedge clk) begin
        dout_valid  <= matmul2_a_valid;
    end
    // outside is always dout_ready

    always @(posedge clk) begin
        if (matmul2_v_valid) begin
            valence <= (matmul2_result > -v_intercept);
        end

        if (matmul2_a_valid) begin
            arousal <= (matmul2_result > -a_intercept);
        end
    end

endmodule : SVM_decision
