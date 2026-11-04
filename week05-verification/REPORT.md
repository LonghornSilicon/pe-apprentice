# Week 5 report

## 1. Run on my own PE
Command: ./run   (xrun -sv -access +rwc -covoverwrite -coverage all ../rtl/fxp.sv ../rtl/pe.sv pe_tb.sv)
Xcelium 24.03-s013, seed 1 (also passed with -svseed 2 and -svseed random)

    checked : 500
    errors  : 0
    coverage: 100.0%
    PASS

## 2. Coverage
- Overall functional coverage: 100.0%
- x_switch_accept: 100% (weight load and switch on the same cycle was hit, so week 2 Q5a was tested)
- x_valid_enabled: 100%
- Nothing below 100%. Before the RTL fixes the bench already reached 100% coverage but failed
  checks, which is how the two bugs below were found.

## 3. Bug log

### Bug 1: weight promoted one cycle late (RTL)
- Saw: isolated mismatches on every sw=1 cycle, e.g. #16 exp -724 got 730; the next cycle passed.
  Working back from #16, the model multiplied by ~195 (the background weight), my PE by ~-36 (the old
  foreground weight).
- Thought: my PE switched weights the way my spec said.
- Actually: weight_active was a flop, so on the switch cycle the multiplier still read the old weight.
  My week 2 answer to 5a said which weight gets promoted, but not which cycle it takes effect on.
- Fix: made promotion combinational (weight_active = pe_switch_in ? weight_bg : weight_fg) and added
  a weight_fg register. Chose same-cycle to match pe_array_tb.sv. Updated my spec to say so.
- Where: RTL

### Bug 2: weights moved while pe_enabled was low (RTL)
- Saw: long runs of mismatches with no switch, e.g. #57-#75, where my PE used ~947 while the model
  used ~195. They started after en=0 cycles that had acc=1 or sw=1 (e.g. #306, #433, #455).
- Thought: pe_enabled low only needed to hold the outputs, so I gated the output block but not the
  weight registers.
- Actually: weight_bg still loaded and the switch still happened while disabled. The output held, so
  the wrong weight only showed up once enabled came back.
- Fix: gated both weight registers with pe_enabled (disabled = frozen: no load, no switch).
- Where: RTL

## 4. Vendor PE bug report
Command: ./run-vendor   Result: FAIL

### Defect 1: no double buffering; loaded weight used without a switch, switch ignored
1. Failing transaction:
   [MISMATCH] #13 @160000 w=1831 a=-1383 p=597 | acc=0 sw=0 vld=1 en=1 exp 791 got -457
   Weight 195 was loaded at #11 (acc=1, sw=0). The vendor multiplies by 195 from #13 with no switch,
   while the model still uses the old foreground weight (-36). Same pattern after the loads at #82
   and #85.
2. Waveform: ss1 (130-190 ns: accept_w pulse, no switch, psum_out changes anyway)
3. Spec violated: the PE holds two weights, one in use and one waiting in the background until
   pe_switch_in. A weight that is loaded but not switched in must not change the answer. My 5a answer:
   the switch uses the older weight, and the new weight is used at the next switch.
4. Ask the vendor: load pe_weight_in into a background register only. Have the multiplier read a
   separate foreground register, and copy background to foreground only on pe_switch_in.
- Found by random stimulus alone: yes (first at #11/#13, and after every load).

### Defect 2: pe_enabled low clears the stored weight
1. Failing transaction:
   [MISMATCH] #27 @300000 w=795 a=1081 p=1890 | acc=0 sw=0 vld=1 en=1 exp 2713 got 1890
   en=0 at #26. Afterwards psum_out == psum_in exactly (weight 0) until the next load.
   Repeats after #53, #56, #68 and #72.
2. Waveform: ss2 (280-340 ns: pe_enabled low, then psum_out = psum_in)
3. Spec violated: pe_enabled low stalls the PE. Nothing moves and nothing is lost; the stored
   weights must hold.
4. Ask the vendor: when pe_enabled is low, hold both weight registers. Do not clear or reload them.
- Found by random stimulus alone: yes.

### Coverage of the bench's own blind spots
The scoreboard checks only pe_psum_out, values never reach saturation (max 72.0 against a 128.0
limit), and reset is applied once. Defects in pe_input_out / pe_valid_out / pe_switch_out /
pe_weight_out, in saturation, or in reset values would not be caught by this bench as written.
(If you add the blind-spot checks, put the results here.)

## 5. Half B: UVM
Command: ./run-uvm   Result: checked 522, errors 0, UVM_ERROR : 0
Matches Half A: 0 errors on the same PE and the same model. The UVM count is higher than 500 because
its monitor samples every cycle, including reset and the idle cycles at the end; Half A checks
exactly the 500 transactions. The UVM item's constraints also differ (valid 9:1 vs my 8:2).

Handout bugs I fixed to get it running (reported to a lead):
1. pe_uvm_tb.sv includes pe_model.sv but not pe_txn.sv, which pe_model needs.
   Fix: `include "pe_txn.sv"` before it.
2. pe_scoreboard::write(pe_item it): Xcelium requires the base class's argument name (t).
   Fix: renamed the argument to t and the local pe_txn to tx.
3. The monitor waited two negedges per sample, so it checked every other cycle and paired inputs
   with the next transaction's output (251 errors). Fix: sample inputs and psum_out at the same
   negedge.
4. The driver drove during reset, so the model applied loads the DUT ignored (9 errors at
   80-160 ns). Fix: wait (vif.rst == 0) before get_next_item.

### Answers
1. get_next_item/item_done vs mailbox.get(): my generator filled the mailbox with all 500
   transactions before the driver started and never learned what happened to them. finish_item()
   blocks until the driver calls item_done(), so the sequence knows the item was really applied,
   and the driver can send a response back. That makes stimulus closed-loop: a sequence can react to
   the DUT, e.g. load a weight, wait until it has landed, then switch, or read psum_out and choose
   operands that push toward saturation. A mailbox can only replay a list decided in advance.

2. +define+DUT_VENDOR vs a factory override: a define is fixed at compile time, so every variant
   needs its own compile and ifdefs in shared files. With 200 tests that means hundreds of builds,
   or common code edited for each new test, risking all the others. A factory override is chosen at
   run time (set_type_override in a test, or +uvm_set_type_override). One compiled image runs every
   test, and a new test touches only its own file. That is why items are built with
   type_id::create() rather than new().

3. uvm_config_db vs being in the same module: my components saw the DUT signals only because they
   were all tasks inside pe_tb. A real driver is a class several levels down
   (test > env > agent > driver), often written by other teams, and classes cannot see module
   signals. Without the config DB, every layer would need an argument whose only job is to pass the
   interface down. With it, the top publishes the handle once and the driver fetches it by name in
   build_phase. Nothing in between changes, and the driver can be reused under a different
   hierarchy.
