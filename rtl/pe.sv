`ifndef PE_V
`define PE_V

`timescale 1ns/1ps

module pe #(
  parameter  QI = 8,
  parameter  QF = 8,
  localparam DW = QI + QF
)(
  input  logic                 clk,
  input  logic                 rst,

  // north
  input  logic signed [DW-1:0] pe_psum_in,
  input  logic signed [DW-1:0] pe_weight_in,
  input  logic                 pe_accept_w_in,

  // west
  input  logic signed [DW-1:0] pe_input_in,
  input  logic                 pe_valid_in,
  input  logic                 pe_switch_in,
  input  logic                 pe_enabled,

  // south
  output logic signed [DW-1:0] pe_psum_out,
  output logic signed [DW-1:0] pe_weight_out,

  // east
  output logic signed [DW-1:0] pe_input_out,
  output logic                 pe_valid_out,
  output logic                 pe_switch_out
);

  // Weight storage

  logic signed [DW-1:0] weight_bg;
  logic signed [DW-1:0] weight_active;

  // MAC

  logic signed [DW-1:0] mult_out;
  logic signed [DW-1:0] mac_out;

  fxp_mul #(QI,QF) u_mul (pe_input_in, weight_active, mult_out, );
  fxp_add #(QI,QF) u_add (mult_out,    pe_psum_in,    mac_out,  );

  // TODO: weight promotion. Which register does the multiplier read?

  always_comb begin
    weight_active = '0;
  end

  // TODO: weight staging. When does weight_bg capture pe_weight_in?

  always_ff @( posedge clk or posedge rst ) begin
    if ( rst )
      weight_bg <= '0;
    else
      weight_bg <= weight_bg;
  end

  // TODO: streaming datapath. Drive all five outputs.

  always_ff @( posedge clk or posedge rst ) begin
    if ( rst ) begin
      pe_psum_out   <= '0;
      pe_weight_out <= '0;
      pe_input_out  <= '0;
      pe_valid_out  <= 1'b0;
      pe_switch_out <= 1'b0;
    end
    else if ( !pe_enabled ) begin
    end
    else begin
    end
  end

endmodule

`endif
