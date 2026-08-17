# Step 04: Gate-Level Simulation

**Week 7, second half.** You just synthesized your PE. Now find out whether
synthesis kept it working.

Good ASIC designers never trust their tools. Synthesis rewrote your design from
Verilog into gates. The way to check it did that correctly is to run your tests
again, on the gates.

This is fast-functional simulation: every gate takes zero time, everything still
changes on the clock edge, exactly like RTL simulation. It is a pure question of
function. Wire delay comes later, in step 07.

## 1. Setup

```
% bash
% qsh -q normal.q -now n -V
% bash
% source ~/longhorn-apprentice/pe-apprentice/tools/setup.sh
% cd ~/longhorn-apprentice/pe-apprentice/04-xcelium-ffglsim
```

Step 03 has to have passed first. Check:

```
% ls ../03-genus-synth/post-synth.v
```

If that file is not there, go back and finish step 03.

## 2. Look at the cell models

```
% less $STDCELLS_V
```

This is the behavioural Verilog for every cell in gsclib045. Find `INVX1`.
Notice it is written in Verilog primitives with a `specify` block for delay.
That `specify` block is ignored here and used in step 07.

## 3. Simulate the netlist

```
% xrun -sv -xprop=tmerge -access +rwc \
    +delay_mode_zero \
    $STDCELLS_V \
    ../03-genus-synth/post-synth.v \
    ../02-xcelium-rtlsim/pe_smoke_tb.sv
```

Two differences from step 02:

- it reads the standard-cell library and your synthesized netlist instead of
  your RTL
- `+delay_mode_zero` strips the cell delays out, so this checks function only

Same testbench. Same expected results.

You should see `SMOKE TEST PASSED, 0 errors` again.

If it passed on RTL and fails here, believe it. That is exactly the class of bug
this step exists to catch, and finding one is a good day.

## 4. Look at the waveform

```
% simvision waves.shm &
```

Open the hierarchy and expand the netlist. You are now looking at individual
gates instead of your `always` blocks. Find the flip-flops that hold
`pe_psum_out` and confirm they behave the same as they did in step 02.

## 5. Build the run script

```
% code run
```

```bash
#!/usr/bin/env bash
xrun -sv -xprop=tmerge -access +rwc \
  +delay_mode_zero \
  $STDCELLS_V \
  ../03-genus-synth/post-synth.v \
  ../02-xcelium-rtlsim/pe_smoke_tb.sv
```

```
% chmod +x run
% ./run
```

## Deliverable

Commit `run`. In your week 7 writeup, state whether the netlist passed the same
tests as the RTL, and if it did not, what differed.

## Done means

- The netlist passes the same testbench that passed in step 02
- `./run` reproduces it
