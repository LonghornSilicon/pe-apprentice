# Week 7 Lab: Run Synthesis

*Week 7 of 11. Handout.*

**Goal:** Synthesize your PE, find out whether your week 6 prediction was right,
then prove synthesis did not break your design.

**Before you start**
No video this week. Your week 6 draft constraints are the starting point.
Compute node first, as always.

**Background**
Synthesis reads your RTL and picks actual gates out of the gsclib045 library to
build it. Those gates have measured delay, measured area, and measured leakage,
which is why the library is 200 MB of tables and not a page of formulas.

Two things happen this week that are easy to miss. First, the tool optimizes
against your constraints, so a different `constraints.sdc` gives a different
netlist from the same RTL. The constraints are part of your design. Second,
synthesis is a translation, and translations can be wrong. Step 04 exists to
check that the gates still do what the RTL did.

You run Genus interactively first, one command at a time, and only then use the
script. A script you ran before you understood it is a script you cannot debug.

**Tasks**

1. Turn your week 6 draft constraints into `03-genus-synth/constraints.sdc`. The
   template is there with deliberately loose placeholder numbers. Replace them
   with what you argued for in week 6. "It was in the template" is not an
   answer anyone accepts.

2. Open Genus interactively and walk the flow by hand:

```
% ./03-genus-synth/run --shell
```

   This puts you at a Genus prompt with the environment set up and nothing else
   done. Read `03-genus-synth/run.tcl` and type its commands in one at a time.
   After each of `syn_generic`, `syn_map`, and `syn_opt`, run:

```
genus:/> report_timing -nworst 1
```

   Watching the slack move across those three stages is the fastest way to build
   intuition for what synthesis actually does. Genus splits them apart on
   purpose instead of hiding everything behind one command.

3. Now run the whole thing as a script, which is how you will run it every time
   after today:

```
% ./03-genus-synth/run
```

   Reports land in the run directory. Read `reports/qor.rpt` first, then
   `reports/timing_setup.rpt`.

4. Find the worst negative slack line in `reports/timing_setup.rpt`. That path
   is your actual critical path. Compare it to what you predicted in week 6.

   If your slack is negative, you asked for a clock your logic cannot deliver.
   Loosen the period in `constraints.sdc` and re-run until it closes. **Do not
   go to step 5 with negative slack.** Everything downstream inherits it and you
   will be debugging a place-and-route problem that was a synthesis problem.

5. Run gate-level simulation:

```
% ./04-xcelium-ffglsim/run
```

   This takes the netlist Genus just wrote, links it against the behavioural
   models of the gsclib045 cells, and runs your own week 5 testbench against it.
   Same tests, same golden vectors, different design under test.

   It runs in zero-delay mode, so it is a pure functional check: did synthesis
   preserve the behaviour, yes or no. Timing comes later, with wires, in weeks
   9 and 10.

   If your testbench passed on RTL and fails on gates, believe it. That is
   exactly the class of bug this step exists to catch.

**Deliverable**

```
% cd ~/longhorn-apprentice/pe-apprentice
% git add 03-genus-synth/constraints.sdc
% git commit -m "week 7: synthesis constraints"
% git bundle create ~/<your-username>-week7.bundle main..<your-username>
```

Transfer the bundle off the chamber, plus, copied out of your run directory:

- `reports/qor.rpt`, `reports/area.rpt`, `reports/timing_setup.rpt`
- `outputs/pe_synth.v`
- The pass/fail output of step 04
- A short writeup: was your week 6 prediction right? If not, what is the actual
  critical path, and why did you miss it?

**Done means**
- Synthesis completes clean, no unresolved references, no inferred latches
- Setup slack is not negative
- Gate-level simulation passes with the same testbench that passed on RTL
- Your writeup reads WNS and TNS correctly off the report and gives a specific
  reason for any mismatch with your prediction, not "I was wrong"
