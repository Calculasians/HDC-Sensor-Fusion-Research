`include "const.vh"
 
module SVM #(
	parameter NBITS = 9,                                // #bits for quantization, 5 -> [-16:15]

	parameter VSUP_WIDTH = 120,                         // width of v support vector
    parameter LOG_VSUP_WIDTH = `ceilLog2(VSUP_WIDTH),   // `ceilLog2(VSUP_WIDTH)
    // VSUP_WIDTH = VALPHA_WIDTH

    parameter ASUP_WIDTH = 155,                         // width of a support vector
    parameter LOG_ASUP_WIDTH = `ceilLog2(ASUP_WIDTH),   // `ceilLog2(ASUP_WIDTH)
    // ASUP_WIDTH = AALPHA_WIDTH

    parameter F_WIDTH = 214,                            // how many features RFE selected
    parameter LOG_F_WIDTH = `ceilLog2(F_WIDTH),         // `ceilLog2(F_WIDTH)

    parameter SUP_WIDTH = (ASUP_WIDTH > VSUP_WIDTH) ? ASUP_WIDTH : VSUP_WIDTH,
    parameter LOG_SUP_WIDTH = (LOG_ASUP_WIDTH > LOG_VSUP_WIDTH) ? LOG_ASUP_WIDTH : LOG_VSUP_WIDTH,

    parameter V_NPARALLEL = 120,                              // how many v_supports to process in parallel, must be divisible by VSUP_WIDTH
    parameter A_NPARALLEL = 155                             // how many a_supports to process in parallel, must be divisible by ASUP_WIDTH
) (
    input                           clk,
    input                           rst,

    input signed    [NBITS*VSUP_WIDTH-1:0]      v_in_support,
    input signed    [NBITS-1:0]                 v_in_alpha,
    input signed    [2*NBITS+LOG_SUP_WIDTH-1:0] v_in_intercept,

    input signed    [NBITS*ASUP_WIDTH-1:0]      a_in_support,
    input signed    [NBITS-1:0]                 a_in_alpha,
    input signed    [2*NBITS+LOG_SUP_WIDTH-1:0] a_in_intercept,

    input           [7:0]           mem_write_addr,
    input                           mem_we,
    output                          mem_write_ready,
    input                           mem_write_done,
    input                           intercept_valid,

    input signed    [NBITS*F_WIDTH-1:0]         in_features,
    input                           fin_valid,
    output                          fin_ready,

    output reg                      valence,
    output reg                      arousal,

    output reg                      dout_valid,
    input                           dout_ready
);

//------------------------------------------------//
//             Registers and Wires                //
//------------------------------------------------//

    localparam NPARALLEL = (V_NPARALLEL > A_NPARALLEL) ? V_NPARALLEL : A_NPARALLEL;
    localparam FMEM_WIDTH = 144;

    reg signed [NBITS-1:0]                  features  [0:F_WIDTH-1];

    wire signed [NBITS*VSUP_WIDTH-1:0]      v_support;
    wire signed [NBITS-1:0]                 v_alpha;
    reg signed  [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept;

    wire signed [NBITS*ASUP_WIDTH-1:0]      a_support;
    wire signed [NBITS-1:0]                 a_alpha;
    reg signed  [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept;
 
    reg signed [NBITS-1:0] matmul1_ina [0:NPARALLEL-1];
    reg signed [NBITS-1:0] matmul1_inb;
    reg signed [NBITS-1:0] matmul1_vout [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_row_result [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_result [0:SUP_WIDTH-1];

    reg signed [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result; 

    reg matmul2_v_valid;
    reg matmul2_a_valid;

    wire [7:0] addr;
    wire [7:0] mem_read_addr;
    wire fin_fire;

    reg         [LOG_SUP_WIDTH:0]   sidx;
    reg         [LOG_F_WIDTH:0]     fidx;
    reg         [2:0]               curr_state;
    localparam  WRITE_SRAM  = 3'b000; // 0
    localparam  IDLE        = 3'b001; // 1
    localparam  V_MATMUL1   = 3'b011; // 3
    localparam  V_MATMUL2   = 3'b010; // 2
    localparam  WAIT_A      = 3'b110; // 6
    localparam  A_MATMUL1   = 3'b111; // 7
    localparam  A_MATMUL2   = 3'b101; // 5

    assign mem_write_ready  = (curr_state == WRITE_SRAM);
    assign addr             = (curr_state == WRITE_SRAM) ? mem_write_addr : mem_read_addr;
    assign mem_read_addr    = (curr_state == V_MATMUL1 || curr_state == A_MATMUL1) ? fidx : 
                              (curr_state == V_MATMUL2 || curr_state == A_MATMUL2) ? sidx : 8'd0;

    assign fin_fire         = fin_valid && fin_ready;
    assign fin_ready        = (curr_state == IDLE || curr_state == WAIT_A);
    always @(posedge clk) begin
        dout_valid  <= matmul2_a_valid;
    end
    // outside is always dout_ready

//-----------------------------------------//
//            SVM SRAM Memories            //
//-----------------------------------------//

    // change this instantiation if using different RFE #features
    SVM_memories_214 #(
        .NBITS          (NBITS),
        .VSUP_WIDTH     (VSUP_WIDTH),
        .ASUP_WIDTH     (ASUP_WIDTH),
        .FMEM_WIDTH     (FMEM_WIDTH),
        .LOG_FMEM_WIDTH (`ceilLog2(FMEM_WIDTH))
    ) mem (
        .clk            (clk),
        .rst            (rst),

        .addr           (addr),
        .we             (mem_we),

        .v_in_support   (v_in_support),
        .v_in_alpha     (v_in_alpha),
        
        .a_in_support   (a_in_support),
        .a_in_alpha     (a_in_alpha),

        .v_out_support  (v_support),
        .v_out_alpha    (v_alpha),

        .a_out_support  (a_support),
        .a_out_alpha    (a_alpha)
    );

//------------------------------------------------//
//             Multiply-Quantize Unit             //
//------------------------------------------------//

    multiply_quantize #(
		.NBITS      (NBITS),
        .NPARALLEL  (NPARALLEL)
	) mq (
        .ina        (matmul1_ina),
        .inb        (matmul1_inb),
        .vout       (matmul1_vout)
    );

//------------------------------------------------//
//                 Matmul1 Inputs                 //
//------------------------------------------------//

    integer pi;
    always @(*) begin
        case (curr_state)
            V_MATMUL1: begin
                for (pi = 0; pi < V_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = v_support[(sidx+pi)*NBITS +: NBITS];
                end
                matmul1_inb     = features[fidx-1];
            end

            V_MATMUL2: begin
                for (pi = 0; pi < V_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = 0;
                end
                matmul1_inb     = 0;
            end

            A_MATMUL1: begin
                for (pi = 0; pi < A_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = a_support[(sidx+pi)*NBITS +: NBITS];
                end
                matmul1_inb     = features[fidx-1];
            end

            A_MATMUL2: begin
                for (pi = 0; pi < A_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = 0;
                end
                matmul1_inb     = 0;
            end
        endcase
    end

//------------------//
//       FSM        //
//------------------//

    integer f;
    integer p;
    always @(posedge clk) begin
        if (rst) begin
            for (p = 0; p < NPARALLEL; p = p + 1) begin
                matmul1_row_result[p]   <= 0;
            end
            matmul2_result      <= 0;
            matmul2_v_valid     <= 1'b0;
            matmul2_a_valid     <= 1'b0;

            curr_state          <= WRITE_SRAM;
        end

        case (curr_state)
            WRITE_SRAM: begin
                if (intercept_valid) begin
                    v_intercept     <= v_in_intercept;
                    a_intercept     <= a_in_intercept;
                end

                if (mem_write_done) begin
                    curr_state      <= IDLE;
                end
            end

            IDLE: begin
                for (p = 0; p < NPARALLEL; p = p + 1) begin
                    matmul1_row_result[p]   <= 0;
                end
                matmul2_result      <= 0;
                matmul2_v_valid     <= 1'b0;
                matmul2_a_valid     <= 1'b0;

                if (fin_fire) begin
                    for (f = 0; f < F_WIDTH; f = f + 1) begin
                        features[f]   <= in_features[f*NBITS +: NBITS];
                    end

                    sidx        <= 0;
                    fidx        <= 0;
                    curr_state  <= V_MATMUL1;
                end
            end

            V_MATMUL1: begin 
                if (sidx == VSUP_WIDTH-V_NPARALLEL && fidx == F_WIDTH) begin
                    sidx                    <= 0;
                    fidx                    <= 0;
                    for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                    curr_state              <= V_MATMUL2;
                end else if (fidx == F_WIDTH) begin
                    sidx                    <= sidx + V_NPARALLEL;
                    fidx                    <= 0;
                    for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                end else begin
                    if (fidx == 1) begin
                        for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                            matmul1_row_result[p]   <= matmul1_vout[p];
                        end
                    end else begin
                        for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                            matmul1_row_result[p]   <= matmul1_row_result[p] + matmul1_vout[p];
                        end
                    end
                    fidx                    <= fidx + 1;
                end
            end

            V_MATMUL2: begin
                for (p = 0; p < NPARALLEL; p = p + 1) begin
                    matmul1_row_result[p]   <= 0;
                end

                if (sidx == VSUP_WIDTH) begin
                    sidx                <= 0;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx-1]*v_alpha;
                    matmul2_v_valid     <= 1'b1;
                    curr_state          <= WAIT_A; 
                end else if (sidx == 0) begin
                    sidx                <= sidx + 1;
                end else begin
                    sidx                <= sidx + 1;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx-1]*v_alpha;
                end
            end

            WAIT_A: begin
                matmul2_result          <= 0;
                matmul2_v_valid         <= 1'b0;
                
                if (fin_fire) begin
                    for (f = 0; f < F_WIDTH; f = f + 1) begin
                        features[f]   <= in_features[f*NBITS +: NBITS];
                    end

                    sidx        <= 0;
                    fidx        <= 0;
                    curr_state  <= A_MATMUL1;
                end
            end

            A_MATMUL1: begin
                if (sidx == ASUP_WIDTH-A_NPARALLEL && fidx == F_WIDTH) begin
                    sidx                    <= 0;
                    fidx                    <= 0;
                    for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                    curr_state              <= A_MATMUL2;
                end else if (fidx == F_WIDTH) begin
                    sidx                    <= sidx + A_NPARALLEL;
                    fidx                    <= 0;
                    for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                end else begin
                    if (fidx == 1) begin
                        for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                            matmul1_row_result[p]   <= matmul1_vout[p];
                        end
                    end else begin
                        for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                            matmul1_row_result[p]   <= matmul1_row_result[p] + matmul1_vout[p];
                        end
                    end
                    fidx                    <= fidx + 1;
                end
            end

            A_MATMUL2: begin
                for (p = 0; p < NPARALLEL; p = p + 1) begin
                    matmul1_row_result[p]   <= 0;
                end

                if (sidx == ASUP_WIDTH) begin
                    sidx                <= 0;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx-1]*a_alpha;
                    matmul2_a_valid     <= 1'b1;
                    curr_state          <= IDLE;
                end else if (sidx == 0) begin
                    sidx                <= sidx + 1;
                end else begin
                    sidx                <= sidx + 1;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx-1]*a_alpha;
                end
            end

        endcase
    end

//---------------------------//
//    Output Declarations    //
//---------------------------//

    always @(posedge clk) begin
        if (matmul2_v_valid) begin
            valence <= (matmul2_result > -v_intercept);
        end

        if (matmul2_a_valid) begin
            arousal <= (matmul2_result > -a_intercept);
        end
    end

endmodule : SVM
