# Week 5 Lab: Build It and Find Real Bugs

*Week 5 of 11. Handout.*

> **BEING REVISED (2026-08-16).** The commands in this handout predate the
> flow-step layout and the verified chamber paths. Use the `run` script in the
> matching `0N-*/` directory instead, and `docs/00-chamber-and-repo-setup.md`
> for anything chamber-related. The goals, tasks, and deliverables below are
> current; only the command lines are stale.


**Goal:** Turn your week 4 plan into a running testbench, and use it on your own RTL.

**Before you start**
No video this week. Build from your week 4 plan. Same Xcelium setup as week 3.

**Task**
1. Open `pe-apprentice/week5-verif/`. A testbench shell and a scoreboard stub are already there, matching the block diagram structure from week 4 (DUT, stimulus, reference model, scoreboard). Fill in your reference model and your stimulus for each corner case from your week 4 plan.
2. Run one test case at a time first, to make sure each one actually works before you trust the whole suite:
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice/week5-verif
% xrun -sv -access +rwc pe.sv scoreboard.sv pe_tb.sv +define+TESTNAME=corner_switch_same_cycle
```
3. Once individual cases pass, use the provided run script to sweep every corner case in one shot and get a single pass/fail summary instead of reading logs by hand:
```
% ./run
```
4. For every failure, figure out whether the bug is in your RTL or in your testbench. Fix it. Log it either way.

**Deliverable**
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice
% git add week5-verif/
% git commit -m "week 5: self-checking testbench and bug log"
% git bundle create ~/<your_eid>-week5.bundle main..<your_eid>
```
SFTP `<your_eid>-week5.bundle` off the chamber, plus your regression log and bug log as described below.

- Testbench code
- A regression log showing pass/fail per test case, not raw output for a human to eyeball
- A bug log: what broke, what you thought was happening, what was actually happening, how you fixed it

**Done means**
- Testbench produces a clear pass or fail per test, automatically
- Every corner case from your week 4 plan is actually implemented, not just planned
- Bug log has real entries, or a clear, specific explanation of why none turned up
