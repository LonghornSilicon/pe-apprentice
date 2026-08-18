//------------------------------------------------------------------------
// pe_model.sv
//------------------------------------------------------------------------
// The reference model: what the PE SHOULD output, computed in software.
//
// One rule matters more than everything else in this file.
//
//   Write this from your week 2 specification. Do not write it by reading
//   your own RTL.
//
// If the model and the design come from the same understanding, they will
// agree with each other and both can be wrong. A testbench built that way
// passes cleanly and proves nothing. The whole value of a reference model is
// that it is an INDEPENDENT statement of what the answer is.
//
// Real teams go further and write the model in a different language for
// exactly this reason. Lambda's reference models are Python. We keep it in
// SystemVerilog here so the week stays self-contained, which means the
// discipline has to come from you.

`ifndef PE_MODEL_SV
`define PE_MODEL_SV

class pe_model;

  localparam int DW = 16;
  localparam int QI = 8;
  localparam int QF = 8;

  // The state your model has to carry between cycles. Exactly the state the
  // real PE carries.
  bit signed [DW-1:0] weight_bg;    // background, loaded but not in use
  bit signed [DW-1:0] weight_fg;    // foreground, what the multiplier reads

  // ----------------------------------------------------------------------
  // Given: Q8.8 arithmetic that matches rtl/fxp.sv exactly.
  // Getting saturation and truncation to agree bit for bit is fiddly and is
  // not what this week is about, so it is done for you. Read them anyway;
  // knowing that the multiply truncates and the add saturates will explain a
  // mismatch one day.
  // ----------------------------------------------------------------------

  function automatic bit signed [DW-1:0] q_mul(bit signed [DW-1:0] a,
                                               bit signed [DW-1:0] b);
    bit signed [2*DW-1:0] prod = a * b;
    return prod[DW+QF-1 : QF];                      // truncates the low QF bits
  endfunction

  function automatic bit signed [DW-1:0] q_add(bit signed [DW-1:0] a,
                                               bit signed [DW-1:0] b);
    bit signed [DW:0] sum = a + b;                  // one guard bit
    if (sum[DW] != sum[DW-1])                       // overflowed, so saturate
      return sum[DW] ? {1'b1, {(DW-1){1'b0}}} : {1'b0, {(DW-1){1'b1}}};
    return sum[DW-1:0];
  endfunction

  // Given. The state of a PE the cycle after reset releases.
  function void reset();
    weight_bg = '0;
    weight_fg = '0;
  endfunction

  // ----------------------------------------------------------------------
  // TODO(week5): advance the model one cycle and return what pe_psum_out
  // should be after this transaction is applied.
  //
  // Work through it in the order the hardware does:
  //
  //   1. Which weight does the multiplier read this cycle? Your answer to
  //      week 2 question 5a decides this, and it is the part people get
  //      wrong. Look at your own pe.sv only to check that you and it made
  //      the same choice, not to copy the logic.
  //   2. If accept_w is high, what changes, and does it affect this cycle's
  //      answer or the next one?
  //   3. If enabled is low, what happens to the output, and what happens to
  //      the two stored weights?
  //   4. If valid is low, what is pe_psum_out?
  //   5. Otherwise: q_add(q_mul(activation, foreground weight), psum_in).
  //
  // Careful with ordering. In hardware everything happens at once on the
  // clock edge, so a register that gets written this cycle is not readable
  // until the next one. Software runs top to bottom, so if you update
  // weight_bg before you use it you have modelled a PE that does not exist.
  // ----------------------------------------------------------------------
  function bit signed [DW-1:0] step(pe_txn t);
    // your code
    return '0;
  endfunction

endclass

`endif
