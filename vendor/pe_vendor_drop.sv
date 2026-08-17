// ============================================================================
// pe_vendor_drop.sv — third-party PE delivery. STUDENT-FACING (week 5 DUT).
// ----------------------------------------------------------------------------
// Read this header. Then do not read the body until your testbench passes on
// your own PE. The whole point of week 5 is that your testbench finds what is
// wrong in here WITHOUT you having read it first. Reading ahead does not make
// you faster; it makes the exercise worthless.
//
// ----------------------------------------------------------------------------
// WHAT THIS IS
// ----------------------------------------------------------------------------
// A PE implementing the same interface you were given in week 2, written by
// someone else. In industry this is routine: a block arrives from another
// team, an acquisition, or an IP vendor, with a datasheet and no warranty.
// You do not get to assume it works. You get to PROVE whether it works, using
// the testbench you built in week 4 and 5, against a spec you understand
// better than the person who wrote the code did.
//
// This one has real defects. They are the same defect classes present today in
// the weight-stationary PE of tiny-tpu, a well-regarded 1.3k-star open-source
// TPU (https://github.com/tiny-tpu-v2/tiny-tpu, tiny-tpu-hardened/rtl/pe.v).
// That module is unlicensed upstream so nothing here is copied from it — this
// is an independent implementation that reproduces the same defects. Go read
// the original after week 5 and confirm for yourself that they are there. The
// lesson is not "this file is bad." The lesson is that popular, working,
// widely-forked RTL ships with bugs of exactly this kind, and the only thing
// standing between those bugs and silicon is a verification engineer who
// tested the spec instead of testing the code.
//
// ----------------------------------------------------------------------------
// YOUR TASK (week 5)
// ----------------------------------------------------------------------------
// Point your week-5 testbench at this module instead of your own. Your
// scoreboard should fail. For each failure produce: the test case that caught
// it, the waveform showing it, the sentence of the week-2 spec it violates,
// and what you would tell the vendor to change.
//
// Grading is binary and it is not about elegance: a passing week 5 is a
// testbench that catches every defect in here. If yours catches none, your
// testbench is the thing that is broken, not this file.
//
// Style note: this arrives in Verilog-2001 (`reg`/`wire`, `always @(*)`),
// not the SystemVerilog you were told to write. That is also realistic, and
// it is not one of the defects.
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

module pe_vendor_drop #(
    parameter QI = 8,
    parameter QF = 8
) (
    input  wire        clk,
    input  wire        rst,

    // North wires of PE
    input  wire signed [15:0] pe_psum_in,
    input  wire signed [15:0] pe_weight_in,
    input  wire               pe_accept_w_in,

    // West wires of PE
    input  wire signed [15:0] pe_input_in,
    input  wire               pe_valid_in,
    input  wire               pe_switch_in,
    input  wire               pe_enabled,

    // South wires of the PE
    output reg  signed [15:0] pe_psum_out,
    output reg  signed [15:0] pe_weight_out,

    // East wires of the PE
    output reg  signed [15:0] pe_input_out,
    output reg                pe_valid_out,
    output reg                pe_switch_out
);

    wire signed [15:0] mult_out;
    wire signed [15:0] mac_out;
    reg  signed [15:0] weight_reg_active;    // foreground register
    reg  signed [15:0] weight_reg_inactive;  // background register

    fxp_mul #(.QI(QI), .QF(QF)) mult (
        .ina(pe_input_in), .inb(weight_reg_active), .out(mult_out), .overflow());

    fxp_add #(.QI(QI), .QF(QF)) adder (
        .ina(mult_out), .inb(pe_psum_in), .out(mac_out), .overflow());

    // Only the switch flag is combinational (active register copies inactive
    // register on the same clock cycle that switch flag is set). That means
    // inputs from the left side of the PE can load in on the same clock cycle
    // that the switch flag is set.
    always @(*) begin
        if (pe_switch_in) begin
            weight_reg_active = weight_reg_inactive;
        end else begin
            weight_reg_active = weight_reg_inactive; // maintain value
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pe_input_out        <= 16'b0;
            weight_reg_inactive <= 16'b0;
            pe_valid_out        <= 1'b0;
            pe_weight_out       <= 16'b0;
            pe_switch_out       <= 1'b0;
        end else if (!pe_enabled) begin
            pe_input_out        <= 16'b0;
            weight_reg_inactive <= 16'b0;
            pe_valid_out        <= 1'b0;
            pe_weight_out       <= 16'b0;
            pe_switch_out       <= 1'b0;
        end else begin
            pe_switch_out <= pe_switch_in;

            // Weight register updates - only on clock edges
            if (pe_accept_w_in) begin
                weight_reg_inactive <= pe_weight_in;
                pe_weight_out       <= pe_weight_in;
            end else begin
                pe_weight_out       <= 16'b0;
            end

            if (pe_valid_in) begin
                pe_input_out <= pe_input_in;
                pe_psum_out  <= mac_out;
                pe_valid_out <= 1'b1;
            end else begin
                pe_input_out <= 16'b0;
                pe_psum_out  <= 16'b0;
                pe_valid_out <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
