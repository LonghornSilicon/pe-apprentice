# pe-apprentice

Longhorn Silicon apprentice program. One processing element, specification to
GDS, on the Cadence chamber, in ten weeks.

You will write a single PE — one cell of the systolic array at the heart of
Lambda's matmul engine — and then personally push it through every stage of a
production ASIC flow: RTL, verification, synthesis, gate-level verification,
place and route, and physical signoff. At the end you will hold a GDS you made.

The point is not the PE. The point is that after ten weeks you will have run
the same tools, on the same chamber, against the same PDK, in the same order as
the people taping out the real chip — so that on week 12 you can contribute.

## The flow

The repository is organized by **flow step**, not by week, because that is what
it is: a pipeline where each stage consumes the previous stage's output. Weeks
map onto steps; steps do not move.

```
rtl/pe.sv                 <- the one file you write
     |
 01-xcelium-rtlsim/       simulate it                       (week 3)
     |
 02-xcelium-verif/        try to break it                   (weeks 4-5)
     |
 03-genus-synth/          RTL -> gate netlist               (weeks 6-7)
     |
 04-xcelium-glsim/        verify the GATES, not the RTL     (week 7)
     |
 05-innovus-pnr/          netlist -> placed and routed      (weeks 8-9)
     |
 06-innovus-signoff/      is it manufacturable? -> GDS      (week 10)
```

Every step directory holds a `run` script. Run it from anywhere:

```
% ./01-xcelium-rtlsim/run
% ./01-xcelium-rtlsim/run --waves
% ./03-genus-synth/run --shell
```

Two rules that make the whole thing work:

**Tool output never lands in this repo.** Runs go to `$PE_WORK` (`~/work/pe` by
default). A `git checkout` can never destroy a run, and a run can never dirty
your `git status`. Each run gets its own timestamped directory, so a failing run
never overwrites the last good one — you can diff them.

**Every run leaves two signals.** `<step>/latest` is a symlink to the most
recent run. `<step>/<run-id>/STATUS` says `PASS` or `FAIL` with a return code.
Which run was last, and whether it worked, are different questions; you can
answer both without opening a tool log.

## Start here

1. `docs/00-chamber-and-repo-setup.md` — chamber access, one-time setup, and
   the sanity check that has to pass before week 2. **Not optional.**
2. `docs/longhorn-silicon-apprentice-program.md` — the eleven-week syllabus.
3. Your week's handout in `docs/`.

## What is in the repo

| Path | What it is |
|---|---|
| `rtl/pe.sv` | Your file. Ports and MAC are given; you write the always blocks. |
| `rtl/fxp.sv` | Given. Q8.8 fixed-point add and multiply. Read the header — the arithmetic contract matters later. |
| `vendor/pe_vendor_drop.sv` | A PE written by someone else. Week 5 DUT. Read its header, not its body. |
| `0N-*/run` | The flow. One script per step. |
| `tools/` | Chamber environment: module pins, PDK paths, `chamber-diagnose`. Inherited from the Lambda chamber framework. |
| `docs/` | Handouts. |

## Technology

Everything targets **gsclib045**, the Cadence generic 45 nm standard-cell
library installed on the chamber. It is a real industrial kit with real Liberty
timing, real LEF abstracts, real behavioural models, and a real transistor-level
netlist — everything a full flow needs.

It is not the process Lambda tapes out on. Lambda targets TSMC N16FFC, which is
under NDA and is not on this chamber. gsclib045 is a proxy, and knowing the
difference between a proxy and a destination is itself part of the job.

Tool versions and PDK paths are pinned in `tools/lib/pe-env.sh`, verified live
on the chamber. Do not hardcode a path anywhere else.

## For leads

Answer keys, the golden PE, the planted-defect list, and grading rubrics live in
the separate private `pe-apprentice-staff` repository. Nothing in this repo
reveals them.
