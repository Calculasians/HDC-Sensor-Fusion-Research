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
//               Local Parameters                 //
//------------------------------------------------//

    // COMP_FSM control parameters
    localparam V_MIDX_CYCLES        = VSUP_WIDTH + F_WIDTH - 1;
    localparam A_MIDX_CYCLES        = ASUP_WIDTH + F_WIDTH - 1;
    localparam LOG_V_MIDX           = `ceilLog2(V_MIDX_CYCLES);
    localparam LOG_A_MIDX           = `ceilLog2(A_MIDX_CYCLES);
    localparam LOG_MIDX             = (LOG_V_MIDX > LOG_A_MIDX) ? LOG_V_MIDX : LOG_A_MIDX;

    // SVM ROM memory parameters
	localparam ROM_DEPTH			= 1024;
	localparam LOG_ROM_DEPTH		= `ceilLog2(ROM_DEPTH);
    localparam ROM_WIDTH            = 128;
    localparam ROM_TOTAL_WIDTH      = 2048;

    // Base addresses for ROM accesses
    localparam VSUP_BASE_ADDR       = 0;
    localparam VALPHA_BASE_ADDR     = V_MIDX_CYCLES + A_MIDX_CYCLES;
    localparam ASUP_BASE_ADDR       = V_MIDX_CYCLES;
    localparam AALPHA_BASE_ADDR     = V_MIDX_CYCLES + A_MIDX_CYCLES + VSUP_WIDTH;

    // Systolic array parameters
    localparam MESHROWS             = F_WIDTH;
    localparam MESHCOLUMNS          = 1;
    localparam INPUT_BITWIDTH       = NBITS;
    localparam OUTPUT_BITWIDTH      = NBITS + LOG_F_WIDTH;
    localparam TILEROWS             = 1;
    localparam TILECOLUMNS          = 1;

//------------------------------------------------//
//             Registers and Wires                //
//------------------------------------------------//

    // From Matmul 1
    wire signed [NBITS+LOG_F_WIDTH-1:0]     matmul1_result [0:SUP_WIDTH-1];

    // From Matmul 2
    wire signed [(NBITS*(NBITS+LOG_F_WIDTH))+LOG_SUP_WIDTH-1:0] matmul2_result; 
    wire                                    matmul2_v_valid;
    wire                                    matmul2_a_valid;

    // From Decision
    wire                                    dout_fire;

    // From Control
    wire signed [NBITS-1:0]                 features  [0:F_WIDTH-1];
    wire        [LOG_F_WIDTH-1:0]           read_fidx;
    wire        [LOG_SUP_WIDTH-1:0]         comp_sidx;
    wire        [LOG_SUP_WIDTH-1:0]         comp_sidx_delay;
    wire        [LOG_MIDX-1:0]              midx;
    wire        [LOG_SUP_WIDTH-1:0]         write_sidx;
    wire                                    sending_v_into_sa;
    wire                                    sending_a_into_sa;
    wire                                    sending_f_into_sa;
    wire                                    reading_r_from_sa;
    wire                                    in_control_propagate[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    in_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    computing_v_matmul1;
    wire                                    computing_v_matmul2;
    wire                                    computing_a_matmul1;
    wire                                    computing_a_matmul2;
    wire                                    v_alpha_valid;
    wire                                    a_alpha_valid;

    // From Memory Wrapper
    wire signed [NBITS*F_WIDTH-1:0]         v_support;
    wire signed [NBITS-1:0]                 v_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] v_intercept;

    wire signed [NBITS*F_WIDTH-1:0]         a_support;
    wire signed [NBITS-1:0]                 a_alpha;
    wire signed [2*NBITS+LOG_SUP_WIDTH-1:0] a_intercept;

//-------------------------------------------//
//     SVM ROM Memories + Memory Wrapper     //
//-------------------------------------------//

    SVM_memory_wrapper #(
        .NBITS              (NBITS),
        .VSUP_WIDTH         (VSUP_WIDTH),
        .ASUP_WIDTH         (ASUP_WIDTH),
        .F_WIDTH            (F_WIDTH),
        .SUP_WIDTH          (SUP_WIDTH),
        .LOG_SUP_WIDTH      (LOG_SUP_WIDTH),
        .LOG_MIDX           (LOG_MIDX),
	    .ROM_DEPTH          (ROM_DEPTH),
	    .LOG_ROM_DEPTH      (LOG_ROM_DEPTH),
        .ROM_WIDTH          (ROM_WIDTH),
        .ROM_TOTAL_WIDTH    (ROM_TOTAL_WIDTH),
        .VSUP_BASE_ADDR     (VSUP_BASE_ADDR),
        .VALPHA_BASE_ADDR   (VALPHA_BASE_ADDR),
        .ASUP_BASE_ADDR     (ASUP_BASE_ADDR),
        .AALPHA_BASE_ADDR   (AALPHA_BASE_ADDR)
    ) memwrap (
        .clk                    (clk),
        .rst                    (rst),
        .comp_sidx              (comp_sidx),
        .midx                   (midx),
        .computing_v_matmul1    (computing_v_matmul1),
        .computing_v_matmul2    (computing_v_matmul2),
        .computing_a_matmul1    (computing_a_matmul1),
        .computing_a_matmul2    (computing_a_matmul2),
        .v_support              (v_support),
        .v_alpha                (v_alpha),
        .v_intercept            (v_intercept),
        .a_support              (a_support),
        .a_alpha                (a_alpha),
        .a_intercept            (a_intercept)      
    );
 
//-----------------//
//    MATMUL 1     //
//-----------------//

    SVM_Matmul1 #(
        .NBITS              (NBITS),
        .F_WIDTH            (F_WIDTH),
        .LOG_F_WIDTH        (LOG_F_WIDTH),
        .SUP_WIDTH          (SUP_WIDTH),
        .LOG_SUP_WIDTH      (LOG_SUP_WIDTH),
        .MESHROWS           (MESHROWS),
        .MESHCOLUMNS        (MESHCOLUMNS),
        .INPUT_BITWIDTH     (INPUT_BITWIDTH),
        .OUTPUT_BITWIDTH    (OUTPUT_BITWIDTH),
        .TILEROWS           (TILEROWS),
        .TILECOLUMNS        (TILECOLUMNS)
    ) mm1 (
        .clk                    (clk),
        .rst                    (rst),
        .features               (features),
        .v_support              (v_support),
        .a_support              (a_support),
        .sending_v_into_sa      (sending_v_into_sa),
        .sending_a_into_sa      (sending_a_into_sa),
        .sending_f_into_sa      (sending_f_into_sa),
        .reading_r_from_sa      (reading_r_from_sa),
        .read_fidx              (read_fidx),
        .write_sidx             (write_sidx),
        .in_control_propagate   (in_control_propagate),
        .in_valid               (in_valid),
        .matmul1_result         (matmul1_result)
    );

//-----------------//
//    MATMUL 2     //
//-----------------//

    SVM_Matmul2 #(
        .NBITS          (NBITS),
        .VSUP_WIDTH     (VSUP_WIDTH),
        .ASUP_WIDTH     (ASUP_WIDTH),
        .F_WIDTH        (F_WIDTH),
        .LOG_F_WIDTH    (LOG_F_WIDTH),
        .SUP_WIDTH      (SUP_WIDTH),
        .LOG_SUP_WIDTH  (LOG_SUP_WIDTH)
    ) mm2 (
        .clk                (clk),
        .rst                (rst),
        .matmul1_result     (matmul1_result),
        .v_alpha            (v_alpha),
        .a_alpha            (a_alpha),
        .comp_sidx_delay    (comp_sidx_delay),
        .v_alpha_valid      (v_alpha_valid),
        .a_alpha_valid      (a_alpha_valid),
        .matmul2_result     (matmul2_result),
        .matmul2_v_valid    (matmul2_v_valid),
        .matmul2_a_valid    (matmul2_a_valid)
    );

//----------------//
//    Decision    //
//----------------//

    SVM_decision #(
    .NBITS          (NBITS),
    .F_WIDTH        (F_WIDTH),
    .LOG_F_WIDTH    (LOG_F_WIDTH),
    .SUP_WIDTH      (SUP_WIDTH),
    .LOG_SUP_WIDTH  (LOG_SUP_WIDTH)
    ) dcsn (
        .clk                (clk),
        .rst                (rst),
        .matmul2_result     (matmul2_result),
        .matmul2_v_valid    (matmul2_v_valid),
        .matmul2_a_valid    (matmul2_a_valid),
        .v_intercept        (v_intercept),
        .a_intercept        (a_intercept),
        .dout_fire          (dout_fire),
        .dout_ready         (dout_ready),
        .dout_valid         (dout_valid),
        .valence            (valence),
        .arousal            (arousal)
    );

//---------------------------//
//       Control Logic       //
//---------------------------//

    SVM_control #(
        .NBITS              (NBITS),
        .VSUP_WIDTH         (VSUP_WIDTH),
        .LOG_VSUP_WIDTH     (LOG_VSUP_WIDTH),
        .ASUP_WIDTH         (ASUP_WIDTH),
        .LOG_ASUP_WIDTH     (LOG_ASUP_WIDTH),
        .F_WIDTH            (F_WIDTH),
        .LOG_F_WIDTH        (LOG_F_WIDTH),
        .SUP_WIDTH          (SUP_WIDTH),
        .LOG_SUP_WIDTH      (LOG_SUP_WIDTH),
        .V_MIDX_CYCLES      (V_MIDX_CYCLES),
        .A_MIDX_CYCLES      (A_MIDX_CYCLES),
        .LOG_V_MIDX         (LOG_V_MIDX),
        .LOG_A_MIDX         (LOG_A_MIDX),
        .LOG_MIDX           (LOG_MIDX),
        .MESHCOLUMNS        (MESHCOLUMNS),
        .TILECOLUMNS        (TILECOLUMNS)
    ) ctrl (
        .clk                    (clk),
        .rst                    (rst),
        .in_features            (in_features),
        .fin_valid              (fin_valid),
        .fin_ready              (fin_ready),
        .features               (features),
        .read_fidx              (read_fidx),
        .comp_sidx              (comp_sidx),
        .comp_sidx_delay        (comp_sidx_delay),
        .midx                   (midx),
        .write_sidx             (write_sidx),
        .sending_v_into_sa      (sending_v_into_sa),
        .sending_a_into_sa      (sending_a_into_sa),
        .sending_f_into_sa      (sending_f_into_sa),
        .reading_r_from_sa      (reading_r_from_sa),
        .in_control_propagate   (in_control_propagate),
        .in_valid               (in_valid),
        .computing_v_matmul1    (computing_v_matmul1),
        .computing_v_matmul2    (computing_v_matmul2),
        .computing_a_matmul1    (computing_a_matmul1),
        .computing_a_matmul2    (computing_a_matmul2),
        .v_alpha_valid          (v_alpha_valid),
        .a_alpha_valid          (a_alpha_valid),
        .dout_fire              (dout_fire)
    );

endmodule : SVM
