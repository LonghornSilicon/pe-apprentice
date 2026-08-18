# Week 6: Before You Synthesize

**Goal:** Understand what synthesis does to your RTL, and predict where your
design will be slow before you find out for real.

Mostly paper. One short exercise on the chamber.

## Before you start

Watch [Basic Static Timing Analysis](https://www.youtube.com/watch?v=Hxq1Xmr4Rpw),
Cadence.

Read the Physical Design section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
specifically Logic Synthesis and Process Corners.

## Background

Synthesis turns your RTL into a netlist of gates from a standard cell library.
Those gates have delay. Data has to get from one flip-flop, through whatever
logic is between, to the next flip-flop, before the next clock edge.

The longest such path is the **critical path**, and it sets the fastest clock
your design can run at. **Setup time** is how long data has to be stable before
an edge. **Hold time** is how long it has to stay stable after. **Slack** is the
difference between how long a path is allowed to take and how long it takes.
Negative slack means you asked for a clock speed your logic cannot deliver.

Every one of those numbers comes out of a file. Task 2 is you opening it.

## Do

1. **Handwritten notes, in your own words:** what is a critical path, what is
   slack, what does negative slack mean, and what are your options for fixing it.
   Name at least three options and what each one costs you.

2. **Open the library.** On the chamber:

```bash
bash
qsh -q normal.q -now n -V
bash
source ~/pe-apprentice/setup.sh
less $LIB_SS
```

   Search for `cell (INVX1)` by typing `/cell (INVX1)` and hitting enter. This is
   the simplest gate in the library. Write down by hand:

   - its `area`
   - its `cell_leakage_power`
   - the `capacitance` of its input pin
   - one number out of its delay table, and what the two axes of that table are

   That last one matters most. Delay is not a constant. It is a lookup against
   how fast the input changes and how much load the output drives.

   Now the physical view:

```bash
less $LEF_MACRO
```

   Find `MACRO INVX1`. Write down its width and height, and where its pins are.

   The `.lib` is what synthesis reads. The `.lef` is what place and route reads.
   Same cell, two views, two different questions.

   Now look at the cell itself:

```bash
klayout -e $STDCELLS_GDS &
```

   In the cell list on the left, find `INVX1` and double-click it. You are
   looking at the actual polygons: diffusion, poly, contacts, metal. The width
   and height you wrote down from the LEF are the outline of what is on screen,
   and the pin rectangles are the shapes the router is allowed to touch.

   Everything in this program above this point is an abstraction over these
   shapes. Worth three minutes to see the bottom of the stack once.

3. **Draft your constraints.** A target clock period, with a reason behind the
   number. Which ports are your primary inputs and outputs. You will type this
   into a real file next week and have to defend the number.

4. **Predict your critical path.** Before you run anything, sketch which path
   through your PE you think will be slowest, and why. Look at your week 3 code.
   The path starts at a specific signal and ends at a specific flop. Name both.

## Turn in

Notes, your library findings, draft constraints, and your prediction. One PDF.
Include one sentence on what surprised you about the INVX1 layout.

## Done means

- Setup, hold, and slack explained correctly in your own words
- The library numbers written down, including what the delay table axes are
- A specific clock period with reasoning behind it
- A prediction that names a start point and an end point in your own PE
