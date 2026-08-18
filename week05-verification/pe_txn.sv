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
  // With no constraints, every field is uniform random across its full range.
  // That sounds thorough and is not: a uniformly random 16-bit weight is
  // almost never a small number, `enabled` is low half the time so the PE
  // barely runs, and a switch landing on the same cycle as a weight load
  // happens only by luck.
  //
  // Constraints are how you describe the space you actually want explored.
  // One is written for you as the pattern.
  // ----------------------------------------------------------------------

  constraint c_values {
    activation inside {[-8*ONE : 8*ONE]};    // +-8.0, small enough not to saturate
    weight     inside {[-8*ONE : 8*ONE]};
    psum_in    inside {[-8*ONE : 8*ONE]};
  }

  // TODO(week5): constrain the four control bits.
  //
  //   dist { 1 := 9, 0 := 1 }   picks 1 about nine times as often as 0
  //
  // Your week 4 stimulus recipe should already answer all four:
  //
  //   valid     how often is the PE actually streaming?
  //   enabled   rarely low enough that the PE runs, often enough that you
  //             find out what happens when it is
  //   accept_w  weights have to be loaded often enough to matter
  //   switch    a switch every cycle is not realistic, never is not a test
  //
  // Every number you write here needs a reason you can say out loud. You
  // will be asked.

  // constraint c_control { ... }


  // Given. Used in scoreboard failure messages so you can see what was being
  // driven when something went wrong.
  function string show();
    return $sformatf("w=%6d a=%6d p=%6d | acc=%0b sw=%0b vld=%0b en=%0b",
                     weight, activation, psum_in,
                     accept_w, switch, valid, enabled);
  endfunction

endclass

`endif
