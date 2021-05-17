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

    parameter V_NPARALLEL = 1,                              // how many v_supports to process in parallel, must be divisible by VSUP_WIDTH
    parameter A_NPARALLEL = 1                             // how many a_supports to process in parallel, must be divisible by ASUP_WIDTH
) (
    input                           clk,
    input                           rst,

    input signed    [NBITS*F_WIDTH-1:0]             in_features,
    input signed    [NBITS*SUP_WIDTH*F_WIDTH-1:0]   in_support,
    input signed    [NBITS*SUP_WIDTH-1:0]           in_alpha,
    input signed    [2*NBITS+LOG_SUP_WIDTH-1:0]     in_intercept,

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

    reg signed [NBITS-1:0]                  features  [0:F_WIDTH-1];
    reg signed [NBITS-1:0]                  support   [0:SUP_WIDTH-1][0:F_WIDTH-1];
    reg signed [NBITS-1:0]                  alpha     [0:SUP_WIDTH-1];
    reg signed [2*NBITS+LOG_SUP_WIDTH-1:0]  intercept;
 
    reg signed [NBITS-1:0] matmul1_ina [0:NPARALLEL-1];
    reg signed [NBITS-1:0] matmul1_inb;
    reg signed [NBITS-1:0] matmul1_vout [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_row_result [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_result [0:SUP_WIDTH-1];

    reg signed [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result; 

    reg matmul2_v_valid;
    reg matmul2_a_valid;

    wire fin_fire;

    reg         [LOG_SUP_WIDTH:0]   sidx;
    reg         [LOG_F_WIDTH:0]     fidx;
    reg         [2:0]               curr_state;
    localparam  IDLE        = 3'b000;
    localparam  V_MATMUL1   = 3'b001;
    localparam  V_MATMUL2   = 3'b011;
    localparam  WAIT_A      = 3'b010;
    localparam  A_MATMUL1   = 3'b110;
    localparam  A_MATMUL2   = 3'b111;

    assign fin_fire     = fin_valid && fin_ready;
    assign fin_ready    = (curr_state == IDLE || curr_state == WAIT_A);
    always @(posedge clk) begin
        dout_valid  <= matmul2_a_valid;
    end
    // outside is always dout_ready

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
                    matmul1_ina[pi] = support[sidx+pi][fidx];
                end
                matmul1_inb     = features[fidx];
            end

            V_MATMUL2: begin
                for (pi = 0; pi < V_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = 0;
                end
                matmul1_inb     = 0;
            end

            A_MATMUL1: begin
                for (pi = 0; pi < A_NPARALLEL; pi = pi + 1) begin
                    matmul1_ina[pi] = support[sidx+pi][fidx];
                end
                matmul1_inb     = features[fidx];
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
    integer vi;
    integer vj;
    integer ai;
    integer aj;
    integer va;
    integer aa;
    integer k;
    integer p;
    always @(posedge clk) begin
        if (rst) begin
            for (p = 0; p < NPARALLEL; p = p + 1) begin
                matmul1_row_result[p]   <= 0;
            end
            matmul2_result      <= 0;
            matmul2_v_valid     <= 1'b0;
            matmul2_a_valid     <= 1'b0;

            curr_state          <= IDLE;
        end

        case (curr_state)
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

                    for (vi = 0; vi < VSUP_WIDTH; vi = vi + 1) begin
                        for (vj = 0; vj < F_WIDTH; vj = vj + 1) begin
                            support[vi][vj]   <= in_support[(vi*F_WIDTH*NBITS)+vj*NBITS +: NBITS];
                        end
                    end

					for (va = 0; va < VSUP_WIDTH; va = va + 1) begin
                        alpha[va]      <= in_alpha[va*NBITS +: NBITS];
					end

                    intercept <= in_intercept;

                    sidx        <= 0;
                    fidx        <= 0;
                    curr_state  <= V_MATMUL1;
                end
            end

            V_MATMUL1: begin
                matmul2_result          <= 0;
                matmul2_a_valid         <= 1'b0;

                if (sidx == VSUP_WIDTH-V_NPARALLEL && fidx == F_WIDTH-1) begin
                    sidx                    <= 0;
                    fidx                    <= 0;
                    for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                    curr_state              <= V_MATMUL2;
                end else if (fidx == F_WIDTH-1) begin
                    sidx                    <= sidx + V_NPARALLEL;
                    fidx                    <= 0;
                    for (p = 0; p < V_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                end else begin
                    if (fidx == 0) begin
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

                if (sidx == VSUP_WIDTH-1) begin
                    sidx                <= 0;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx]*alpha[sidx];
                    matmul2_v_valid     <= 1'b1;
                    curr_state          <= WAIT_A; 
                end else begin
                    sidx                <= sidx + 1;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx]*alpha[sidx];
                end
            end

            WAIT_A: begin
                matmul2_result          <= 0;
                matmul2_v_valid         <= 1'b0;
                
                if (fin_fire) begin
                    for (f = 0; f < F_WIDTH; f = f + 1) begin
                        features[f]   <= in_features[f*NBITS +: NBITS];
                    end

                    for (ai = 0; ai < ASUP_WIDTH; ai = ai + 1) begin
                        for (aj = 0; aj < F_WIDTH; aj = aj + 1) begin
                            support[ai][aj]   <= in_support[(ai*F_WIDTH*NBITS)+aj*NBITS +: NBITS];
                        end
                    end

                    for (aa = 0; aa < ASUP_WIDTH; aa = aa + 1) begin
                        alpha[aa]      <= in_alpha[aa*NBITS +: NBITS];
                    end

                    intercept <= in_intercept;

                    sidx        <= 0;
                    fidx        <= 0;
                    curr_state  <= A_MATMUL1;
                end
            end

            A_MATMUL1: begin
                if (sidx == ASUP_WIDTH-A_NPARALLEL && fidx == F_WIDTH-1) begin
                    sidx                    <= 0;
                    fidx                    <= 0;
                    for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                    curr_state              <= A_MATMUL2;
                end else if (fidx == F_WIDTH-1) begin
                    sidx                    <= sidx + A_NPARALLEL;
                    fidx                    <= 0;
                    for (p = 0; p < A_NPARALLEL; p = p + 1) begin
                        matmul1_result[sidx+p]  <= matmul1_row_result[p] + matmul1_vout[p];
                    end
                end else begin
                    if (fidx == 0) begin
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

                if (sidx == ASUP_WIDTH-1) begin
                    sidx                <= 0;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx]*alpha[sidx];
                    matmul2_a_valid     <= 1'b1;
                    curr_state          <= IDLE;
                end else begin
                    sidx                <= sidx + 1;
                    matmul2_result      <= matmul2_result + matmul1_result[sidx]*alpha[sidx];
                end
            end

        endcase
    end

//---------------------------//
//    Output Declarations    //
//---------------------------//

    always @(posedge clk) begin
        if (matmul2_v_valid) begin
            valence <= (matmul2_result > -intercept);
        end

        if (matmul2_a_valid) begin
            arousal <= (matmul2_result > -intercept);
        end
    end

endmodule : SVM
