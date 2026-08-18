# Week 8: Before You Place and Route

**Goal:** Understand floorplanning and placement before you run a tool that
makes those decisions for you.

No tools this week. Handwritten.

**Pair up this week.** You work in pairs for weeks 9 and 10 because Innovus is
heavy and the chamber is shared with other universities. Sort out who you are
working with now.

## Before you start

Read the Physical Design section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
specifically Floorplanning, Power Planning, Placement, Routing, and Clock Tree
Synthesis.

Watch your PD lead's walkthrough of the floorplan flow, recorded for this week.

## Background

Floorplanning decides where things go before anything is placed: how big the die
is, where the major blocks sit, where power runs, where the pins land. Placement
then puts every individual cell somewhere inside that plan.

Get the floorplan wrong and everything after it gets harder. Wires get longer,
congestion builds up in tight spots, power delivery gets uneven. Fixing a bad
floorplan after routing costs far more than fixing it before placement starts.

## What you are planning

Your PE. One of them, the same design you synthesized in week 7.

The thing that makes this a real decision is not how many cells there are, it is
where the signals enter and leave. Your PE has four edges and every port belongs
to one of them: activations arrive from the west, partial sums arrive from the
north and leave to the south, activations continue east. Next week you will
place those pins yourself, and where you put them changes how far every wire has
to travel.

Look at the interface again with that in mind:

```bash
less ~/pe-apprentice/rtl/pe.sv
```

## Do

1. **Floorplan sketch.** Draw the core as a rectangle. Mark which edge each
   group of ports goes on, and why. Mark where the power ring runs and where the
   stripes cross the core.

   Every port has a natural side, given how a PE sits in a grid: its north
   neighbour feeds it partial sums, its west neighbour feeds it activations, and
   it feeds the PE below and to the right. Put each one where its neighbour
   would be.

   You will type this into Innovus next week, so be specific enough to
   implement.

2. **Notes.** Name at least 2 things that go wrong with a bad floorplan, and why
   catching them now is cheaper than catching them at routing.

3. **One prediction.** With your pin placement, which port will have the longest
   wire to the logic it drives? Week 9 gives you a total wire length you can
   check it against.

## Turn in

Floorplan sketch and notes. One PDF.

## Done means

- The sketch assigns every port group to a specific edge, with a reason
- Pin placement matches the direction data flows in a grid of PEs
- At least 2 named risks (congestion, IR drop, long critical nets are the usual)
- You committed to a prediction in task 3
