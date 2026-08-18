# Week 7: Synthesis

**Goal:** Turn your RTL into gates, find out whether your week 6 prediction was
right, then check that synthesis did not break your design.

Two halves. Part A is Genus. Part B is simulating what Genus produced.

## 1. Get on the chamber

```
% bash
% qsh -q normal.q -now n -V
% bash
% source ~/pe-apprentice/setup.sh
% cd ~/pe-apprentice/week07-synthesis
```

---

# Part A: Synthesis

Synthesis reads your Verilog and picks actual cells out of the gsclib045
library to build it. Those cells have measured delay and area, which is where
every number below comes from.

You run Genus by hand first. That is on purpose.

## 2. Set your clock period

```
% less constraints.sdc
```

The period in there is a placeholder. Replace it with the number you argued for
in week 6.

## 3. Start Genus

```
% genus
```

You get a `genus:/>` prompt. Everything below is one command at a time.

## 4. Load the library

```
genus:/> set_db library $env(LIB_SS)
```

`LIB_SS` is the slow corner: 0.9 V, 125 C. Slow silicon is when data arrives
latest, which is when setup timing is hardest. That is the corner you check
setup against.

## 5. Read and elaborate

```
genus:/> read_hdl -sv ../rtl/fxp.sv ../rtl/pe.sv
genus:/> elaborate pe
```

`read_hdl` parses. `elaborate` resolves parameters, builds the hierarchy, and
works out which signals become flip-flops.

Read what elaborate prints. If it says it inferred a **latch**, stop and fix your
RTL. A latch you did not ask for means a combinational block does not assign
something on every path.

## 6. Apply your constraints

```
genus:/> read_sdc constraints.sdc
```

## 7. Synthesize, in three stages

```
genus:/> syn_generic
genus:/> report_timing -nworst 1
genus:/> syn_map
genus:/> report_timing -nworst 1
genus:/> syn_opt
genus:/> report_timing -nworst 1
```

Genus splits this into three instead of hiding it behind one command:

- `syn_generic` turns your RTL into generic boolean logic. No library cells yet.
- `syn_map` picks actual gsclib045 cells. Now it has delay.
- `syn_opt` optimises against your constraints.

Running `report_timing` after each one and watching the slack move is the
fastest way to see what synthesis actually does.

## 8. Reports

```
genus:/> report_area
genus:/> report_timing
genus:/> report_power
```

Find the `slack` line. Note the total cell area.

**If slack is negative, go back to step 2, increase the clock period, and redo
this.** Do not go to Part B with negative slack. Everything after inherits it and
you will spend week 9 debugging a week 7 mistake.

## 9. Write the outputs

```
genus:/> write_hdl -mapped > post-synth.v
genus:/> write_sdc         > post-synth.sdc
genus:/> exit
```

Look at what you got:

```
% less post-synth.v
```

`less` scrolls with space, searches with `/word`, quits with `q`. It never
changes the file, which is why it is the right tool for reading reports and
netlists. When you do need to edit something, use `vi` and see `SETUP.md`.

That is your PE as gates. Pick a cell name out of it and look it up:

```
% grep -A 20 "cell (INVX1)" $LIB_SS
```

## 10. Save the commands

Put every `genus:/>` command into `run.tcl`, ending with `exit`:

```
% vi run.tcl
```

`i` to type, `Esc` to stop, `:wq` to save and quit. If the letters `:wq` end up
in your file, you were still in insert mode: press `Esc` first.

Then make `run`:

```bash
#!/usr/bin/env bash
genus -no_gui -files run.tcl
```

```
% chmod +x run
% ./run
```

You should get the same result you got by hand.

---

# Part B: Simulate the gates

Good ASIC designers never trust their tools. Synthesis just rewrote your design.
The way to check it did that correctly is to run your test again, on the gates.

Every gate takes zero time here, so this is a pure question of function. Wire
delay comes much later.

## 11. Look at the cell models

```
% less $STDCELLS_V
```

Behavioural Verilog for every cell in the library. Find `INVX1`.

## 12. Simulate

```
% cd ~/pe-apprentice/week07-synthesis
% xrun -sv -access +rwc \
    +delay_mode_zero \
    $STDCELLS_V \
    post-synth.v \
    ../rtl/pe_smoke_tb.sv
```

Two differences from week 3: it reads the cell library and your synthesized
netlist instead of your RTL, and `+delay_mode_zero` strips the cell delays out.

Same testbench. Same expected result: `SMOKE TEST PASSED, 0 errors`.

If it passed in week 3 and fails here, believe it. That is exactly the kind of
bug this step exists to catch, and finding one is a good day.

## 13. Save it

```
% vi run-glsim
```

```bash
#!/usr/bin/env bash
xrun -sv -access +rwc \
  +delay_mode_zero \
  $STDCELLS_V \
  post-synth.v \
  ../rtl/pe_smoke_tb.sv
```

```
% chmod +x run-glsim
% ./run-glsim
```

## Turn in

```
% cd ~/pe-apprentice
% git add week07-synthesis/constraints.sdc week07-synthesis/run.tcl \
          week07-synthesis/run week07-synthesis/run-glsim
% git commit -m "week 7: synthesis"
% git bundle create ~/<your-username>-week7.bundle main..<your-username>
```

Move the bundle off the chamber, plus your area and timing reports, and a short
writeup: which path did you predict would be critical in week 6, which one
actually is, and if they differ, why did you miss it?

## Done means

- Synthesis completes with no unresolved references and no inferred latches
- Slack is not negative
- The gate netlist passes the same test your RTL passed
- You can point at the worst path in the timing report and say what it is
- Both `run` scripts work from a fresh shell
