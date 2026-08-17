# Week 3 Lab: Write the PE

*Week 3 of 11. Handout.*

**Goal:** Turn your week 2 spec into working, simulated SystemVerilog.

**Before you start**
No video this week. Your week 2 notes and diagrams are the spec. Write from
those, not from memory of any code you have seen. Chamber and repo already set
up per `00-chamber-and-repo-setup.md`. Get onto a compute node first, every
session:

```
% bash
% qsh -q normal.q -now n -V
% bash
```

**Background**
Everything you specified last week now has to become logic that a machine can
build. Two things change when you write it down as RTL. First, you cannot leave
anything vague: a signal either has a defined value every cycle or it does not,
and the simulator will tell you which. Second, some of your week 2 answers were
guesses, and this is the week you find out which ones.

The file you are filling in already has its port list, its weight registers, and
its multiplier and adder wired up. You write three blocks: how the weight gets
promoted, how the weight gets staged, and how the streaming datapath behaves.
Each one has a `TODO(week3)` comment above it naming the week 2 diagram that
answers it.

**Tasks**

1. Open `rtl/pe.sv` and fill in the three always blocks.

   Use `logic`, never `wire` or `reg`. Use `always_comb` for combinational logic
   and `always_ff` for sequential. Blocking assignment (`=`) goes inside
   `always_comb`, nonblocking (`<=`) inside `always_ff`, and you never mix them.
   These two constructs turn a whole class of mistakes into compile errors
   instead of silent bugs you find three weeks later in a waveform.

   Every flop you declare needs a defined value out of reset. Every one. If you
   miss one it is X in simulation and it powers up unknown in silicon, and
   because partial sums chain down a column, one unknown poisons every PE below
   it.

2. Simulate:

```
% cd ~/longhorn-apprentice/pe-apprentice
% ./02-xcelium-rtlsim/run
```

   The script loads Xcelium, creates a fresh run directory under `~/work/pe/`,
   compiles your PE against the provided smoke testbench, and prints a pass or
   fail per check. Your output never lands in the repo, so a `git checkout`
   cannot destroy a run and a run cannot dirty your `git status`.

3. Pull the waveform and check it against your own week 2 diagrams:

```
% ./02-xcelium-rtlsim/run --waves
```

   This opens SimVision on the run you just did. If your waveform disagrees with
   your week 2 timing diagram, one of the two is wrong. Work out which before
   you change any code. Sometimes it is the diagram, and finding that out is
   worth more than the fix.

4. Read what the smoke test actually checks, in
   `02-xcelium-rtlsim/pe_smoke_tb.sv`. Four checks, and they are the floor, not
   the ceiling. A PE that passes all four can still be wrong in ways that matter.
   Weeks 4 and 5 are where you go find those.

**Deliverable**

```
% cd ~/longhorn-apprentice/pe-apprentice
% git add rtl/pe.sv
% git commit -m "week 3: pe.sv"
% git bundle create ~/<your-username>-week3.bundle main..<your-username>
```

Transfer `<your-username>-week3.bundle` off the chamber, plus a screenshot of
the passing smoke test with the waveform visible.

**Done means**
- Simulates with 0 errors and 0 unintentional warnings
- All four smoke test checks pass
- Signal names match the interface exactly, nothing renamed
- No leftover debug prints, no dead code
- You can say, out loud, why you chose combinational or sequential for the
  weight promotion, and what that choice does to the answer you gave in week 2
  question 5a
