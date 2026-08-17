`ifndef FXP_V
`define FXP_V

`timescale 1ns/1ps
`default_nettype none

// Signed fixed-point add, Q(QI).(QF). Saturates.

module fxp_add #(
  parameter  QI = 8,
  parameter  QF = 8,
  localparam W  = QI + QF
)(
  input  wire signed [W-1:0] ina,
  input  wire signed [W-1:0] inb,
  output wire signed [W-1:0] out,
  output wire                overflow
);

  wire signed [W:0] sum = ina + inb;

  assign overflow = ( sum[W] != sum[W-1] );

  assign out = overflow ? ( sum[W] ? {1'b1, {(W-1){1'b0}}}
                                   : {1'b0, {(W-1){1'b1}}} )
                        : sum[W-1:0];

endmodule

// Signed fixed-point multiply, Q(QI).(QF). Truncates the low QF bits.

module fxp_mul #(
  parameter  QI = 8,
  parameter  QF = 8,
  localparam W  = QI + QF
)(
  input  wire signed [W-1:0] ina,
  input  wire signed [W-1:0] inb,
  output wire signed [W-1:0] out,
  output wire                overflow
);

  wire signed [2*W-1:0] prod = ina * inb;

  assign out = prod[W+QF-1 : QF];

  assign overflow = ~( (&prod[2*W-1 : W+QF-1]) | (~|prod[2*W-1 : W+QF-1]) );

endmodule

`default_nettype wire
`endif
