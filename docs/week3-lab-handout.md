# Week 3 Lab: Write the PE

*Week 3 of 11. Handout.*

> **BEING REVISED (2026-08-16).** The commands in this handout predate the
> flow-step layout and the verified chamber paths. Use the `run` script in the
> matching `0N-*/` directory instead, and `docs/00-chamber-and-repo-setup.md`
> for anything chamber-related. The goals, tasks, and deliverables below are
> current; only the command lines are stale.


**Goal:** Turn your week 2 spec into real, simulated SystemVerilog.

**Before you start**
No video this week. Your week 2 notes and diagrams are the spec. Write from those, not from memory of any code you've seen. Chamber and repo already set up per `00-chamber-and-repo-setup.md`.

**Task**
1. Open `pe-apprentice/week3-rtl/pe.sv`. The port list and module declaration are already there, fill in the `always_comb` and `always_ff` blocks. Use `logic`, not `wire`/`reg`, and don't mix blocking and nonblocking assignments. This matters, `always_comb` and `always_ff` catch a whole class of mistakes at compile time that plain Verilog lets slide through silently.
2. Simulate against the provided smoke test:
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice/week3-rtl
% xrun -sv -access +rwc pe.sv pe_smoke_tb.sv
```
`-access +rwc` gives you full read/write/connect access to every signal, you need it for waveform debug. Without it, SimVision shows you nothing.
3. Get it passing, then pull the waveform and check it against your own week 2 timing diagrams:
```
% xrun -sv -access +rwc pe.sv pe_smoke_tb.sv -input waves.tcl
% simvision waves.shm
```
`waves.tcl` is already in the directory, it opens a waveform database and probes every signal. If your waveform doesn't match your week 2 diagrams, one of them is wrong, figure out which.

**Deliverable**
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice
% git add week3-rtl/pe.sv
% git commit -m "week 3: pe.sv"
% git bundle create ~/<your_eid>-week3.bundle main..<your_eid>
```
SFTP `<your_eid>-week3.bundle` off the chamber, plus a screenshot of your passing smoke test simulation with the waveform visible.

**Done means**
- Simulates with 0 errors and 0 unintentional warnings
- Passes the provided smoke test
- Signal names match the interface exactly, no renaming
- Code is legible: no leftover debug prints, no dead code
