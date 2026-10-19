`ifndef PE_ARRAY_V
`define PE_ARRAY_V

`timescale 1ns/1ps
`default_nettype none

// N x N weight-stationary systolic array of pe. Activations flow west to
// east, partial sums flow north to south, weights are loaded from the north.
// N = 2 is the stretch array; N = 8 is the challenge in CHALLENGE.md.
//
//   a_in[0] -> PE(0,0) -> PE(0,1) -> ... -> PE(0,N-1) -> valid_out[0]
//                 |          |                 |
//   a_in[1] -> PE(1,0) -> PE(1,1) -> ... -> PE(1,N-1) -> valid_out[1]
//                 |          |                 |
//              psum_out[0] psum_out[1]  ...  psum_out[N-1]
//
// Row r is bits [r*DW +: DW] of a_in; column c is bits [c*DW +: DW] of
// w_in and psum_out. valid_in and switch_in are one bit per row so the
// testbench can skew them with the activations; accept_w is one bit for
// the whole array because weights shift down a column one PE per cycle.

module pe_array #(
  parameter  N  = 2,
  parameter  QI = 8,
  parameter  QF = 8,
  localparam DW = QI + QF
)(
  input  wire              clk,
  input  wire              rst,
  input  wire              enabled,

  // west
  input  wire [N*DW-1:0]   a_in,
  input  wire [N-1:0]      valid_in,
  input  wire [N-1:0]      switch_in,

  // north
  input  wire [N*DW-1:0]   w_in,
  input  wire              accept_w,

  // south
  output wire [N*DW-1:0]   psum_out,

  // east
  output wire [N-1:0]      valid_out
);

  wire signed [DW-1:0] psum [0:N][0:N-1];
  wire signed [DW-1:0] wgt  [0:N][0:N-1];
  wire signed [DW-1:0] act  [0:N-1][0:N];
  wire                 vld  [0:N-1][0:N];
  wire                 swt  [0:N-1][0:N];

  genvar r, c;
  generate

    for ( c = 0; c < N; c = c + 1 ) begin : g_north
      assign psum[0][c] = '0;
      assign wgt [0][c] = $signed( w_in[c*DW +: DW] );
    end

    for ( r = 0; r < N; r = r + 1 ) begin : g_west
      assign act[r][0] = $signed( a_in[r*DW +: DW] );
      assign vld[r][0] = valid_in[r];
      assign swt[r][0] = switch_in[r];
    end

    for ( r = 0; r < N; r = r + 1 ) begin : g_row
      for ( c = 0; c < N; c = c + 1 ) begin : g_col
        pe #(QI,QF) u_pe (
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

    for ( c = 0; c < N; c = c + 1 ) begin : g_south
      assign psum_out[c*DW +: DW] = psum[N][c];
    end

    for ( r = 0; r < N; r = r + 1 ) begin : g_east
      assign valid_out[r] = vld[r][N];
    end

  endgenerate

endmodule

`default_nettype wire
`endif
