// ============================================================================
// pe.sv  --  your file. The one thing you write in week 3.
// ----------------------------------------------------------------------------
// The header, port list, internal signals, and the two fxp instances are given.
// Do not change them and do not rename anything; the provided testbenches bind
// to these names.
//
// You fill in the always blocks. Write from your own week-2 notes and timing
// diagrams. If your week-2 spec does not answer a question you hit here, fix
// the spec first, then come back.
//
// Rules week 3 checks:
//   * logic, never wire or reg.
//   * always_comb for combinational, always_ff for sequential. Blocking (=)
//     inside always_comb, nonblocking (<=) inside always_ff, never mixed.
//     These constructs turn a class of mistakes into compile errors.
//   * Reset is asynchronous, active high:
//     always_ff @(posedge clk or posedge rst)
//   * Every flop you declare gets a defined value out of reset. Skip one and
//     it is X in simulation and unknown at power-up in silicon. Partial sums
//     chain down a column, so one unknown propagates to every PE below.
//
// Run it: ./02-xcelium-rtlsim/run
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

module pe #(
    parameter  int QI = 8,               // integer bits, including sign
    parameter  int QF = 8,               // fraction bits
    localparam int DW = QI + QF          // 16
) (
    input  logic                 clk,
    input  logic                 rst,          // asynchronous, active high

    // north: partial sums and weights arrive from the PE above
    input  logic signed [DW-1:0] pe_psum_in,
    input  logic signed [DW-1:0] pe_weight_in,
    input  logic                 pe_accept_w_in,

    // west: activations and control arrive from the PE to the left
    input  logic signed [DW-1:0] pe_input_in,
    input  logic                 pe_valid_in,
    input  logic                 pe_switch_in,
    input  logic                 pe_enabled,

    // south: to the PE below
    output logic signed [DW-1:0] pe_psum_out,
    output logic signed [DW-1:0] pe_weight_out,

    // east: to the PE to the right
    output logic signed [DW-1:0] pe_input_out,
    output logic                 pe_valid_out,
    output logic                 pe_switch_out
);

    // ------------------------------------------------------------------
    // Given: weight storage and the MAC. You write the behaviour.
    // ------------------------------------------------------------------
    logic signed [DW-1:0] weight_bg;      // background, staged from the north
    logic signed [DW-1:0] weight_active;  // what the multiplier reads this cycle

    // TODO(week3): weight_active is a value, not necessarily one flop. Work out
    // from your week-2 diagrams what holds it between switches and declare any
    // additional state here.

    logic signed [DW-1:0] mult_out, mac_out;

    fxp_mul #(.QI(QI), .QF(QF)) u_mul (
        .ina(pe_input_in), .inb(weight_active), .out(mult_out), .overflow());

    fxp_add #(.QI(QI), .QF(QF)) u_add (
        .ina(mult_out), .inb(pe_psum_in), .out(mac_out), .overflow());

    // ------------------------------------------------------------------
    // TODO(week3): weight promotion.
    //   Which register does the multiplier read, and when does that change?
    //   Week-2 timing diagram 2 (preload and switch) is the spec.
    //   Whether this block is combinational or sequential is your call and
    //   you have to defend it. It decides the answer to week-2 question 5a
    //   and it decides where your critical path starts.
    // ------------------------------------------------------------------
    always_comb begin
        weight_active = '0;   // replace
    end

    // ------------------------------------------------------------------
    // TODO(week3): weight staging.
    //   When does weight_bg capture from pe_weight_in?
    //   Does pe_enabled affect it? Justify either answer. Week 11 will ask.
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_bg <= '0;
        end else begin
            // your logic
        end
    end

    // ------------------------------------------------------------------
    // TODO(week3): the streaming datapath.
    //   Three behaviours in priority order: reset, disabled, running.
    //   Running drives all five outputs every cycle. Decide what each output
    //   does when pe_valid_in is low. Holding the previous value and driving
    //   zero are different designs with different consequences for the PE
    //   below you. Your week-2 question 5b answer settles it.
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // every output flop, defined
        end else if (!pe_enabled) begin
            // your logic
        end else begin
            // your logic
        end
    end

endmodule

`default_nettype wire
