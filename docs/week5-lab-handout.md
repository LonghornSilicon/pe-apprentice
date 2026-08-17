# Week 5 Lab: Build It and Find Real Bugs

*Week 5 of 11. Handout.*

**Goal:** Turn your week 4 plan into a running testbench, use it on your own
RTL, then use it on a PE somebody else wrote.

**Before you start**
No video this week. Build from your week 4 plan. Same compute node setup as
week 3.

**Background**
A testbench you have never seen fail is not a testbench, it is a hope. You have
no evidence it would catch anything, because it has never had to.

So this week has two halves. First you build the thing: a golden model in
Python that computes what the PE should output, a stimulus driver, and a
scoreboard that compares the two and reports pass or fail per test without you
reading a log. Then you point it at `vendor/pe_vendor_drop.sv`, a PE written by
someone else, and find out whether what you built actually works.

That second half is the graded part, and it is not a trick. Blocks arrive from
other teams, from acquisitions, and from IP vendors, with a datasheet and no
warranty. You do not get to assume they work. You get to prove whether they do,
using a testbench built against a spec you understand better than the person who
wrote the code did.

The vendor PE has defects. They are the same defect classes sitting in a
well-regarded open-source TPU today, one with over a thousand stars on GitHub.
Popular, working, widely-forked RTL ships with bugs of exactly this kind. The
only thing between those bugs and silicon is somebody who tested the spec
instead of testing the code.

Read the header of `vendor/pe_vendor_drop.sv`. Do not read the body until your
testbench passes on your own PE. Reading ahead does not make you faster, it
makes the exercise worthless.

**Tasks**

1. Write the golden model. Open `01-golden-model/` and write the generator that
   produces test vectors: a stream of inputs and the psum the PE should produce
   for each. Pure Python, no numpy.

```
% ./01-golden-model/run
```

   The chamber's `python` is 2.7 and there is a separate 3.6 at
   `/grid/common/bin/python3`. The run script handles that for you.

   Write the model from the spec, not from your RTL. If you derive the expected
   answer from the same code you are testing, both will agree and both can be
   wrong. This is the single most common way a testbench ends up worthless.

2. Fill in your stimulus and scoreboard in `02-xcelium-rtlsim/`. The shell is
   there and matches the block diagram structure from week 4: DUT, stimulus,
   golden vectors, scoreboard. Implement every corner case from your week 4 plan.

3. Run one case at a time first, so you know each works before you trust the
   suite:

```
% ./02-xcelium-rtlsim/run --test corner_switch_same_cycle
```

4. Then sweep everything and get one pass/fail summary:

```
% ./02-xcelium-rtlsim/run --regress
```

5. For every failure, work out whether the bug is in your RTL or your testbench.
   Fix it. Log it either way. A testbench bug you found and fixed is worth
   writing down; it tells you what you misunderstood about the spec.

6. Now point the same testbench at the vendor PE:

```
% ./02-xcelium-rtlsim/run --regress --dut vendor
```

   Your scoreboard should fail. For each failure produce four things: the test
   case that caught it, the waveform showing it, the sentence of the week 2 spec
   it violates, and what you would tell the vendor to change.

   If it catches nothing, your testbench is the thing that is broken.

**Deliverable**

```
% cd ~/longhorn-apprentice/pe-apprentice
% git add 01-golden-model/ 02-xcelium-rtlsim/
% git commit -m "week 5: golden model, self-checking testbench, vendor bug report"
% git bundle create ~/<your-username>-week5.bundle main..<your-username>
```

Transfer the bundle off the chamber, plus:

- Your regression log, pass/fail per test case, not raw output for a human to
  eyeball
- Your bug log for your own PE: what broke, what you thought was happening, what
  was actually happening, how you fixed it
- Your vendor bug report, one entry per defect, in the four-part form above

**Done means**
- The testbench produces a clear pass or fail per test, automatically
- Every corner case from your week 4 plan is implemented, not just planned
- The golden model was written from the spec and you can say how you know it is
  independent of your RTL
- Your bug log has real entries, or a specific explanation of why none turned up
- **Your testbench catches every defect in the vendor PE.** This is binary and
  it is the main thing week 5 is graded on.
