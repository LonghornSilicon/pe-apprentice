# Week 1: The Whole Picture

**Goal:** See the entire path from idea to shipped chip before we zoom into any
one piece of it.

No tools this week. Reading and paper.

## Read

[The EDA Primer, From RTL to Silicon](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
SemiAnalysis. Read at least through the Physical Design section. This is not a
light explainer. Take your time with it.

## Background

A chip starts as an idea and ends up as a physical object smaller than your
fingernail with billions of transistors in it. The primer lays out the 13 stages
that get you from one to the other. Each stage is handled by a different kind of
engineer, and each one turns the design into something closer to silicon.

This week is about seeing that whole map. Starting next week we zoom into one
small piece of it: a single PE.

## Do

1. List all 13 stages in order.

2. For each stage, one sentence: what goes in, what comes out. For example,
   "Logic synthesis: RTL code goes in, a gate level netlist comes out."

3. Pick any 2 stages. Write 2 to 3 sentences each on why a mistake made at that
   stage gets more expensive the later it is caught. The primer gives real
   numbers on mask costs and respin timelines. Use them.

4. Draw the whole flow on one page, as boxes and arrows. Label where each of our
   4 teams works (ARCH, RTL, DV, PD). Mark where our PE sits, and be clear that
   it is one small piece of Lambda, and Lambda is one small piece of what a chip
   company does.

## Turn in

One page: your diagram plus the written answers. Photo or scan, one PDF.

## Done means

- All 13 stages named, in the right order
- At least 8 have a correct in/out description
- The diagram shows all 4 teams and where the PE sits
