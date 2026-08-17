//------------------------------------------------------------------------
// pe_vendor_drop.sv
//------------------------------------------------------------------------
// A PE written by someone else, implementing the same interface you were
// given in week 2. It has bugs in it.
//
// Do not read past this header until your own testbench passes on your own
// PE. Week 5 asks whether your testbench can find the bugs. Reading the code
// first answers the question for you and wastes the exercise.

`ifndef PE_VENDOR_DROP_V
`define PE_VENDOR_DROP_V

`timescale 1ns/1ps
`default_nettype none

module pe_vendor_drop #(
  parameter QI = 8,
  parameter QF = 8
)(
  input  wire        clk,
  input  wire        rst,

  input  wire signed [15:0] pe_psum_in,
  input  wire signed [15:0] pe_weight_in,
  input  wire               pe_accept_w_in,

  input  wire signed [15:0] pe_input_in,
  input  wire               pe_valid_in,
  input  wire               pe_switch_in,
  input  wire               pe_enabled,

  output reg  signed [15:0] pe_psum_out,
  output reg  signed [15:0] pe_weight_out,

  output reg  signed [15:0] pe_input_out,
  output reg                pe_valid_out,
  output reg                pe_switch_out
);

  wire signed [15:0] mult_out;
  wire signed [15:0] mac_out;
  reg  signed [15:0] weight_reg_active;
  reg  signed [15:0] weight_reg_inactive;

  fxp_mul #(QI,QF) mult  (pe_input_in, weight_reg_active, mult_out, );
  fxp_add #(QI,QF) adder (mult_out,    pe_psum_in,        mac_out,  );

  always @(*) begin
    if ( pe_switch_in )
      weight_reg_active = weight_reg_inactive;
    else
      weight_reg_active = weight_reg_inactive;
  end

  always @( posedge clk or posedge rst ) begin
    if ( rst ) begin
      pe_input_out        <= 16'b0;
      weight_reg_inactive <= 16'b0;
      pe_valid_out        <= 1'b0;
      pe_weight_out       <= 16'b0;
      pe_switch_out       <= 1'b0;
    end
    else if ( !pe_enabled ) begin
      pe_input_out        <= 16'b0;
      weight_reg_inactive <= 16'b0;
      pe_valid_out        <= 1'b0;
      pe_weight_out       <= 16'b0;
      pe_switch_out       <= 1'b0;
    end
    else begin
      pe_switch_out <= pe_switch_in;

      if ( pe_accept_w_in ) begin
        weight_reg_inactive <= pe_weight_in;
        pe_weight_out       <= pe_weight_in;
      end
      else begin
        pe_weight_out       <= 16'b0;
      end

      if ( pe_valid_in ) begin
        pe_input_out <= pe_input_in;
        pe_psum_out  <= mac_out;
        pe_valid_out <= 1'b1;
      end
      else begin
        pe_input_out <= 16'b0;
        pe_psum_out  <= 16'b0;
        pe_valid_out <= 1'b0;
      end
    end
  end

endmodule

`default_nettype wire
`endif
