//========================================================================
// pe_uvm_tb.sv
//------------------------------------------------------------------------
// The SAME testbench you built in Half A, written in real UVM.
//
// A production UVM environment is eight or nine separate files plus a
// package. This is all of it in one file so you can read it top to bottom in
// one sitting. Nothing here is simplified or faked; it is what a real
// environment looks like, just smaller and in one place.
//
// You write ONE thing in this file: the body of pe_seq. Everything else is
// given, and you should read all of it.
//
// Run it:  ./run-uvm
//========================================================================

`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "pe_model.sv"      // your reference model from Half A, unchanged

//------------------------------------------------------------------------
// The interface. Half A drove loose signals from inside the testbench
// module. UVM classes are not inside any module, so they cannot see module
// signals at all. An interface bundles the pins into one object that can be
// passed to a class as a handle.
//------------------------------------------------------------------------
interface pe_if (input logic clk);
  logic               rst;
  logic signed [15:0] pe_psum_in, pe_weight_in, pe_input_in;
  logic               pe_accept_w_in, pe_valid_in, pe_switch_in, pe_enabled;
  logic signed [15:0] pe_psum_out, pe_weight_out, pe_input_out;
  logic               pe_valid_out, pe_switch_out;
endinterface

//------------------------------------------------------------------------
// 1. TRANSACTION            your pe_txn  ->  extends uvm_sequence_item
//------------------------------------------------------------------------
// Same fields, same constraints. The differences are all bookkeeping:
//   `uvm_object_utils registers this type with the factory, which is what
//   lets a test swap in a different transaction type without editing this
//   file. It also generates print, copy, and compare for free.
//------------------------------------------------------------------------
class pe_item extends uvm_sequence_item;
  `uvm_object_utils(pe_item)

  rand bit signed [15:0] weight, activation, psum_in;
  rand bit accept_w, switch, valid, enabled;

  // observed on the way back from the monitor
  bit signed [15:0] psum_out;

  localparam int ONE = 256;

  constraint c_values {
    activation inside {[-8*ONE : 8*ONE]};
    weight     inside {[-8*ONE : 8*ONE]};
    psum_in    inside {[-8*ONE : 8*ONE]};
  }
  constraint c_control {
    valid    dist { 1 := 9, 0 := 1 };
    enabled  dist { 1 := 9, 0 := 1 };
    accept_w dist { 1 := 3, 0 := 7 };
    switch   dist { 1 := 2, 0 := 8 };
  }

  function new(string name = "pe_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("w=%0d a=%0d p=%0d acc=%0b sw=%0b vld=%0b en=%0b",
                     weight, activation, psum_in,
                     accept_w, switch, valid, enabled);
  endfunction
endclass

//------------------------------------------------------------------------
// 2. SEQUENCE               your generator  ->  extends uvm_sequence
//------------------------------------------------------------------------
// A sequence produces transactions and hands them to a sequencer, which
// hands them to the driver. Your generator put objects straight into a
// mailbox; this adds one layer so that several sequences can share one
// driver, and so a test can pick which sequence to run without either the
// sequence or the driver knowing about the other.
//
// start_item(it) blocks until the driver is ready for another transaction.
// finish_item(it) blocks until the driver says it is done with this one.
// That handshake is what your mailbox was doing implicitly.
//------------------------------------------------------------------------
class pe_seq extends uvm_sequence #(pe_item);
  `uvm_object_utils(pe_seq)

  int n = 500;

  function new(string name = "pe_seq");
    super.new(name);
  endfunction

  // ------------------------------------------------------------------
  // TODO(week5): write the body.
  //
  // Repeat n times:
  //   pe_item it = pe_item::type_id::create("it");
  //   start_item(it);
  //   assert (it.randomize());
  //   finish_item(it);
  //
  // Note `type_id::create` rather than `new`. That is the factory. It looks
  // up which class to actually build, so a test can substitute a different
  // item type without this line changing. `new` would hardcode the type and
  // give up that flexibility.
  // ------------------------------------------------------------------
  task body();
    // your code
  endtask
endclass

//------------------------------------------------------------------------
// 3. DRIVER                 your driver task  ->  extends uvm_driver
//------------------------------------------------------------------------
// Same job: take a transaction, wiggle pins. Two differences worth seeing.
//
// It gets the interface handle out of uvm_config_db instead of being in the
// same module as the signals. That is how a component buried several levels
// deep in a hierarchy gets a handle without every layer above passing it
// down by hand.
//
// get_next_item / item_done replace your mailbox.get(). The extra half of
// that handshake lets the sequence know when the driver has finished, which
// is what makes a sequence able to react to the DUT.
//------------------------------------------------------------------------
class pe_driver extends uvm_driver #(pe_item);
  `uvm_component_utils(pe_driver)
  virtual pe_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "no virtual interface in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    pe_item it;
    forever begin
      seq_item_port.get_next_item(it);
      @(negedge vif.clk);
      vif.pe_weight_in   <= it.weight;
      vif.pe_input_in    <= it.activation;
      vif.pe_psum_in     <= it.psum_in;
      vif.pe_accept_w_in <= it.accept_w;
      vif.pe_switch_in   <= it.switch;
      vif.pe_valid_in    <= it.valid;
      vif.pe_enabled     <= it.enabled;
      seq_item_port.item_done();
    end
  endtask
endclass

//------------------------------------------------------------------------
// 4. MONITOR                your monitor task  ->  extends uvm_monitor
//------------------------------------------------------------------------
// Still drives nothing. It publishes what it saw on an analysis port, which
// is a broadcast: any number of subscribers can listen and the monitor does
// not know or care who they are. Your monitor wrote into one specific
// mailbox and therefore knew exactly who was listening.
//------------------------------------------------------------------------
class pe_monitor extends uvm_monitor;
  `uvm_component_utils(pe_monitor)
  virtual pe_if vif;
  uvm_analysis_port #(pe_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "no virtual interface in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    pe_item it;
    forever begin
      @(negedge vif.clk);
      it = pe_item::type_id::create("it");
      it.weight     = vif.pe_weight_in;
      it.activation = vif.pe_input_in;
      it.psum_in    = vif.pe_psum_in;
      it.accept_w   = vif.pe_accept_w_in;
      it.switch     = vif.pe_switch_in;
      it.valid      = vif.pe_valid_in;
      it.enabled    = vif.pe_enabled;
      @(negedge vif.clk);          // the response lands one cycle later
      it.psum_out   = vif.pe_psum_out;
      ap.write(it);
    end
  endtask
endclass

//------------------------------------------------------------------------
// 5. SCOREBOARD             your scoreboard  ->  extends uvm_subscriber
//------------------------------------------------------------------------
// Note what did NOT change: pe_model. Your reference model drops in here
// unmodified. That is the point. The model is design knowledge and it is
// worth keeping; the framework around it is plumbing and it is replaceable.
//------------------------------------------------------------------------
class pe_scoreboard extends uvm_subscriber #(pe_item);
  `uvm_component_utils(pe_scoreboard)
  pe_model model;
  int n_checked = 0, n_errors = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    model = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model.reset();
  endfunction

  function void write(pe_item it);
    bit signed [15:0] expected;
    pe_txn t = new();
    t.weight = it.weight; t.activation = it.activation; t.psum_in = it.psum_in;
    t.accept_w = it.accept_w; t.switch = it.switch;
    t.valid = it.valid; t.enabled = it.enabled;

    expected = model.step(t);
    n_checked++;
    if (it.psum_out !== expected) begin
      n_errors++;
      `uvm_error("SCB", $sformatf("#%0d %s exp=%0d got=%0d",
                 n_checked, it.convert2string(), expected, it.psum_out))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("checked %0d, errors %0d", n_checked, n_errors),
              UVM_NONE)
  endfunction
endclass

//------------------------------------------------------------------------
// 6. ENV                    (Half A had no equivalent)  extends uvm_env
//------------------------------------------------------------------------
// A container that builds the components and wires them together. In Half A
// you did this by declaring everything in one module and calling tasks in a
// fork. Here it is explicit and, more importantly, reusable: this whole env
// can be instantiated inside a bigger env when the PE becomes one block in a
// larger chip.
//
// Notice build_phase and connect_phase are separate. UVM builds every
// component in the whole hierarchy first, then connects them. That ordering
// is fixed and automatic, which is what stops components written by
// different people from racing each other at time zero.
//------------------------------------------------------------------------
class pe_env extends uvm_env;
  `uvm_component_utils(pe_env)

  pe_driver                drv;
  uvm_sequencer #(pe_item) sqr;
  pe_monitor               mon;
  pe_scoreboard            scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = pe_driver::type_id::create("drv", this);
    sqr = uvm_sequencer#(pe_item)::type_id::create("sqr", this);
    mon = pe_monitor::type_id::create("mon", this);
    scb = pe_scoreboard::type_id::create("scb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap.connect(scb.analysis_export);
  endfunction
endclass

//------------------------------------------------------------------------
// 7. TEST                   your initial block  ->  extends uvm_test
//------------------------------------------------------------------------
// The test picks which sequence to run. Swapping tests swaps stimulus
// without touching a single other file, which is the whole reason for the
// layering above.
//
// raise_objection and drop_objection are how a component says "do not end
// the simulation yet, I am still working". Without them run_phase would end
// immediately.
//------------------------------------------------------------------------
class pe_test extends uvm_test;
  `uvm_component_utils(pe_test)
  pe_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pe_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    pe_seq seq;
    phase.raise_objection(this);
    seq = pe_seq::type_id::create("seq");
    seq.start(env.sqr);
    #200;
    phase.drop_objection(this);
  endtask
endclass

//------------------------------------------------------------------------
// 8. TOP
//------------------------------------------------------------------------
module pe_uvm_tb;
  logic clk = 0;
  always #5 clk = ~clk;

  pe_if intf (clk);

  pe #(8,8) dut (
    .clk            (clk),
    .rst            (intf.rst),
    .pe_psum_in     (intf.pe_psum_in),
    .pe_weight_in   (intf.pe_weight_in),
    .pe_accept_w_in (intf.pe_accept_w_in),
    .pe_input_in    (intf.pe_input_in),
    .pe_valid_in    (intf.pe_valid_in),
    .pe_switch_in   (intf.pe_switch_in),
    .pe_enabled     (intf.pe_enabled),
    .pe_psum_out    (intf.pe_psum_out),
    .pe_weight_out  (intf.pe_weight_out),
    .pe_input_out   (intf.pe_input_out),
    .pe_valid_out   (intf.pe_valid_out),
    .pe_switch_out  (intf.pe_switch_out)
  );

  initial begin
    intf.rst = 1;
    intf.pe_psum_in = '0; intf.pe_weight_in = '0; intf.pe_input_in = '0;
    intf.pe_accept_w_in = 0; intf.pe_valid_in = 0;
    intf.pe_switch_in = 0; intf.pe_enabled = 1;
    repeat (2) @(negedge clk);
    intf.rst = 0;
  end

  initial begin
    // Hand the interface to every component that asks for "vif".
    uvm_config_db#(virtual pe_if)::set(null, "*", "vif", intf);
    run_test("pe_test");
  end
endmodule
