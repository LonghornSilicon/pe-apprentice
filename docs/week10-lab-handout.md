# Week 10 Lab: Is It Actually Manufacturable

*Week 10 of 11. Handout.*

> **BEING REVISED (2026-08-16).** The commands in this handout predate the
> flow-step layout and the verified chamber paths. Use the `run` script in the
> matching `0N-*/` directory instead, and `docs/00-chamber-and-repo-setup.md`
> for anything chamber-related. The goals, tasks, and deliverables below are
> current; only the command lines are stale.


**Goal:** Take your routed design through physical verification and produce a real, signoff quality GDS.

**Before you start**
Read: the Signoff section of [the SemiAnalysis EDA Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon), specifically Design Rule Check, Layout vs Schematic, and Static Timing Analysis at signoff.

**Background**
DRC checks that your layout obeys the foundry's manufacturing rules: minimum spacing, minimum width, all the geometric constraints that make a design possible to actually fabricate. LVS checks that the layout you built matches the circuit you meant to build, with no accidental shorts or missing connections. Passing both is what makes a layout real, rather than just a picture that happens to look right.

**Task**
1. Confirm you have `pe_layout.gds` and `pe_postroute.v` from week 9 in `pe-apprentice/week10-signoff/`.
2. Run DRC. PD leads: fill in the real tool and ruledeck path here once the PDK is finalized, this is a placeholder command shape.
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice/week10-signoff
% <drc-tool> -rules <ruledeck> -input pe_layout.gds -output drc.rpt
```
3. Fix every violation. Re-run DRC until `drc.rpt` is clean.
4. Run LVS, same placeholder note as above:
```
% <lvs-tool> -layout pe_layout.gds -netlist pe_postroute.v -output lvs.rpt
```
5. Fix every mismatch. Re-run LVS until `lvs.rpt` is clean.

**Deliverable**
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice
% git add week10-signoff/pe_layout.gds week10-signoff/drc.rpt week10-signoff/lvs.rpt
% git commit -m "week 10: signoff"
% git bundle create ~/<your_eid>-week10.bundle main..<your_eid>
```
SFTP `<your_eid>-week10.bundle` off the chamber, plus a short signoff summary: what checks passed, and anything still open, named specifically.

**Done means**
- GDS is actually generated, not just a plan to generate one
- DRC and LVS reports are included and clean
- Any open items are named specifically, with a reason they're still open, not glossed over
