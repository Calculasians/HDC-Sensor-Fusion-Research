`include "const.vh"

module SVM_memory_wrapper #(
    parameter NBITS,
    parameter VSUP_WIDTH,
    parameter ASUP_WIDTH,
    parameter F_WIDTH,
    parameter SUP_WIDTH,
    parameter LOG_SUP_WIDTH,
    parameter LOG_MIDX,
	parameter ROM_DEPTH,
	parameter LOG_ROM_DEPTH,
    parameter ROM_WIDTH,   
    parameter ROM_TOTAL_WIDTH, 
    parameter VSUP_BASE_ADDR,     
    parameter VALPHA_BASE_ADDR,   
    parameter ASUP_BASE_ADDR,  
    parameter AALPHA_BASE_ADDR
) (
    input                                       clk,
    input                                       rst,

    input           [LOG_SUP_WIDTH-1:0]         comp_sidx,
    input           [LOG_MIDX-1:0]              midx,

    input                                       computing_v_matmul1,
    input                                       computing_v_matmul2,
    input                                       computing_a_matmul1,
    input                                       computing_a_matmul2,

    output signed   [NBITS*F_WIDTH-1:0]         v_support,
    output signed   [NBITS-1:0]                 v_alpha,
    output signed   [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept,

    output signed   [NBITS*F_WIDTH-1:0]         a_support,
    output signed   [NBITS-1:0]                 a_alpha,
    output signed   [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept
);

    wire        [LOG_ROM_DEPTH-1:0]         addr;
    wire        [LOG_ROM_DEPTH-1:0]         mem_read_addr;
    wire signed [ROM_TOTAL_WIDTH-1:0]	    mem_out;

    assign addr             = mem_read_addr;
    assign mem_read_addr    = (computing_v_matmul1) ? midx + VSUP_BASE_ADDR :
                              (computing_v_matmul2) ? comp_sidx + VALPHA_BASE_ADDR :
                              (computing_a_matmul1) ? midx + ASUP_BASE_ADDR :
                              (computing_a_matmul2) ? comp_sidx + AALPHA_BASE_ADDR : 0;
    assign v_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*F_WIDTH)];
    assign a_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*F_WIDTH)];
    assign v_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    assign a_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    // 
    assign v_intercept      = `V_INTERCEPT;
    assign a_intercept      = `A_INTERCEPT;

//-----------------------------------------//
//            SVM ROM Memories             //
//-----------------------------------------//

    // change this instantiation if using different RFE #features
    SVM_memories_214 #(
	    .NBITS              (NBITS),
	    .VSUP_WIDTH         (VSUP_WIDTH),
	    .ASUP_WIDTH         (ASUP_WIDTH),
	    .ROM_DEPTH          (ROM_DEPTH),
	    .LOG_ROM_DEPTH      (`ceilLog2(1024)),
	    .ROM_WIDTH          (ROM_WIDTH),
	    .ROM_TOTAL_WIDTH    (ROM_TOTAL_WIDTH)
    ) mem (
        .clk        (clk),
        .addr       (addr),
        .mem_out    (mem_out)
    );

endmodule : SVM_memory_wrapper
