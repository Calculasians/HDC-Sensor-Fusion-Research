`include "const.vh"

module SVM_control #(
    parameter NBITS,
    parameter VSUP_WIDTH,
    parameter LOG_VSUP_WIDTH,
    parameter ASUP_WIDTH,
    parameter LOG_ASUP_WIDTH,
    parameter F_WIDTH,
    parameter LOG_F_WIDTH,
    parameter SUP_WIDTH,
    parameter LOG_SUP_WIDTH,
    parameter V_MIDX_CYCLES,
    parameter A_MIDX_CYCLES,
    parameter LOG_V_MIDX,
    parameter LOG_A_MIDX,
    parameter LOG_MIDX,
    parameter MESHCOLUMNS,
    parameter TILECOLUMNS
) (
    input                                       clk,
    input                                       rst,

    // features
    input  signed       [NBITS*F_WIDTH-1:0]     in_features,
    input                                       fin_valid,
    output                                      fin_ready,
    output reg signed   [NBITS-1:0]             features  [0:F_WIDTH-1],

    // READ_FSM outputs
    output reg          [LOG_F_WIDTH-1:0]       read_fidx,

    // COMP_FSM outputs
    output reg          [LOG_SUP_WIDTH-1:0]     comp_sidx,
    output reg          [LOG_SUP_WIDTH-1:0]     comp_sidx_delay,
    output reg          [LOG_MIDX-1:0]          midx,

    // WRITE_FSM outputs
    output reg          [LOG_SUP_WIDTH-1:0]     write_sidx,

    // Control Logic Declarations
    output reg                                  sending_v_into_sa,
    output reg                                  sending_a_into_sa,
    output                                      sending_f_into_sa,
    output                                      reading_r_from_sa,

    output                                      in_control_propagate[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
    output                                      in_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],

    output                                      computing_v_matmul1,
    output                                      computing_v_matmul2,
    output                                      computing_a_matmul1,
    output                                      computing_a_matmul2,

    output reg                                  v_alpha_valid,
    output reg                                  a_alpha_valid,

    input                                       dout_fire
);

    // READ_FSM declarations
    reg  [2:0]                          read_state;
    localparam READ_IDLE                = 3'b000;
    localparam READ_V_FEATURES          = 3'b001;
    localparam REQ_A_FEATURES           = 3'b010;
    localparam READ_A_FEATURES          = 3'b011;
    localparam WAIT_COMP_V_DONE         = 3'b100;
    localparam WAIT_CLASSIFICATION_DONE = 3'b101;

    // COMP_FSM declarations
    reg  [2:0]                          comp_state;
    localparam COMP_IDLE                = 3'b000;
    localparam V_MATMUL1                = 3'b001;
    localparam V_MATMUL2                = 3'b010;
    localparam A_MATMUL1                = 3'b011;
    localparam A_MATMUL2                = 3'b100;

    // WRITE_FSM declarations
    reg  [LOG_F_WIDTH-1:0]              write_fidx;
    reg  [2:0]                          write_state;
    localparam WRITE_IDLE               = 3'b000;
    localparam WAIT_V_OUT               = 3'b001;
    localparam WRITE_V_MATMUL_1_RESULT  = 3'b010;
    localparam WRITE_BREAK              = 3'b011;
    localparam WAIT_A_OUT               = 3'b100;
    localparam WRITE_A_MATMUL_1_RESULT  = 3'b101;

    wire fin_fire;

    wire read_v_features_done;
    wire comp_v_done;
    wire start_sending_in_a;

    //---------------------------------------//
    //       Control Logic Assignments       //
    //---------------------------------------//

    assign fin_fire             = fin_valid && fin_ready;
    assign fin_ready            = (read_state == READ_IDLE) || (read_state == REQ_A_FEATURES);

    // sending_v/a_into_sa is high for all cycles where in_a to systolic array is valid
    always @(posedge clk) begin
        sending_v_into_sa   <= (comp_state == V_MATMUL1);
        sending_a_into_sa   <= (comp_state == A_MATMUL1);
    end

    // sending_f_into_sa is high for all cycles where in_b to systolic array is valid
    assign sending_f_into_sa    = (read_state == READ_V_FEATURES || read_state == READ_A_FEATURES);

    // reading_r_from_sa is high for all cycles where out_c from systolic array is valid
    assign reading_r_from_sa    = (write_state == WRITE_V_MATMUL_1_RESULT || write_state == WRITE_A_MATMUL_1_RESULT);

    // This signal is sent from the READ_FSM to the COMP_FSM, indicating all V_features have been read
    assign read_v_features_done = (read_state == READ_V_FEATURES) && (read_fidx == 0);

    // This signal is sent from the COMP_FSM to the READ_FSM, indicating computations to valence are done
    assign comp_v_done = (comp_state == V_MATMUL2) && (comp_sidx == VSUP_WIDTH-1);

    // This signal is sent from the COMP_FSM to the WRITE_FSM, indicating that the COMP_FSM has begun sending in data to in_a of systolic array
    assign start_sending_in_a = (comp_state == V_MATMUL1 && midx == 0) || (comp_state == A_MATMUL1 && midx == 0);

    // Control logic declarations for the systolic array
    assign in_valid[0][0]               = (read_state == READ_V_FEATURES) || (read_state == READ_A_FEATURES);
    assign in_control_propagate[0][0]   = (read_state == READ_A_FEATURES) || (read_state == WAIT_COMP_V_DONE);

    // Control logic for memory wrapper ROM address setup
    assign computing_v_matmul1  = (comp_state == V_MATMUL1);
    assign computing_v_matmul2  = (comp_state == V_MATMUL2);
    assign computing_a_matmul1  = (comp_state == A_MATMUL1);
    assign computing_a_matmul2  = (comp_state == A_MATMUL2);

    // Indicates cycles where alpha values from ROMs are valid
    // comp_sidx_delay is the sidx from the values read from memory. comp_sidx is the view from the address request.
    always @(posedge clk) begin
        v_alpha_valid   <= (comp_state == V_MATMUL2);
        a_alpha_valid   <= (comp_state == A_MATMUL2);
        comp_sidx_delay <= comp_sidx;
    end

    //------------------//
    //       FSMs       //
    //------------------//

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

endmodule : SVM_control
