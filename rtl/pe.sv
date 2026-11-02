`ifndef PE_V
`define PE_V

`timescale 1ns/1ps

module pe #(
    parameter QI = 8,
    parameter QF = 8,
    localparam DW = QI + QF
)(
    input  logic                       clk,
    input  logic                       rst,

    // North inputs
    input  logic signed [DW-1:0]       pe_psum_in,
    input  logic signed [DW-1:0]       pe_weight_in,
    input  logic                       pe_accept_w_in,

    // West inputs
    input  logic signed [DW-1:0]       pe_input_in,
    input  logic                       pe_valid_in,
    input  logic                       pe_switch_in,
    input  logic                       pe_enabled,

    // South outputs
    output logic signed [DW-1:0]       pe_psum_out,
    output logic signed [DW-1:0]       pe_weight_out,

    // East outputs
    output logic signed [DW-1:0]       pe_input_out,
    output logic                       pe_valid_out,
    output logic                       pe_switch_out
);

    // Two-bank weights: staged background, active foreground.
    logic signed [DW-1:0] weight_bg;
    logic signed [DW-1:0] weight_active;

    logic signed [DW-1:0] mult_out;
    logic signed [DW-1:0] mac_out;

    fxp_mul #(QI, QF) u_mul (pe_input_in, weight_active, mult_out, );
    fxp_add #(QI, QF) u_add (mult_out, pe_psum_in, mac_out, );

    // Nonblocking assignments ensure this cycle's MAC uses the OLD
    // active weight, and a switch uses the OLD background weight.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_active <= '0;
            weight_bg <= '0;
        end else if (pe_enabled) begin
            if (pe_switch_in)
                weight_active <= weight_bg;
            if (pe_accept_w_in)
                weight_bg <= pe_weight_in;
        end
    end

    // Registered datapath: a disabled PE holds its existing outputs.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pe_psum_out   <= '0;
            pe_weight_out <= '0;
            pe_input_out  <= '0;
            pe_valid_out  <= 1'b0;
            pe_switch_out <= 1'b0;
        end else if (pe_enabled) begin
            pe_weight_out <= pe_weight_in;
            pe_input_out  <= pe_input_in;
            pe_valid_out  <= pe_valid_in;
            pe_switch_out <= pe_switch_in;
            pe_psum_out   <= pe_valid_in ? mac_out : '0;
        end
    end
endmodule

`endif
