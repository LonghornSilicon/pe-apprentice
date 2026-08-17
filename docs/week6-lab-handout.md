# Week 6 Lab: Before You Synthesize

*Week 6 of 11. Handout.*

**Goal:** Understand what synthesis does to your RTL, meet the standard-cell
library it does it with, and predict where your design will be slow before you
find out for real.

**Before you start**
- Watch: [Basic Static Timing Analysis, Analyzing Timing
  Reports](https://www.youtube.com/watch?v=Hxq1Xmr4Rpw), Cadence.
- Read: the Physical Design section of [the SemiAnalysis EDA
  Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
  specifically Logic Synthesis and Process Corners.
- Task 2 happens on the chamber. Get a compute node.

**Background**
Synthesis turns your RTL into a netlist of logic gates picked out of a standard
cell library. Those gates have delay. Data has to get from one flip-flop,
through whatever combinational logic sits between, to the next flip-flop, before
the next clock edge arrives.

The longest such path is the critical path, and it sets the fastest clock your
design can run at. Setup time is how long data must be stable before an edge.
Hold time is how long it must stay stable after. Slack is the difference between
how long a path is allowed to take and how long it takes. Negative slack means
you asked for a clock speed your logic cannot deliver.

Everything in that paragraph comes from numbers in a file. Task 2 is you opening
that file.

**Tasks**

1. Watch and read the material above. Then, handwritten and in your own words:
   what is a critical path, what is slack, what does negative slack actually
   mean, and what are your options for fixing it. Name at least three options
   and say what each one costs you.

2. Meet the library. Everything synthesis knows about gates lives in two files,
   and you are going to open both of them. On a compute node:

```
% module load genus/211/21.18.000
% setenv G /process/hosted/gpdk/gpdk045/ip_libraries/gsclib045/v4p4/gsclib045
% less $G/timing/slow_vdd1v0_basicCells.lib
```

   Search for `cell (INVX1)` (type `/cell (INVX1)` and hit enter). This is the
   simplest gate in the library, one inverter. Write down, by hand:

   - its `area`
   - its `cell_leakage_power`
   - the `capacitance` of its input pin
   - the `function` of its output pin
   - one number out of its delay table, and what the two axes of that table are

   That last one is the important one. Delay is not a constant. It is a lookup
   against how fast the input transitions and how much capacitance the output
   drives. That table is where every timing number you will read in week 7 comes
   from.

   Now the other file:

```
% less $G/lef/gsclib045_tech.lef
% less $G/lef/gsclib045_macro.lef
```

   The tech LEF describes the metal layers and the spacing rules. The macro LEF
   describes each cell's physical shape. Find `MACRO INVX1` in the macro LEF and
   write down its width and height, where its input and output pins sit, and
   which layers it blocks.

   The `.lib` is what synthesis reads. The `.lef` is what place and route reads.
   Same cell, two views, two different questions.

3. Draft SDC constraints for your PE by hand: a target clock period with a
   reason behind the number, and which ports are your primary inputs and
   outputs. The period is the number you will defend in week 7, so pick it for a
   reason you can say out loud.

4. Before you run anything, sketch which path through your PE you think will be
   the critical path, and explain why. Look at your week 3 code, not at a
   general principle. The path starts at a specific signal and ends at a
   specific flop, and you should be able to name both.

5. Accumulator width, in writing. Your psum is 16 bits in Q8.8, so it saturates
   at about +128. In an 8x8 array, eight products accumulate down a column
   before the result leaves. How large can the average product be before that
   saturates? Show the arithmetic.

   Then look at what the actual chip did: `src/blocks/acu/mate/README.md` in the
   Lambda repo, the "Known gotchas" section. MatE's P·V tile uses a 32-bit
   accumulator because 24 bits overflowed past about 520 tokens. Same problem,
   same reasoning, bigger numbers.

**Deliverable**
Handwritten notes, your library findings from task 2, draft constraints,
critical path prediction, and the accumulator arithmetic. One PDF.

**Done means**
- Setup, hold, and slack explained correctly and in your own words
- Both library files opened and the requested numbers written down, including
  what the two axes of the delay table are
- Constraint draft has a specific clock period with reasoning behind it
- Critical path prediction names a specific start point and end point in your
  own PE, not a general shrug
- Accumulator arithmetic is shown and the answer is a number
