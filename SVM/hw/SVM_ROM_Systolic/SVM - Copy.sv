`include "const.vh"
 
module SVM #(
	parameter NBITS = `NBITS,                           // #bits for quantization, 5 -> [-16:15]

	parameter VSUP_WIDTH = `VSUP_WIDTH,                 // width of v support vector
    parameter LOG_VSUP_WIDTH = `ceilLog2(VSUP_WIDTH),   // `ceilLog2(VSUP_WIDTH)
    // VSUP_WIDTH = VALPHA_WIDTH

    parameter ASUP_WIDTH = `ASUP_WIDTH,                 // width of a support vector
    parameter LOG_ASUP_WIDTH = `ceilLog2(ASUP_WIDTH),   // `ceilLog2(ASUP_WIDTH)
    // ASUP_WIDTH = AALPHA_WIDTH

    parameter F_WIDTH = `F_WIDTH,                       // how many features RFE selected
    parameter LOG_F_WIDTH = `ceilLog2(F_WIDTH),         // `ceilLog2(F_WIDTH)

    parameter SUP_WIDTH = (ASUP_WIDTH > VSUP_WIDTH) ? ASUP_WIDTH : VSUP_WIDTH,
    parameter LOG_SUP_WIDTH = (LOG_ASUP_WIDTH > LOG_VSUP_WIDTH) ? LOG_ASUP_WIDTH : LOG_VSUP_WIDTH
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

    localparam V_MIDX_CYCLES        = VSUP_WIDTH + F_WIDTH - 1;
    localparam A_MIDX_CYCLES        = ASUP_WIDTH + F_WIDTH - 1;
    localparam LOG_V_MIDX           = `ceilLog2(V_MIDX_CYCLES);
    localparam LOG_A_MIDX           = `ceilLog2(A_MIDX_CYCLES);
    localparam LOG_MIDX             = (LOG_V_MIDX > LOG_A_MIDX) ? LOG_V_MIDX : LOG_A_MIDX;

	localparam ROM_DEPTH			= 1024;
	localparam LOG_ROM_DEPTH		= `ceilLog2(ROM_DEPTH);
    localparam ROM_WIDTH            = 128;
    localparam ROM_TOTAL_WIDTH      = 2048;

    localparam VSUP_BASE_ADDR       = 0;
    localparam VALPHA_BASE_ADDR     = V_MIDX_CYCLES + A_MIDX_CYCLES;
    localparam ASUP_BASE_ADDR       = V_MIDX_CYCLES;
    localparam AALPHA_BASE_ADDR     = V_MIDX_CYCLES + A_MIDX_CYCLES + VSUP_WIDTH;

    localparam MESHROWS             = F_WIDTH;
    localparam MESHCOLUMNS          = 1;
    localparam INPUT_BITWIDTH       = NBITS;
    localparam OUTPUT_BITWIDTH      = NBITS + LOG_F_WIDTH;
    localparam TILEROWS             = 1;
    localparam TILECOLUMNS          = 1;

    reg signed [NBITS-1:0]                  features  [0:F_WIDTH-1];

    wire signed [ROM_TOTAL_WIDTH-1:0]	    mem_out;

    wire signed [NBITS*F_WIDTH-1:0]         v_support;
    wire signed [NBITS-1:0]                 v_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept;

    wire signed [NBITS*F_WIDTH-1:0]         a_support;
    wire signed [NBITS-1:0]                 a_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept;
 
    reg  signed [INPUT_BITWIDTH-1:0]        in_a[MESHROWS-1:0][TILEROWS-1:0];
    wire signed [INPUT_BITWIDTH-1:0]        in_b[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    in_control_propagate[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    in_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire signed [OUTPUT_BITWIDTH-1:0]       out_c[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    out_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];

    reg  signed [NBITS+LOG_F_WIDTH-1:0]                         matmul1_result [0:SUP_WIDTH-1];
    reg  signed [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result; 

    reg  matmul2_v_valid;
    reg  matmul2_a_valid;

    wire [LOG_ROM_DEPTH-1:0]    addr;
    wire [LOG_ROM_DEPTH-1:0]    mem_read_addr;
    wire fin_fire;
    wire dout_fire;

    reg  sending_v_into_sa;
    reg  sending_a_into_sa;
    wire read_v_features_done;
    wire comp_v_done;
    wire start_sending_in_a;

    reg  [LOG_F_WIDTH-1:0]      read_fidx;
    reg  [2:0]                  read_state;
    localparam READ_IDLE                = 3'b000;
    localparam READ_V_FEATURES          = 3'b001;
    localparam REQ_A_FEATURES           = 3'b010;
    localparam READ_A_FEATURES          = 3'b011;
    localparam WAIT_COMP_V_DONE         = 3'b100;
    localparam WAIT_CLASSIFICATION_DONE = 3'b101;

    reg  [LOG_SUP_WIDTH-1:0]    comp_sidx;
    reg  [LOG_SUP_WIDTH-1:0]    comp_sidx_delay;
    reg  [LOG_MIDX-1:0]         midx;
    reg  [2:0]                  comp_state;
    localparam COMP_IDLE        = 3'b000;
    localparam V_MATMUL1        = 3'b001;
    localparam V_MATMUL2        = 3'b010;
    localparam A_MATMUL1        = 3'b011;
    localparam A_MATMUL2        = 3'b100;

    reg  [LOG_F_WIDTH-1:0]      write_fidx;
    reg  [LOG_SUP_WIDTH-1:0]    write_sidx;
    reg                         v_alpha_valid;
    reg                         a_alpha_valid;
    reg  [2:0]                  write_state;
    localparam WRITE_IDLE               = 3'b000;
    localparam WAIT_V_OUT               = 3'b001;
    localparam WRITE_V_MATMUL_1_RESULT  = 3'b010;
    localparam WRITE_BREAK              = 3'b011;
    localparam WAIT_A_OUT               = 3'b100;
    localparam WRITE_A_MATMUL_1_RESULT  = 3'b101;

    assign addr             = mem_read_addr;
    assign mem_read_addr    = (comp_state == V_MATMUL1) ? midx + VSUP_BASE_ADDR :
                              (comp_state == V_MATMUL2) ? comp_sidx + VALPHA_BASE_ADDR :
                              (comp_state == A_MATMUL1) ? midx + ASUP_BASE_ADDR :
                              (comp_state == A_MATMUL2) ? comp_sidx + AALPHA_BASE_ADDR : 0;
    assign v_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*F_WIDTH)];
    assign a_support        = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS*F_WIDTH)];
    assign v_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    assign a_alpha          = mem_out[ROM_TOTAL_WIDTH-1:ROM_TOTAL_WIDTH-(NBITS)];
    assign v_intercept      = 26'b11111111111010111101001010; // -20662
    assign a_intercept      = 26'b11111111101110010110100111; // -72281

    assign fin_fire         = fin_valid && fin_ready;
    assign fin_ready        = (read_state == READ_IDLE) || (read_state == REQ_A_FEATURES);
    assign dout_fire        = dout_valid && dout_ready;
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
	    .ROM_DEPTH          (ROM_DEPTH),
	    .LOG_ROM_DEPTH      (`ceilLog2(1024)),
	    .ROM_WIDTH          (ROM_WIDTH),
	    .ROM_TOTAL_WIDTH    (ROM_TOTAL_WIDTH)
    ) mem (
        .clk        (clk),
        .addr       (addr),
        .mem_out    (mem_out)
    );

//------------------------------------------------//
//                 Systolic Array                 //
//------------------------------------------------//

    systolic_array #(
        .MESHROWS           (MESHROWS),
        .MESHCOLUMNS        (MESHCOLUMNS),
        .INPUT_BITWIDTH     (INPUT_BITWIDTH),
        .OUTPUT_BITWIDTH    (OUTPUT_BITWIDTH),
        .TILEROWS           (TILEROWS),
        .TILECOLUMNS        (TILECOLUMNS)
    ) sa (
        .clock                  (clk),
        .reset                  (rst),
        .in_a                   (in_a),
        .in_d                   (), // not used
        .in_b                   (in_b),
        .in_control_dataflow    (), // not used
        .in_control_propagate   (in_control_propagate),
        .in_valid               (in_valid),
        .out_c                  (out_c),
        .out_b                  (), // not used
        .out_valid              (out_valid)
    );

//------------------//
//       FSMs       //
//------------------//

    // sending_in_a is high for all cycles where in_a to systolic array is valid
    always @(posedge clk) begin
        sending_v_into_sa   <= (comp_state == V_MATMUL1);
        sending_a_into_sa   <= (comp_state == A_MATMUL1);
    end

    // Writing into in_a of systolic array
    integer x;
    always @(*) begin
        if (sending_v_into_sa) begin
            for (x = 0; x < F_WIDTH; x = x + 1) begin
                in_a[x][0] = v_support[((F_WIDTH*NBITS) - ((x+1)*NBITS)) +: NBITS];
            end
        end

        if (sending_a_into_sa) begin
            for (x = 0; x < F_WIDTH; x = x + 1) begin
                in_a[x][0] = a_support[((F_WIDTH*NBITS) - ((x+1)*NBITS)) +: NBITS];
            end
        end
    end

    assign in_b[0][0] = (read_state == READ_V_FEATURES || read_state == READ_A_FEATURES) ? features[read_fidx] : 0;

    // This signal is sent from the READ_FSM to the COMP_FSM, indicating all V_features have been read
    assign read_v_features_done = (read_state == READ_V_FEATURES) && (read_fidx == 0);

    // This signal is sent from the COMP_FSM to the READ_FSM, indicating computations to valence are done
    assign comp_v_done = (comp_state == V_MATMUL2) && (comp_sidx == VSUP_WIDTH-1);

    // This signal is sent from the COMP_FSM to the WRITE_FSM, indicating that the COMP_FSM has begun sending in data to in_a of systolic array
    assign start_sending_in_a = (comp_state == V_MATMUL1 && midx == 0) || (comp_state == A_MATMUL1 && midx == 0);

    assign in_valid[0][0]               = (read_state == READ_V_FEATURES) || (read_state == READ_A_FEATURES);
    assign in_control_propagate[0][0]   = (read_state == READ_A_FEATURES) || (read_state == WAIT_COMP_V_DONE);

    // Obtaining data from systolic array and storing them into intermediate matmul1 result array
    always @(posedge clk) begin
        if (write_state == WRITE_V_MATMUL_1_RESULT || write_state == WRITE_A_MATMUL_1_RESULT) begin
            matmul1_result[write_sidx] <= out_c[0][0];
        end
    end

    // Indicates cycles where alpha values from ROMs are valid
    // comp_sidx_delay is the sidx from the values read from memory. comp_sidx is the view from the address request.
    always @(posedge clk) begin
        v_alpha_valid   <= (comp_state == V_MATMUL2);
        a_alpha_valid   <= (comp_state == A_MATMUL2);
        comp_sidx_delay <= comp_sidx;
    end

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

    //-------------------------- READ_FSM --------------------------//
    integer f;
    always @(posedge clk) begin
        if (rst) begin
            read_fidx                   <= F_WIDTH-1;
            read_state                  <= READ_IDLE;
        end

        case (read_state)

            READ_IDLE: begin
                if (fin_fire) begin
                    for (f = 0; f < F_WIDTH; f = f + 1) begin
                        features[f]             <= in_features[f*NBITS +: NBITS];
                    end

                    read_fidx                   <= F_WIDTH-1;
                    read_state                  <= READ_V_FEATURES;
                end
            end

            READ_V_FEATURES: begin
                if (read_fidx == 0) begin
                    read_fidx                   <= F_WIDTH-1;
                    read_state                  <= REQ_A_FEATURES;
                end else begin
                    read_fidx                   <= read_fidx - 1;
                end
            end

            REQ_A_FEATURES: begin
                for (f = 0; f < F_WIDTH; f = f + 1) begin
                    features[f]                 <= in_features[f*NBITS +: NBITS];
                end
                read_state                      <= READ_A_FEATURES;
            end

            READ_A_FEATURES: begin
                if (read_fidx == 0) begin
                    read_fidx                   <= F_WIDTH-1;
                    read_state                  <= WAIT_COMP_V_DONE;
                end else begin
                    read_fidx                   <= read_fidx - 1;
                end
            end

            WAIT_COMP_V_DONE: begin
                if (comp_v_done) 
                    read_state                  <= WAIT_CLASSIFICATION_DONE;
            end

            WAIT_CLASSIFICATION_DONE: begin
                if (dout_fire)
                    read_state                  <= READ_IDLE;
            end

        endcase
    end

    //-------------------------- COMP_FSM --------------------------//
    always @(posedge clk) begin
        if (rst) begin
            midx                        <= 0;
            comp_sidx                   <= 0;
            comp_state                  <= COMP_IDLE;
        end

        case (comp_state)

            COMP_IDLE: begin
                if (read_v_features_done) begin
                    midx                        <= 0;
                    comp_sidx                   <= 0;
                    comp_state                  <= V_MATMUL1;
                end
            end

            V_MATMUL1: begin
                if (midx == V_MIDX_CYCLES-1) begin
                    midx                        <= 0;
                    comp_sidx                   <= 0;
                    comp_state                  <= V_MATMUL2;
                end else begin
                    midx                        <= midx + 1;
                end
            end

            V_MATMUL2: begin
                if (comp_sidx == VSUP_WIDTH-1) begin
                    midx                        <= 0;
                    comp_sidx                   <= 0;
                    comp_state                  <= A_MATMUL1;
                end else begin
                    comp_sidx                   <= comp_sidx + 1;
                end
            end

            A_MATMUL1: begin
                if (midx == A_MIDX_CYCLES-1) begin
                    midx                        <= 0;
                    comp_sidx                   <= 0;
                    comp_state                  <= A_MATMUL2;
                end else begin
                    midx                        <= midx + 1;
                end
            end

            A_MATMUL2: begin
                if (comp_sidx == ASUP_WIDTH-1) begin
                    midx                        <= 0;
                    comp_sidx                   <= 0;
                    comp_state                  <= COMP_IDLE;
                end else begin
                    comp_sidx                   <= comp_sidx + 1;
                end
            end

        endcase
    end

    //-------------------------- WRITE_FSM --------------------------//
    always @(posedge clk) begin
        if (rst) begin
            write_fidx                  <= 0;
            write_sidx                  <= 0;
            write_state                 <= WRITE_IDLE;          
        end

        case (write_state)

            WRITE_IDLE: begin
                if (start_sending_in_a) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WAIT_V_OUT;
                end
            end

            // count up to fidx because it takes fidx cycles for output from systolic array, after sending in in_a
            WAIT_V_OUT: begin
                if (write_fidx == F_WIDTH-1) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WRITE_V_MATMUL_1_RESULT;
                end else begin
                    write_fidx                  <= write_fidx + 1;
                end
            end

            WRITE_V_MATMUL_1_RESULT: begin
                if (write_sidx == VSUP_WIDTH-1) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WRITE_BREAK;
                end else begin
                    write_sidx                  <= write_sidx + 1;
                end
            end

            WRITE_BREAK: begin
                if (start_sending_in_a) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WAIT_A_OUT;
                end
            end

            WAIT_A_OUT: begin
                if (write_fidx == F_WIDTH-1) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WRITE_A_MATMUL_1_RESULT;
                end else begin
                    write_fidx                  <= write_fidx + 1;
                end     
            end

            WRITE_A_MATMUL_1_RESULT: begin
                if (write_sidx == ASUP_WIDTH-1) begin
                    write_fidx                  <= 0;
                    write_sidx                  <= 0;
                    write_state                 <= WRITE_IDLE;
                end else begin
                    write_sidx                  <= write_sidx + 1;
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
