# Week 4: Plan How to Break It

**Goal:** Learn how verification works, then plan a testbench that would
actually catch a bug in your PE.

No tools this week. Handwritten.

## Read

[Self Checking Testbench](https://chipverify.com/verification/self-checking-testbench),
chipverify.com. This is the exact pattern you build next week: a model computes
what the output should be, a scoreboard compares it against what your PE
produced, and it runs without you reading a log.

## Background

Verification is not running your design once and eyeballing the output. It is
deciding ahead of time what could go wrong, then building something that checks
for it automatically, every time.

A bug that only appears when two specific signals land on the same cycle will
never show up in a casual test. It shows up only if you went looking for it on
purpose.

One rule matters more than the rest, and it is the one people get wrong: **work
out your expected answers from the spec, not from your RTL.** If your model and
your design both come from the same understanding, they will agree with each
other and both can be wrong.

## The six components

Every industrial verification environment is built from the same six pieces, and
next week you build all six. Learn the names now.

| Component | Job | Called this in UVM |
|---|---|---|
| Generator | invents operations to try | `uvm_sequence` |
| Driver | turns an operation into pin wiggles | `uvm_driver` |
| Monitor | watches the DUT and drives nothing | `uvm_monitor` |
| Model | says what the answer should be | reference model |
| Scoreboard | compares, counts, reports | `uvm_scoreboard` |
| Coverage | says whether you tested enough | `covergroup` |

UVM is the SystemVerilog verification library used across the industry. You will
not use it next week; you will build the six ideas it is made of, which is the
faster route to understanding it later.

The split between driver and monitor is the one people find odd at first. A
driver makes things happen; a monitor only observes. Keeping them apart is what
lets you attach a monitor to a bus you do not control, or between two blocks
talking to each other, without disturbing anything.

## Directed versus constrained random

Every test you have written so far was **directed**: you chose the inputs and
you knew the answer. Directed tests find the bugs you thought of.

Next week you write **constrained random** stimulus instead. You describe the
space of legal inputs and how often you want each kind, and the simulator picks
the values. It produces combinations you would not have written, which is why it
finds bugs you would not have looked for.

The price is that you no longer know the answer in advance. That is what the
model is for, and it is why the two ideas always arrive together.

## What week 5 does with this

Your plan turns into a working testbench, run first against your own PE and then
against one somebody else wrote, which has defects in it.

## Do

1. **Write a test plan by hand.** Every corner case worth testing on this
   specific PE, not a generic checklist. Go back to your week 2 diagrams and
   written answers; the corner cases are sitting in them already.

2. **Draw your testbench as a block diagram.** All six components above, plus
   the DUT, with arrows showing what flows between them. Mark which components
   drive the DUT and which only watch it.

3. **Pick 2 of your corner cases** and hand draw the expected timing diagram for
   each, the same way you did in week 2.

4. **Turn your corner cases into a stimulus recipe.** For each of the four
   control signals, write down roughly how often it should be asserted and why.
   Next week those numbers become constraints, and you will have to defend them,
   so "half the time" needs a reason behind it.

## Turn in

Handwritten test plan, block diagram, and 2 timing diagrams. One PDF.

## Done means

- At least 5 corner cases, grounded in this interface
- At least one involving `pe_enabled`, and one involving what happens right
  after reset
- Block diagram shows all six components and which of them drive the DUT
- Your stimulus recipe gives a frequency and a reason for each control signal
- Both timing diagrams are correct
