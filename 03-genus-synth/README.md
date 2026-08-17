# Step 03: Synthesis

**Week 7, first half.** You turn your RTL into a netlist of real gates.

Synthesis reads your Verilog and picks actual cells out of the gsclib045
standard-cell library to build it. Those cells have measured delay and measured
area, which is where every number you are about to read comes from.

You will run Genus by hand first, one command at a time, and only then write the
script. This is on purpose.

## 1. Setup

```
% bash
% qsh -q normal.q -now n -V
% bash
% source ~/longhorn-apprentice/pe-apprentice/tools/setup.sh
% cd ~/longhorn-apprentice/pe-apprentice/03-genus-synth
```

## 2. Set your clock period

```
% less constraints.sdc
```

The clock period in there is a placeholder. Replace it with the number you
argued for in week 6.

## 3. Start Genus

```
% genus
```

You get a `genus:/>` prompt. Everything below goes in one command at a time.

## 4. Load the library

```
genus:/> set_db library $env(LIB_SS)
```

`LIB_SS` is the slow corner: 0.9 V, 125 C. Slow silicon is when data arrives
latest, which is when setup timing is hardest, so that is the corner you sign
off setup against.

## 5. Read and elaborate

```
genus:/> read_hdl -sv ../rtl/fxp.sv ../rtl/pe.sv
genus:/> elaborate pe
```

`read_hdl` parses. `elaborate` resolves parameters, builds the hierarchy, and
works out which signals become flip-flops.

Read the elaborate output. If it says it inferred a latch, stop and fix your
RTL. A latch you did not ask for means a combinational block does not assign
something on every path.

## 6. Apply constraints

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

Genus splits this into three on purpose instead of hiding it behind one command.

- `syn_generic` turns your RTL into generic boolean logic. No library cells yet.
- `syn_map` picks actual gsclib045 cells. Now it has delay.
- `syn_opt` optimizes against your constraints.

Run `report_timing` after each one and watch the slack move. That is the fastest
way to see what synthesis actually does.

## 8. Reports

```
genus:/> report_area
genus:/> report_timing
genus:/> report_power
```

Find the `slack` line in the timing report. If it is negative, you asked for a
clock your logic cannot deliver.

**If your slack is negative, go back to step 2, increase the clock period, and
redo this. Do not continue to step 04 with negative slack.** Everything
downstream inherits the problem and you will spend week 9 debugging a week 7
mistake.

Note the total cell area. You will compare against it later.

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

This is your PE as gates. Find a few cell names and look them up in the library:

```
% grep "cell (INVX1)" -A 20 $LIB_SS
```

## 10. Build the script

Put every `genus:/>` command from above into `run.tcl`, ending with `exit`:

```
% code run.tcl
```

Then `run`:

```bash
#!/usr/bin/env bash
genus -no_gui -files run.tcl
```

```
% chmod +x run
% ./run
```

You should get the same result as doing it by hand.

## Deliverable

Keep `constraints.sdc`, `run.tcl`, `run`, `post-synth.v`, and your reports.
Commit the first three; the rest go in your writeup.

Write a short comparison: which path did you predict would be critical in week
6, which one actually is, and if they differ, why did you miss it?

## Done means

- Synthesis completes with no unresolved references and no inferred latches
- Slack is not negative
- You can point at the worst path in the timing report and say what it is
- `./run` reproduces the whole thing from a clean shell
