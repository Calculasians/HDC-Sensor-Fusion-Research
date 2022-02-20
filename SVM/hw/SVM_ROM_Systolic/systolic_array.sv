
// This is the blackbox we are asking you to implement
// Assume TILEROWS=1, and TILECOLUMNS=1
module systolic_array
    #(parameter MESHROWS, MESHCOLUMNS, INPUT_BITWIDTH, OUTPUT_BITWIDTH, TILEROWS=1, TILECOLUMNS=1)
    (
        input                               clock,
        input                               reset,
        input signed [INPUT_BITWIDTH-1:0]   in_a[MESHROWS-1:0][TILEROWS-1:0],
        input signed [INPUT_BITWIDTH-1:0]   in_d[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        input signed [INPUT_BITWIDTH-1:0]   in_b[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        input                               in_control_dataflow[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        input                               in_control_propagate[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        input                               in_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        output reg signed [OUTPUT_BITWIDTH-1:0] out_c[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        output signed [OUTPUT_BITWIDTH-1:0] out_b[MESHCOLUMNS-1:0][TILECOLUMNS-1:0],
        output reg                          out_valid[MESHCOLUMNS-1:0][TILECOLUMNS-1:0]
    );

    // ---------------------------------------------------------
    // ---------------------------------------------------------
    //           DO NOT MODIFY ANYTHING ABOVE THIS
    // ---------------------------------------------------------
    // --------------------------------------------------------- 
    
    wire signed [INPUT_BITWIDTH-1:0]  forwarded_in_activation[MESHROWS-1:0][MESHCOLUMNS-1:0];
    wire signed [OUTPUT_BITWIDTH-1:0] partial_sum_result[MESHROWS-1:0][MESHCOLUMNS-1:0];

    reg signed [INPUT_BITWIDTH-1:0]   vert_reg[MESHROWS-1:0][MESHCOLUMNS-1:0];
    reg signed [OUTPUT_BITWIDTH-1:0]  hor_reg[MESHROWS-1:0][MESHCOLUMNS-1:0];

    reg signed [INPUT_BITWIDTH-1:0]   in_weight_pe[MESHROWS-1:0][MESHCOLUMNS-1:0];
    reg                               valid[MESHROWS-1:0][MESHCOLUMNS-1:0];
    reg                               propagate[MESHROWS-1:0][MESHCOLUMNS-1:0];
    wire signed [INPUT_BITWIDTH-1:0]  out_weight_pe[MESHROWS-1:0][MESHCOLUMNS-1:0];

    reg [MESHROWS-1:0]		            out_valid_shift_reg [MESHCOLUMNS-1:0];

    // ---------------------- //
    //   VERTICAL REGISTER    //
    // ---------------------- //
    // The Vertical Registers are the vertical pipeline registers between each
    // PE in the Systolic Mesh

    // assigning leftmost column of vert_reg to the input activations
    integer vxx;
    always @(*) begin
      for (vxx = 0; vxx < MESHROWS; vxx = vxx + 1) begin
        vert_reg[vxx][0] = in_a[vxx][0];
      end
    end

    // assigning the next vert_reg[x][y] to the output of PE[x][y-1]. This
    // models propagating input activations to the right at each cycle.
    integer vx;
    integer vy;
    always @(posedge clock) begin
      for (vx = 0; vx < MESHROWS; vx = vx + 1) begin
        for (vy = 1; vy < MESHCOLUMNS; vy = vy + 1) begin
          vert_reg[vx][vy] <= forwarded_in_activation[vx][vy-1];
        end
      end
    end

    // ------------------------ //
    //   HORIZONTAL REGISTER    //
    // ------------------------ //
    // The Horizontal Registers are the horizontal pipeline registers between
    // each PE in the Systolic Mesh

    // assigning topmost row of hor_reg to all 0's
    integer hyy;
    always @(posedge clock) begin
      for (hyy = 0; hyy < MESHCOLUMNS; hyy = hyy + 1) begin
        hor_reg[0][hyy] <= 1'b0;
      end
    end

    // assigning the next hor_reg[x][y] to the output of PE[x-1][y]. This
    // models propagating the partial sum of the previous PE to the next PE.
    integer hx;
    integer hy;
    always @(posedge clock) begin
      for (hx = 1; hx < MESHROWS; hx = hx + 1) begin
        for (hy = 0; hy < MESHCOLUMNS; hy = hy + 1) begin
          hor_reg[hx][hy] <= partial_sum_result[hx-1][hy];
        end
      end
    end

    // The bottom row of partial sums is registered into the output
    integer oy; 
    always @(posedge clock) begin
      for (oy = 0; oy < MESHCOLUMNS; oy = oy + 1) begin
        out_c[oy][0] <= partial_sum_result[MESHROWS-1][oy];
      end
    end

    // ------------------------------- //
    //   WEIGHT DATA/CTRL REGISTERS    //
    // ------------------------------- //

    // Assigning local propagate, in_weight_pe, and valid signals from global
    // inputs for input into the top row of PEs
    integer wyy;
    always @(*) begin
      for (wyy = 0; wyy < MESHCOLUMNS; wyy = wyy + 1) begin
        in_weight_pe[0][wyy] = in_b[wyy][0];
        propagate[0][wyy] = in_control_propagate[wyy][0];
        valid[0][wyy] = in_valid[wyy][0];
      end  
    end

    // The valid and propagate control signals are propagated downwards at
    // each cycle
    integer wx;
    integer wy;
    always @(posedge clock) begin
      for (wx = 1; wx < MESHROWS; wx = wx + 1) begin
        for (wy = 0; wy < MESHCOLUMNS; wy = wy + 1) begin
          propagate[wx][wy] <= propagate[wx-1][wy];
          valid[wx][wy] <= valid[wx-1][wy];
        end
      end
    end

    // The output weight of each PE gets propagated as the input weight to the
    // next PE below
    integer qx;
    integer qy;
    always @(*) begin
      for (qx = 1; qx < MESHROWS; qx = qx + 1) begin
        for (qy = 0; qy < MESHCOLUMNS; qy = qy + 1) begin
          in_weight_pe[qx][qy] = out_weight_pe[qx-1][qy];
        end
      end
    end

    // -------------- //
    //   PE MODULES   //
    // -------------- //

    // Generate MESHROWSxMESHCOLUMNS instances of PEs
    genvar x;
    genvar y;
    generate 
      for (x = 0; x < MESHROWS; x = x + 1) begin : pe_x
        for (y = 0; y < MESHCOLUMNS; y = y + 1) begin : pe_y
          systolic_mesh_PE #(
            .MESHROWS         (MESHROWS),
            .MESHCOLUMNS      (MESHCOLUMNS),
            .INPUT_BITWIDTH   (INPUT_BITWIDTH),
            .OUTPUT_BITWIDTH  (OUTPUT_BITWIDTH),
            .TILEROWS         (TILEROWS),
            .TILECOLUMNS      (TILECOLUMNS)
          ) smp (
            .clock                      (clock),
            .reset                      (reset),

            .in_activation              (vert_reg[x][y]),
            .forwarded_in_activation    (forwarded_in_activation[x][y]),

            .in_partial_sum             (hor_reg[x][y]),
            .partial_sum_result         (partial_sum_result[x][y]),

            .in_weight                  (in_weight_pe[x][y]),
            .in_valid                   (valid[x][y]),
            .in_propagate               (propagate[x][y]),
            .out_weight                 (out_weight_pe[x][y])
          );
        end
      end
    endgenerate

    // ------------------- //
    //   OUTPUT SHIFT REG  //
    // ------------------- //

    // out_valid is always MESHROWS cycles delayed from in_valid
    integer s;
    always @(posedge clock) begin
      for (s = 0; s < MESHCOLUMNS; s = s + 1) begin
	      out_valid_shift_reg[s] <= {out_valid_shift_reg[s][MESHROWS-2:0], in_valid[s][0]};
      end
    end

    integer ss;
    always @(*) begin
      for (ss = 0; ss < MESHCOLUMNS; ss = ss + 1) begin
        out_valid[ss][0] = out_valid_shift_reg[ss][MESHROWS-1];
      end
    end

endmodule // MeshBlackBox

module systolic_mesh_PE #(parameter MESHROWS, MESHCOLUMNS, INPUT_BITWIDTH, OUTPUT_BITWIDTH, TILEROWS=1, TILECOLUMNS=1) (
  input   clock,
  input   reset,

  input signed [INPUT_BITWIDTH-1:0]      in_activation,
  output signed [INPUT_BITWIDTH-1:0]     forwarded_in_activation,

  input signed [OUTPUT_BITWIDTH-1:0]     in_partial_sum,
  output reg signed [OUTPUT_BITWIDTH-1:0]    partial_sum_result,

  input signed [INPUT_BITWIDTH-1:0]      in_weight,
  input                                  in_valid,
  input                                  in_propagate,
  output reg signed [INPUT_BITWIDTH-1:0]     out_weight
); 

  reg signed [INPUT_BITWIDTH-1:0] reg_0;
  reg signed [INPUT_BITWIDTH-1:0] reg_1;

  reg signed [2*INPUT_BITWIDTH-1:0] temp;

  assign forwarded_in_activation = in_activation;

  // If in_valid is true to the PE, we store the weight into one of the
  // 2 registers, depending on the value of propagate. 
  // The current value of the 2 registers (chosen by propagate) will also be propagated as weights to the next PE.
  // Finally, the partial sum is calculated by performing in_a * reg + partial_sum from above.

  always @(posedge clock) begin
    if (in_valid) begin
      if (~in_propagate) 
        reg_0 <= in_weight;
      else  // in_propagate
        reg_1 <= in_weight;
    end
  end

  always @(posedge clock) begin
    if (in_valid) begin
      if (~in_propagate)
        out_weight <= reg_0;
      else
        out_weight <= reg_1;
    end
  end

  // always @(*) begin
  //   if (in_valid) begin
  //     if (~in_propagate)
  //       partial_sum_result = in_activation * reg_1 + in_partial_sum;
  //     else 
  //       partial_sum_result = in_activation * reg_0 + in_partial_sum;
  //   end else begin
  //     partial_sum_result = partial_sum_result;
  //   end
  // end
  always @(*) begin
      if (~in_propagate) begin
        temp = (in_activation * reg_1) >>> INPUT_BITWIDTH; // additional quantization
        partial_sum_result = temp + in_partial_sum;
      end else begin
        temp = (in_activation * reg_0) >>> INPUT_BITWIDTH;
        partial_sum_result = temp + in_partial_sum;
      end
  end

endmodule // systolic_mesh_PE
