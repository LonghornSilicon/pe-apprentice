//------------------------------------------------------------------------
// pe_txn.sv
//------------------------------------------------------------------------
// One operation on the PE.  In UVM this is a uvm_sequence_item.
//
// A transaction says WHAT should happen, not HOW to make it happen on wires.
// "Load a weight of 3.0, do not switch it in, stream one activation" is a
// transaction. Driving pe_weight_in and pulsing pe_accept_w_in for exactly one
// cycle is the driver's problem, not yours here.
//
// The `rand` keyword means the simulator may pick this field's value for you.
// The `constraint` blocks are how you tell it which values are legal and how
// often you want them. That combination is called constrained random, and it
// is the single biggest idea in this week.

`ifndef PE_TXN_SV
`define PE_TXN_SV

class pe_txn;

  localparam int DW  = 16;
  localparam int ONE = 256;          // 1.0 in Q8.8

  rand bit signed [DW-1:0] weight;
  rand bit signed [DW-1:0] activation;
  rand bit signed [DW-1:0] psum_in;

  rand bit accept_w;
  rand bit switch;
  rand bit valid;
  rand bit enabled;

  // ----------------------------------------------------------------------
  // TODO(week5): write your constraints.
  //
  // With no constraints at all, every field is uniform random across its full
  // range. That sounds thorough and is not: a 16-bit signed weight picked
  // uniformly is almost never a small number, `enabled` is low half the time
  // so the PE barely runs, and interesting combinations like switch and
  // accept_w on the same cycle come up only by luck.
  //
  // Your job is to describe the space you actually want explored. Two kinds
  // of constraint do most of the work:
  //
  //   inside {[a:b]}          restrict a field to a range
  //   dist { 1 := 9, 0 := 1 } pick 1 about nine times as often as 0
  //
  // Questions your constraints have to answer, and your week 4 test plan
  // should already have opinions on all four:
  //
  //   - What range of activations and weights is worth testing? Remember Q8.8
  //     saturates around +-128, so large values tell you about saturation and
  //     small ones tell you about arithmetic.
  //   - How often should `enabled` be low? Rarely enough that the PE runs, but
  //     often enough that you find out what happens when it does.
  //   - How often should `switch` fire? A switch every cycle is not realistic
  //     and a switch that never fires tests nothing.
  //   - Do you want accept_w and switch to land on the same cycle sometimes?
  //     That is week 2 question 5a. If you never generate it, you never test
  //     it, and the coverage report at the end will say so.
  // ----------------------------------------------------------------------

  // constraint c_... { ... }


  // Given. Used in scoreboard failure messages so you can see what was being
  // driven when something went wrong.
  function string show();
    return $sformatf("w=%6d a=%6d p=%6d | acc=%0b sw=%0b vld=%0b en=%0b",
                     weight, activation, psum_in,
                     accept_w, switch, valid, enabled);
  endfunction

endclass

`endif
