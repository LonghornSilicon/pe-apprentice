# Week 5 Lab: Build It and Find Real Bugs

*Week 5 of 11. Handout.*

**Goal:** Turn your week 4 plan into a running testbench, use it on your own
RTL, then use it on a PE somebody else wrote.

**Before you start**
No video this week. Build from your week 4 plan.

**Background**
A testbench you have never seen fail is not a testbench, it is a hope. You have
no evidence it would catch anything, because it has never had to.

So this week has two halves. First you build it: a Python model that computes
what the PE should output, a stimulus driver, and a scoreboard that reports pass
or fail per test without you reading a log. Then you point it at
`vendor/pe_vendor_drop.sv`, a PE written by someone else, and find out whether
what you built actually works.

That second half is the graded part. Blocks arrive from other teams and from IP
vendors with a datasheet and no warranty. You do not assume they work, you prove
whether they do, using a testbench built against a spec you understand better
than the person who wrote the code did.

Read the header of `vendor/pe_vendor_drop.sv`. Do not read the body until your
testbench passes on your own PE.

**Do this, in order**
1. `01-golden-model/README.md`. Write the model that says what the answer should
   be. Write it from the spec, not from your RTL. If both come from the same
   understanding they will agree with each other and both can be wrong.
2. `02-xcelium-rtlsim/README.md`, section 8 onward. Build the scoreboard, run it
   on your PE, then run it on the vendor PE.

**Deliverable and Done means**
At the bottom of each README. The one that decides your grade: your testbench
catches every defect in the vendor PE.
