// ============================================================================
// pe.sv — YOUR FILE. This is the one thing you write in week 3.
// ----------------------------------------------------------------------------
// The module header, the port list, the internal signals, and the two fxp
// instances are already here. Do not change them, and do not rename anything —
// the provided testbenches bind to these exact names.
//
// Your job is to fill in the always blocks. Write from your OWN week-2 notes
// and timing diagrams, not from memory of any PE you have seen. If your week-2
// spec does not answer a question you hit here, that is a gap in your spec —
// go fix the spec first, then come back. That order is the point of the
// exercise, and it is the order real design work happens in.
//
// RULES (week 3 checks these)
//   - `logic`, never `wire` or `reg`.
//   - `always_comb` for combinational, `always_ff` for sequential. Never mix
//     blocking (=) and nonblocking (<=) assignment styles between them:
//     `=` inside always_comb, `<=` inside always_ff. These two constructs turn
//     a whole class of mistakes into compile errors instead of silent bugs
//     you find three weeks later in a waveform.
//   - Reset is asynchronous, active high: `always_ff @(posedge clk or posedge rst)`.
//   - Every flop you declare must have a defined value out of reset. Every
//     single one. If you skip one, it is X in simulation and it powers up
//     unknown in silicon, and because partial sums chain down a column, one
//     unknown poisons every PE below it.
//
// Build and run:  cd 01-xcelium-rtlsim && ./run
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

    // ---- north: partial sums and weights arrive from the PE above ----
    input  logic signed [DW-1:0] pe_psum_in,
    input  logic signed [DW-1:0] pe_weight_in,
    input  logic                 pe_accept_w_in,

    // ---- west: activations and control arrive from the PE to the left ----
    input  logic signed [DW-1:0] pe_input_in,
    input  logic                 pe_valid_in,
    input  logic                 pe_switch_in,
    input  logic                 pe_enabled,

    // ---- south: to the PE below ----
    output logic signed [DW-1:0] pe_psum_out,
    output logic signed [DW-1:0] pe_weight_out,

    // ---- east: to the PE to the right ----
    output logic signed [DW-1:0] pe_input_out,
    output logic                 pe_valid_out,
    output logic                 pe_switch_out
);

    // ------------------------------------------------------------------
    // Given: the weight storage and the MAC. You wire the behaviour.
    // ------------------------------------------------------------------
    logic signed [DW-1:0] weight_bg;      // background — staged from the north
    logic signed [DW-1:0] weight_active;  // what the multiplier uses THIS cycle

    // TODO(week3): `weight_active` is a value, not necessarily a single flop.
    // Work out from your week-2 diagrams what has to hold it between switches,
    // and declare whatever additional state you need right here.

    logic signed [DW-1:0] mult_out, mac_out;

    fxp_mul #(.QI(QI), .QF(QF)) u_mul (
        .ina(pe_input_in), .inb(weight_active), .out(mult_out), .overflow());

    fxp_add #(.QI(QI), .QF(QF)) u_add (
        .ina(mult_out), .inb(pe_psum_in), .out(mac_out), .overflow());

    // ------------------------------------------------------------------
    // TODO(week3): weight promotion.
    //   Which register does the multiplier read, and when does that change?
    //   Your week-2 timing diagram 2 (preload and switch) is the spec here.
    //   Whether this block is combinational or sequential is YOUR call to
    //   make and to defend — it changes the answer to week-2 question 5a and
    //   it changes where your critical path starts. Decide deliberately.
    // ------------------------------------------------------------------
    always_comb begin
        weight_active = '0;   // <-- replace
    end

    // ------------------------------------------------------------------
    // TODO(week3): weight staging.
    //   When does `weight_bg` capture from `pe_weight_in`?
    //   Does `pe_enabled` affect it? Justify your answer either way — this is
    //   a design decision, not a lookup, and week 11 will ask you about it.
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_bg <= '0;
        end else begin
            // <-- your logic
        end
    end

    // ------------------------------------------------------------------
    // TODO(week3): the streaming datapath.
    //   Three behaviours, in priority order: reset, disabled, running.
    //   Running has to drive all five outputs every cycle. Think about what
    //   each output should be when `pe_valid_in` is LOW — "hold the old value"
    //   and "drive zero" are different designs with different consequences
    //   for the PE below you. Your week-2 question 5b answer decides this.
    // ------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // <-- every output flop, defined
        end else if (!pe_enabled) begin
            // <-- your logic
        end else begin
            // <-- your logic
        end
    end

endmodule

`default_nettype wire
