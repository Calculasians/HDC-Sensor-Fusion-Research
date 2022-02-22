`include "const.vh"

module SVM_Matmul1 #(
    parameter NBITS,
    parameter F_WIDTH,
    parameter LOG_F_WIDTH,
    parameter SUP_WIDTH,
    parameter LOG_SUP_WIDTH,
    parameter MESHROWS,
    parameter MESHCOLUMNS,
    parameter INPUT_BITWIDTH,
    parameter OUTPUT_BITWIDTH,
    parameter TILEROWS,
    parameter TILECOLUMNS
) (
    input                                       clk,
    input                                       rst,

    input signed        [NBITS-1:0]             features  [0:F_WIDTH-1],

    input signed        [NBITS*F_WIDTH-1:0]     v_support,
    input signed        [NBITS*F_WIDTH-1:0]     a_support,

    input                                       sending_v_into_sa,
    input                                       sending_a_into_sa,
    input                                       sending_f_into_sa,
    input                                       reading_r_from_sa,

    input               [LOG_F_WIDTH-1:0]       read_fidx,
    input               [LOG_SUP_WIDTH-1:0]     write_sidx,

    input                                       in_control_propagate[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
    input                                       in_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],

    output reg signed   [NBITS+LOG_F_WIDTH-1:0] matmul1_result [0:SUP_WIDTH-1]
);

    reg  signed [INPUT_BITWIDTH-1:0]        in_a[MESHROWS-1:0][TILEROWS-1:0];
    wire signed [INPUT_BITWIDTH-1:0]        in_b[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire signed [OUTPUT_BITWIDTH-1:0]       out_c[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];
    wire                                    out_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0];

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

//-----------------------------------------------//
//   Systolic Array Input / Output Assignments   //
//-----------------------------------------------//

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

    // Writing into in_b of systolic array
    assign in_b[0][0] = (sending_f_into_sa) ? features[read_fidx] : 0;

    // Reading from systolic array and storing them into intermediate matmul1 result array
    always @(posedge clk) begin
        if (reading_r_from_sa) begin
            matmul1_result[write_sidx] <= out_c[0][0];
        end
    end

endmodule : SVM_Matmul1
