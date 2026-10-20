# Challenge: the 8×8 array

For anyone who finished week 10 and wants the next size up. Not graded. The
reward is that you leave having built the thing the PE exists for.

`rtl/pe_array.sv` wires N×N of your PE into a weight-stationary systolic
array: activations flow west to east, partial sums north to south, weights
load from the north and shift down one PE per cycle. `N = 2` is the small
stretch; the challenge is `N = 8`, 64 PEs, 128-bit buses on every edge.

The array has no controller. `rtl/pe_array_tb.sv` is the controller: it skews
row `r` by `r` cycles on the way in, de-skews column `c` by `c` cycles on the
way out, and runs two matrix products back to back with a weight swap in
between, loading the second weight set while the first product is still
streaming. That swap is the whole reason the PE has two weight registers.

## 1. Simulate

```bash
cd ~/pe-apprentice/week03-rtl
xrun -sv -access +rwc +define+N=8 \
    ../rtl/fxp.sv ../rtl/pe.sv ../rtl/pe_array.sv ../rtl/pe_array_tb.sv
```

Expected: `384 results checked, 0 errors`, `ARRAY TEST PASSED`. If your PE
passes week 5 it passes this. If it does not, the array found something 500
random transactions on one PE did not; work out what.

## 2. Derive the two inequalities

Open the testbench and read the schedule comment. It states two constraints
on `L`, the cycle the second weight load starts, and asserts them. Derive both
yourself from the PE's behaviour, on paper, then answer:

- With a shift-down load and a broadcast `pe_accept_w_in`, what is the
  shortest batch that allows a stall-free weight swap, as a function of N?
- What one change to the PE or the array would bring that bound down to
  2N − 1? What does it cost?

Set `L` one cycle too early and run it. Read which results break and why.

## 3. Synthesize

Week 7's flow with one more file and a parameter:

```tcl
read_hdl -sv ../rtl/fxp.sv ../rtl/pe.sv ../rtl/pe_array.sv
elaborate pe_array -parameters {{N 8}}
```

Record cell count, area and worst slack next to your single-PE numbers. Is the
array 64 PEs' worth of area? Is its critical path the same path? Look at the
first `module` line of `post-synth.v`: Genus names a parameterized top after
its parameters, so the module is `pe_array_N8`, not `pe_array`, and that is
the name `read_netlist -top` needs next.

## 4. Place and route

Week 9's flow with four changes: the top is `pe_array_N8`, the floorplan is
bigger, the pins are buses of 128, and the pin placement now matters more
than anything else you type. Each 128-bit edge bus is 8 groups of 16; keep the
groups in row and column order so row `r`'s activations enter at the height
of PE row `r`. Two tracks between pins. Layer by edge direction, as in week 9.

Then compare to your single PE: density, wire length, worst slack, where the
critical path runs now, and how long the run took. If the critical path now
starts at a `switch_in` pin and the slack is several nanoseconds worse than
the PE's, look at where that pin is and where PE(0,0) was placed. The fix is
in the floorplan, not the logic.

## Turn in, if you want it looked at

The passing test output, your derivation page, and the synthesis and PnR
numbers side by side with your single-PE numbers.
