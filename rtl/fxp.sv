// ============================================================================
// fxp.sv — signed fixed-point add and multiply, Q(QI).(QF)
// ----------------------------------------------------------------------------
// Given to you. You do not write or modify this file; you instantiate it.
//
// FIXED POINT IN ONE PARAGRAPH. A Q(QI).(QF) number is a plain (QI+QF)-bit
// two's-complement integer that everyone has agreed to read as if a binary
// point sits QF bits from the right. Q8.8 in 16 bits therefore covers
// -128.0 .. +127.99609375 in steps of 1/256. The hardware is ordinary integer
// hardware — the binary point exists only in the contract between modules.
// That contract is why these two modules exist: an integer adder is already
// correct for fixed point, but an integer multiplier is NOT, because
// Q8.8 x Q8.8 lands in Q16.16 and has to be re-aligned.
//
// THE TWO THINGS THAT COST YOU BITS, both surfaced on `overflow`:
//   fxp_add  can produce a value too large to represent. It SATURATES (clamps
//            to the largest representable magnitude) rather than wrapping,
//            because a clamped result is wrong by a little and a wrapped
//            result is wrong by everything (+127.99 + 0.01 would become -128).
//   fxp_mul  keeps the middle slice of the full product. The low QF bits are
//            TRUNCATED (precision you silently lose every multiply) and the
//            high QI bits are dropped (range you silently lose when the true
//            product does not fit). `overflow` tells you the second happened.
//
// Both modules report `overflow`. Whether anyone LISTENS to it is a design
// decision made by the module that instantiates them — see rtl/pe.sv.
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

// ---------------------------------------------------------------------------
// Signed saturating add.  Q(QI).(QF) + Q(QI).(QF) -> Q(QI).(QF)
// ---------------------------------------------------------------------------
module fxp_add #(
    parameter  int QI = 8,               // integer bits, including the sign bit
    parameter  int QF = 8,               // fraction bits
    localparam int W  = QI + QF
) (
    input  wire signed [W-1:0] ina,
    input  wire signed [W-1:0] inb,
    output wire signed [W-1:0] out,
    output wire                overflow
);
    // One guard bit. Both operands sign-extend into W+1 bits, so `sum` is the
    // exact mathematical result and cannot itself overflow.
    wire signed [W:0] sum = ina + inb;

    // The sum overflowed W bits exactly when its top two bits disagree —
    // i.e. bit W is no longer a pure sign extension of bit W-1.
    assign overflow = (sum[W] != sum[W-1]);

    assign out = overflow
               ? (sum[W] ? {1'b1, {(W-1){1'b0}}}    // clamp to most negative
                         : {1'b0, {(W-1){1'b1}}})   // clamp to most positive
               : sum[W-1:0];
endmodule

// ---------------------------------------------------------------------------
// Signed multiply with re-alignment.  Q(QI).(QF) x Q(QI).(QF) -> Q(QI).(QF)
// ---------------------------------------------------------------------------
module fxp_mul #(
    parameter  int QI = 8,
    parameter  int QF = 8,
    localparam int W  = QI + QF
) (
    input  wire signed [W-1:0] ina,
    input  wire signed [W-1:0] inb,
    output wire signed [W-1:0] out,
    output wire                overflow
);
    // The full product of two Q(QI).(QF) values is Q(2*QI).(2*QF) in 2W bits.
    wire signed [2*W-1:0] prod = ina * inb;

    // Re-align to Q(QI).(QF): keep W bits starting at bit QF. Bit QF carries
    // weight 2^(QF - 2*QF) = 2^-QF, so the slice is Q(W-QF).(QF) = Q(QI).(QF).
    // Dropping bits [QF-1:0] is the truncation; it always happens and is not
    // an error, just lost precision.
    assign out = prod[W+QF-1 : QF];

    // Range loss is different and IS an error. The kept slice's own sign bit
    // is prod[W+QF-1]; every bit above it must be an exact sign extension of
    // it, or the true product did not fit and `out` is not the right number.
    assign overflow = ~( (&prod[2*W-1 : W+QF-1]) | (~|prod[2*W-1 : W+QF-1]) );
endmodule

`default_nettype wire
