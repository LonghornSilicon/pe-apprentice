//------------------------------------------------------------------------
// pe_tb.sv
//------------------------------------------------------------------------
// A self-checking testbench, built out of six named components.
//
//   generator   makes transactions            uvm_sequence
//   driver      turns them into pin wiggles   uvm_driver
//   monitor     watches the DUT, drives nothing  uvm_monitor
//   model       says what the answer should be   reference model
//   scoreboard  compares and counts               uvm_scoreboard
//   coverage    says whether you tested enough    covergroup
//
// They talk to each other through mailboxes, never by reaching into each
// other's variables. That separation is the point: you can replace the
// generator without touching the driver, or point the monitor at an interface
// you do not drive at all.
//
// Select which DUT to test:
//   +define+DUT_MINE     your own pe.sv          (default)
//   +define+DUT_VENDOR   rtl/pe_vendor_drop.sv

`timescale 1ns/1ps

`include "pe_txn.sv"
`include "pe_model.sv"

module pe_tb;

  localparam int DW  = 16;
  localparam int ONE = 256;                  // 1.0 in Q8.8

  //----------------------------------------------------------------------
  // Clock, reset, and the wires to the DUT
  //----------------------------------------------------------------------
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst;

  logic signed [DW-1:0] pe_psum_in, pe_weight_in, pe_input_in;
  logic                 pe_accept_w_in, pe_valid_in, pe_switch_in, pe_enabled;
  logic signed [DW-1:0] pe_psum_out, pe_weight_out, pe_input_out;
  logic                 pe_valid_out, pe_switch_out;

`ifdef DUT_VENDOR
  pe_vendor_drop #(8,8) dut (.*);
`else
  pe #(8,8) dut (.*);
`endif

  //----------------------------------------------------------------------
  // The channels between components. A mailbox is a queue you can block on:
  // put() adds, get() waits until something is there. Nothing shares state.
  //----------------------------------------------------------------------
  mailbox #(pe_txn) gen2drv = new();
  mailbox #(pe_txn) drv2scb = new();
  mailbox #(bit signed [DW-1:0]) mon2scb = new();

  pe_model model = new();

  int n_checked = 0;
  int n_errors  = 0;
  int N_TXN     = 500;

  //======================================================================
  // 1. GENERATOR                                          uvm_sequence
  //======================================================================
  // Makes transactions and hands them to the driver. It knows nothing about
  // pins, clocks, or the DUT.
  //
  // TODO(week5): fill in the loop.
  //   - make a new pe_txn
  //   - randomize it, and check that randomization succeeded
  //   - put it in gen2drv
  //
  // `assert (t.randomize())` is the idiom. If your constraints contradict
  // each other the solver cannot find a legal value, randomize() returns 0,
  // and without the assert your testbench silently drives whatever was in the
  // object before. That failure is very hard to find later.
  //======================================================================
  task automatic generator(int n);
    // your code
  endtask

  //======================================================================
  // 2. DRIVER                                               uvm_driver
  //======================================================================
  // Takes one transaction and makes it happen on the wires. It is the only
  // component that drives anything.
  //
  // TODO(week5): fill in the body.
  //   - get a transaction from gen2drv
  //   - wait for @(negedge clk)
  //   - drive every input pin from the transaction's fields
  //   - put the same transaction into drv2scb so the scoreboard knows what
  //     was sent
  //
  // Drive on the negative edge so the values are stable well before the
  // positive edge the DUT samples on. Driving on the same edge the design
  // captures on is a classic way to write a testbench that passes in
  // simulation and fails in silicon.
  //======================================================================
  task automatic driver();
    pe_txn t;
    forever begin
      // your code
      @(negedge clk);
    end
  endtask

  //======================================================================
  // 3. MONITOR                                             uvm_monitor
  //======================================================================
  // Watches pe_psum_out and reports what it saw. It drives nothing. That
  // restriction is what lets a monitor be attached to a bus you do not own,
  // or to two blocks talking to each other, without disturbing them.
  //
  // Given, because the timing offset is fiddly and is not the lesson: the
  // DUT registers its output, so what appears on pe_psum_out one negedge
  // after a transaction was driven is the response to that transaction. The
  // single skip below lines the two streams up.
  //======================================================================
  task automatic monitor();
    @(negedge clk);
    forever begin
      @(negedge clk);
      mon2scb.put(pe_psum_out);
    end
  endtask

  //======================================================================
  // 4. SCOREBOARD                                       uvm_scoreboard
  //======================================================================
  // Pairs what was sent with what came back, asks the model what should have
  // come back, and counts.
  //
  // TODO(week5): fill in the body.
  //   - get the transaction from drv2scb
  //   - get the observed value from mon2scb
  //   - ask the model what it should have been
  //   - compare, count, and on a mismatch print enough to debug from
  //
  // A failure message earns its keep or it does not. "MISMATCH" tells you
  // nothing at 1am. Print the cycle, the transaction (t.show() is there for
  // this), what you expected, and what you got.
  //======================================================================
  task automatic scoreboard();
    pe_txn t;
    bit signed [DW-1:0] observed, expected;
    forever begin
      // your code
      @(negedge clk);
    end
  endtask

  //======================================================================
  // 5. COVERAGE                                             covergroup
  //======================================================================
  // Passing tests tell you nothing about what you did not try. Coverage
  // answers a different question: of the situations worth reaching, which
  // ones did your stimulus actually reach?
  //
  // A coverpoint records the values a signal took. A cross records the
  // combinations two signals took together, which is where the interesting
  // corners live.
  //
  // TODO(week5): add coverpoints and at least two crosses.
  //
  // One cross is not optional. Week 2 question 5a asked what happens when a
  // new weight and a switch arrive on the same cycle. Cross pe_accept_w_in
  // with pe_switch_in and you will find out whether you ever actually
  // generated that case. Reaching 100% passing with 0% on that bin is the
  // most useful thing this week can show you.
  //======================================================================
  covergroup cg @(posedge clk);
    // cp_switch: coverpoint pe_switch_in;
    // ...
    // x_switch_accept: cross cp_switch, cp_accept;
  endgroup

  cg cov = new();

  //======================================================================
  // Run
  //======================================================================
  initial begin
`ifndef NO_SHM
    $shm_open("waves.shm");
    $shm_probe("AS");
`endif

    rst = 1;
    pe_psum_in = '0; pe_weight_in = '0; pe_input_in = '0;
    pe_accept_w_in = 0; pe_valid_in = 0; pe_switch_in = 0; pe_enabled = 1;
    repeat (2) @(negedge clk);
    rst = 0;
    model.reset();

    // Fill the generator's mailbox first so the driver never stalls waiting
    // for stimulus, which keeps the driver and monitor streams in lockstep.
    generator(N_TXN);

    fork
      driver();
      monitor();
      scoreboard();
    join_none

    wait (n_checked == N_TXN);

    $display("");
    $display("=======================================================");
    $display(" checked : %0d", n_checked);
    $display(" errors  : %0d", n_errors);
    $display(" coverage: %0.1f%%", cov.get_coverage());
    $display("=======================================================");
    if (n_errors == 0) $display(" PASS");
    else               $display(" FAIL");
    $display("");
    $finish;
  end

  initial begin
    #2000000;
    $display("[FAIL] timeout. Did every component finish? Is a mailbox empty?");
    $finish;
  end

endmodule
