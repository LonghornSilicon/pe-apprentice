# Week 5: Build the Testbench, Find Real Bugs

**Goal:** Turn your week 4 plan into a running testbench, use it on your own PE,
then use it on a PE somebody else wrote.

**Not written yet.** This handout is still being finished.

## What it will cover

Two halves.

First you build it: a Python model in `gen_pe_vectors.py` that computes what the
PE should output, plus stimulus and a scoreboard in SystemVerilog that reports
pass or fail per test without you reading a log.

Then you point the whole thing at `rtl/pe_vendor_drop.sv`, a PE written by
someone else, and find out whether what you built actually works. That PE has
bugs in it. A testbench you have never seen fail is not a testbench, it is a
hope.

Your grade on this week is one thing: does your testbench catch every bug in the
vendor PE.

## Meanwhile

Read the header of `rtl/pe_vendor_drop.sv`. Do not read the body.

Start `gen_pe_vectors.py`. The Q8.8 helpers are already in it and the model
itself is marked `TODO`. Write it from your week 2 spec, not from your RTL.

Ask a lead where this stands.
