`include "/tools/B/daniels/hammer-tsmc28/src/SVM_ROM_Naive/const.vh"
 
module SVM #(
	parameter NBITS = `NBITS,                                // #bits for quantization, 5 -> [-16:15]

	parameter VSUP_WIDTH = `VSUP_WIDTH,                         // width of v support vector
    parameter LOG_VSUP_WIDTH = `ceilLog2(VSUP_WIDTH),   // `ceilLog2(VSUP_WIDTH)
    // VSUP_WIDTH = VALPHA_WIDTH

    parameter ASUP_WIDTH = `ASUP_WIDTH,                         // width of a support vector
    parameter LOG_ASUP_WIDTH = `ceilLog2(ASUP_WIDTH),   // `ceilLog2(ASUP_WIDTH)
    // ASUP_WIDTH = AALPHA_WIDTH

    parameter F_WIDTH = `F_WIDTH,                            // how many features RFE selected
    parameter LOG_F_WIDTH = `ceilLog2(F_WIDTH),         // `ceilLog2(F_WIDTH)

    parameter SUP_WIDTH = (ASUP_WIDTH > VSUP_WIDTH) ? ASUP_WIDTH : VSUP_WIDTH,
    parameter LOG_SUP_WIDTH = (LOG_ASUP_WIDTH > LOG_VSUP_WIDTH) ? LOG_ASUP_WIDTH : LOG_VSUP_WIDTH,

    parameter V_NPARALLEL = `V_NPARALLEL,                              // how many v_supports to process in parallel, must be divisible by VSUP_WIDTH
    parameter A_NPARALLEL = `A_NPARALLEL                             // how many a_supports to process in parallel, must be divisible by ASUP_WIDTH
) (
    input                           clk,
    input                           rst,

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

	localparam ROM_DEPTH			= 1024;
	localparam LOG_ROM_DEPTH		= `ceilLog2(ROM_DEPTH);
    localparam ROM_TOTAL_WIDTH      = 1408;

    localparam VSUP_BASE_ADDR   = 0;
    localparam VALPHA_BASE_ADDR = F_WIDTH + F_WIDTH;
    localparam ASUP_BASE_ADDR   = F_WIDTH;
    localparam AALPHA_BASE_ADDR = F_WIDTH + F_WIDTH + VSUP_WIDTH;

    reg signed [NBITS-1:0]                  features  [0:F_WIDTH-1];

    wire signed [ROM_TOTAL_WIDTH-1:0]	    mem_out;

    wire signed [NBITS*VSUP_WIDTH-1:0]      v_support;
    wire signed [NBITS-1:0]                 v_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept;

    wire signed [NBITS*ASUP_WIDTH-1:0]      a_support;
    wire signed [NBITS-1:0]                 a_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept;
 
    reg signed [NBITS-1:0] matmul1_ina [0:NPARALLEL-1];
    reg signed [NBITS-1:0] matmul1_inb;
    reg signed [NBITS-1:0] matmul1_vout [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_row_result [0:NPARALLEL-1];
    reg signed [NBITS+LOG_F_WIDTH-1:0] matmul1_result [0:SUP_WIDTH-1];

    reg signed [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result; 

    reg matmul2_v_valid;
    reg matmul2_a_valid;

    wire [LOG_ROM_DEPTH-1:0] addr;
    wire [LOG_ROM_DEPTH-1:0] mem_read_addr;
    wire fin_fire;

    reg         [LOG_SUP_WIDTH:0]   sidx;
    reg         [LOG_F_WIDTH:0]     fidx;
    reg         [2:0]               curr_state;
    localparam  IDLE        = 3'b000;
    localparam  V_MATMUL1   = 3'b001;
    localparam  V_MATMUL2   = 3'b010;
    localparam  WAIT_A      = 3'b011;
    localparam  A_MATMUL1   = 3'b100;
    localparam  A_MATMUL2   = 3'b101;

    assign addr             = mem_read_addr;
    assign mem_read_addr    = (curr_state == V_MATMUL1) ? fidx + VSUP_BASE_ADDR :
                              (curr_state == V_MATMUL2) ? sidx + VALPHA_BASE_ADDR :
                              (curr_state == A_MATMUL1) ? fidx + ASUP_BASE_ADDR :
                              (curr_state == A_MATMUL2) ? sidx + AALPHA_BASE_ADDR : 0;
    assign v_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*VSUP_WIDTH)];
    assign a_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*ASUP_WIDTH)];
    assign v_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    assign a_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    assign v_intercept      = 26'b11111111111010111101001010; // -20662
    assign a_intercept      = 26'b11111111101110010110100111; // -72281

    assign fin_fire         = fin_valid && fin_ready;
    assign fin_ready        = (curr_state == IDLE || curr_state == WAIT_A);
    always @(posedge clk) begin
        dout_valid  <= matmul2_a_valid;
    end
    // outside is always dout_ready

//-----------------------------------------//
//            SVM ROM Memories             //
//-----------------------------------------//

    // change this instantiation if using different RFE #features
    SVM_memories_214 #(
	    .NBITS              (NBITS),
	    .VSUP_WIDTH         (VSUP_WIDTH),
	    .ASUP_WIDTH         (ASUP_WIDTH),
	    .ROM_DEPTH          (1024),
	    .LOG_ROM_DEPTH      (`ceilLog2(1024)),
	    .ROM_WIDTH          (128),
	    .ROM_TOTAL_WIDTH    (ROM_TOTAL_WIDTH)
    ) mem (
        .clk        (clk),
        .addr       (addr),
        .mem_out    (mem_out)
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
