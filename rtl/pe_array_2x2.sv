// ============================================================================
// pe_array_2x2.sv  --  given to you. You do not write or modify this file.
// ----------------------------------------------------------------------------
// Four of your PEs wired into a 2x2 weight-stationary systolic array. This is
// what you floorplan in week 8 and place and route in week 9.
//
// Why an array and not a single PE: floorplanning one cell is not a decision,
// the tool has nothing to arrange. With four PEs there is a wrong answer and a
// right answer, and the difference shows up in wire length and congestion.
// Four is also small enough to route in an afternoon.
//
// Lambda's MatE runs an 8x8 grid of 64 PEs. This is that structure at 1/16
// scale. Everything you learn about where the wires go scales up unchanged.
//
// ----------------------------------------------------------------------------
// HOW DATA MOVES
// ----------------------------------------------------------------------------
// Activations enter from the WEST and travel east across a row, one PE per
// cycle. Partial sums enter from the NORTH and travel south down a column,
// accumulating as they go. Weights are loaded from the north before compute
// starts and then sit still, which is what "weight stationary" means.
//
//        a_in[0] ->  PE(0,0) --> PE(0,1)  -> (activation falls off the east edge)
//                       |           |
//        a_in[1] ->  PE(1,0) --> PE(1,1)
//                       |           |
//                   psum_out[0]  psum_out[1]
//
// Column c computes the dot product of the activation stream against the
// weights held in column c. Two columns, so two dot products at once, which is
// the whole point: each activation is read from memory once and used by every
// PE in its row.
//
// ----------------------------------------------------------------------------
// LOADING WEIGHTS
// ----------------------------------------------------------------------------
// Hold accept_w high for 2 cycles (one per row) and present one weight row per
// cycle on w_in. Weights shift down the column, so the LAST row you present
// ends up in the TOP PE. Present them bottom row first.
//
// Then pulse switch to promote them. Compute can continue through the switch
// cycle; that is what the double buffer inside each PE is for.
//
// ----------------------------------------------------------------------------
// TIMING SKEW
// ----------------------------------------------------------------------------
// Column 1 sees each activation one cycle after column 0, because the
// activation had to travel through column 0 to get there. Row 1's partial sum
// arrives one cycle after row 0's for the same reason. A driver feeding this
// array has to skew its inputs to match. The testbench does this for you; if
// you build an array of your own later, this is the part that catches people.
//
// ----------------------------------------------------------------------------
// ONE THING YOU WILL NOTICE IN WEEK 7
// ----------------------------------------------------------------------------
// This array does not synthesize to four times one PE. The east edge of column
// 1 and the south weight edge of row 1 drive nothing, so synthesis deletes the
// flops behind them. Expect roughly 260 flops, not 328. Work out which ones
// went and why before you assume something is broken. In an 8x8 grid those
// edges connect to the next tile and the flops stay.
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

module pe_array_2x2 #(
    parameter  int QI = 8,
    parameter  int QF = 8,
    localparam int DW = QI + QF
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 enabled,

    // West edge: one activation stream per row. Packed, row 0 in the low bits:
    //   row 0 = a_in[DW-1:0]     row 1 = a_in[2*DW-1:DW]
    // Packed rather than an unpacked array on purpose. Unpacked array ports
    // survive simulation but produce escaped pin names downstream that are
    // painful to constrain in SDC and to find in the layout.
    input  logic [2*DW-1:0] a_in,
    input  logic [1:0]      valid_in,
    input  logic            switch_in,

    // North edge: one weight stream per column, same packing.
    input  logic [2*DW-1:0] w_in,
    input  logic            accept_w,

    // South edge: one accumulated result per column, same packing.
    output logic [2*DW-1:0] psum_out,
    output logic [1:0]      valid_out
);

    // Interconnect between the four PEs. [row][col].
    logic signed [DW-1:0] psum   [0:2][0:1];   // row 2 is the bottom output
    logic signed [DW-1:0] wgt    [0:2][0:1];
    logic signed [DW-1:0] act    [0:1][0:2];   // col 2 is the east edge
    logic                 vld    [0:1][0:2];
    logic                 swt    [0:1][0:2];

    genvar r, c;
    generate
        for (c = 0; c < 2; c++) begin : g_north
            // Top of each column: partial sums start at zero, weights enter here.
            assign psum[0][c] = '0;
            assign wgt [0][c] = $signed(w_in[c*DW +: DW]);
        end
        for (r = 0; r < 2; r++) begin : g_west
            // Left of each row: activations and their control enter here.
            assign act[r][0] = $signed(a_in[r*DW +: DW]);
            assign vld[r][0] = valid_in[r];
            assign swt[r][0] = switch_in;
        end

        for (r = 0; r < 2; r++) begin : g_row
            for (c = 0; c < 2; c++) begin : g_col
                pe #(.QI(QI), .QF(QF)) u_pe (
                    .clk            (clk),
                    .rst            (rst),
                    .pe_psum_in     (psum[r][c]),
                    .pe_weight_in   (wgt [r][c]),
                    .pe_accept_w_in (accept_w),
                    .pe_input_in    (act[r][c]),
                    .pe_valid_in    (vld[r][c]),
                    .pe_switch_in   (swt[r][c]),
                    .pe_enabled     (enabled),
                    .pe_psum_out    (psum[r+1][c]),
                    .pe_weight_out  (wgt [r+1][c]),
                    .pe_input_out   (act[r][c+1]),
                    .pe_valid_out   (vld[r][c+1]),
                    .pe_switch_out  (swt[r][c+1])
                );
            end
        end

        for (c = 0; c < 2; c++) begin : g_south
            assign psum_out[c*DW +: DW] = psum[2][c];
            assign valid_out[c]         = vld[1][2];   // bottom row's valid
        end
    endgenerate

endmodule

`default_nettype wire
