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

```
% less ~/pe-apprentice/rtl/pe_array_2x2.sv
```

Four of your PEs wired into a grid. Read the header: activations flow west to
east, partial sums flow north to south, weights come in from the north.

Four instead of one because floorplanning a single cell is not a decision. With
four there is a wrong answer and a right answer.

## Do

1. **Floorplan sketch.** Where would you put the four PEs relative to each other,
   given how data actually moves between them? Where would the power rings and
   straps run? Where would the pins land on each edge?

   Activations enter from the west and results leave to the south. Your pin
   placement should show that.

2. **Notes.** Name at least 2 things that go wrong with a bad floorplan, and why
   catching them now is cheaper than catching them at routing.

3. **One prediction.** Which of the four PEs will have the longest wire to its
   neighbour under your floorplan, and roughly how much longer? Week 9 tells you
   whether you were right.

## Turn in

Floorplan sketch and notes. One PDF.

## Done means

- The sketch shows a specific layout choice with reasoning, not a rectangle with
  PEs scattered in it
- Pin placement matches the direction data flows
- At least 2 named risks (congestion, IR drop, long critical nets are the usual)
- You committed to a prediction in task 3
