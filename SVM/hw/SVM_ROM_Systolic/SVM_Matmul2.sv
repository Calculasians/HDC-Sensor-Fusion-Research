`include "const.vh"

module SVM_Matmul2 #(
    parameter NBITS,
    parameter VSUP_WIDTH,
    parameter ASUP_WIDTH,
    parameter F_WIDTH,
    parameter LOG_F_WIDTH,
    parameter SUP_WIDTH,
    parameter LOG_SUP_WIDTH
) (
    input                                           clk,
    input                                           rst,

    input signed        [NBITS+LOG_F_WIDTH-1:0]     matmul1_result [0:SUP_WIDTH-1],
    
    input signed        [NBITS-1:0]                 v_alpha,
    input signed        [NBITS-1:0]                 a_alpha,
    
    input               [LOG_SUP_WIDTH-1:0]         comp_sidx_delay,

    input                                           v_alpha_valid,
    input                                           a_alpha_valid,

    output reg signed   [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result,

    output reg                                      matmul2_v_valid,
    output reg                                      matmul2_a_valid
);

    always @(posedge clk) begin
        if (rst) begin
            matmul2_result  <= 0;
        end else if (v_alpha_valid) begin
            matmul2_result  <= matmul2_result + (v_alpha * matmul1_result[comp_sidx_delay]);
        end else if (a_alpha_valid) begin
            matmul2_result  <= matmul2_result + (a_alpha * matmul1_result[comp_sidx_delay]);
        end else begin
            matmul2_result  <= 0;
        end
    end

    always @(posedge clk) begin
        matmul2_v_valid <= v_alpha_valid && (comp_sidx_delay == VSUP_WIDTH-1);
        matmul2_a_valid <= a_alpha_valid && (comp_sidx_delay == ASUP_WIDTH-1);
    end


endmodule : SVM_Matmul2
