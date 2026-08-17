# Week 4 Lab: Plan How to Break It

*Week 4 of 11. Handout.*

**Goal:** Learn how verification works, then plan a testbench that would actually catch a bug in your PE.

**Before you start**
Read: [Self Checking Testbench](https://chipverify.com/verification/self-checking-testbench), chipverify.com. This is the exact pattern you're about to build: a reference model computes what the output should be, a scoreboard compares it against what your PE actually produced, and it runs unattended instead of you reading through a log by hand.

If you want to see where this leads at a real company, the RTL Verification section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon) covers UVM and constrained random testing. That's further than we're going this semester, but it's built on the exact same idea you're about to use.

**Background**
Verification isn't about running your design once and eyeballing the output. It's about deciding, ahead of time, what could go wrong, then building something that checks for it automatically, every time, without you watching. A bug that only shows up when two specific signals hit on the same cycle will never show up in a casual test. It only shows up if you went looking for it on purpose.

**What week 5 does with this**
Your plan becomes three concrete things next week: a Python golden model that
computes the expected answer (`01-golden-model/`), stimulus and a scoreboard in
SystemVerilog (`02-xcelium-rtlsim/`), and then the whole thing pointed at a PE
somebody else wrote, which has defects in it.

That last part is why one rule matters more than the rest: **derive your
expected answers from the spec, not from your RTL.** If the golden model and the
design come from the same understanding, they will agree with each other and
both can be wrong. Write the plan from your week 2 notes.

**Tasks**
1. Write a test plan by hand. List every corner case worth testing on this specific PE, not generic ones. Go back to your week 2 diagrams and written answers, the corner cases are already sitting in them.
2. Draw a block diagram of your testbench: the PE (DUT), something that generates stimulus, a reference model that computes the expected output in software, and a scoreboard that compares the two and flags mismatches.
3. Pick 2 of your corner cases and hand draw the expected timing diagram for each, the same way you did in week 2.

**Deliverable**
Handwritten test plan, testbench block diagram, and 2 timing diagrams. One PDF.

**Done means**
- At least 5 corner cases listed, grounded in this interface, not a generic checklist
- At least one corner case involving `pe_enabled`, and one involving what a
  signal does immediately after reset
- Block diagram shows all 4 pieces: DUT, stimulus, reference model, scoreboard
- Both timing diagrams are correct
