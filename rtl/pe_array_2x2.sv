`ifndef PE_ARRAY_2X2_V
`define PE_ARRAY_2X2_V

`include "pe.sv"

`timescale 1ns/1ps
`default_nettype none

// 2x2 weight-stationary array. Activations flow west to east, partial sums
// flow north to south, weights are loaded from the north.
//
//   a_in[0] -> PE(0,0) -> PE(0,1)
//                |          |
//   a_in[1] -> PE(1,0) -> PE(1,1)
//                |          |
//            psum_out[0] psum_out[1]

module pe_array_2x2 #(
  parameter  QI = 8,
  parameter  QF = 8,
  localparam DW = QI + QF
)(
  input  logic            clk,
  input  logic            rst,
  input  logic            enabled,

  // west: row r is bits [r*DW +: DW]
  input  logic [2*DW-1:0] a_in,
  input  logic [1:0]      valid_in,
  input  logic            switch_in,

  // north: column c is bits [c*DW +: DW]
  input  logic [2*DW-1:0] w_in,
  input  logic            accept_w,

  // south: column c is bits [c*DW +: DW]
  output logic [2*DW-1:0] psum_out,
  output logic [1:0]      valid_out
);

  logic signed [DW-1:0] psum [0:2][0:1];
  logic signed [DW-1:0] wgt  [0:2][0:1];
  logic signed [DW-1:0] act  [0:1][0:2];
  logic                 vld  [0:1][0:2];
  logic                 swt  [0:1][0:2];

  genvar r, c;
  generate

    for ( c = 0; c < 2; c = c + 1 ) begin : g_north
      assign psum[0][c] = '0;
      assign wgt [0][c] = $signed( w_in[c*DW +: DW] );
    end

    for ( r = 0; r < 2; r = r + 1 ) begin : g_west
      assign act[r][0] = $signed( a_in[r*DW +: DW] );
      assign vld[r][0] = valid_in[r];
      assign swt[r][0] = switch_in;
    end

    for ( r = 0; r < 2; r = r + 1 ) begin : g_row
      for ( c = 0; c < 2; c = c + 1 ) begin : g_col
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

    for ( c = 0; c < 2; c = c + 1 ) begin : g_south
      assign psum_out[c*DW +: DW] = psum[2][c];
      assign valid_out[c]         = vld[1][2];
    end

  endgenerate

endmodule

`default_nettype wire
`endif
