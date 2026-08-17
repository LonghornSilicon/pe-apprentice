# Week 10 Lab: Signoff

*Week 10 of 11. Handout.*

**Goal:** Prove the layout meets timing with measured wire delays, obeys the
foundry's manufacturing rules, and matches the circuit you meant to build.

**Before you start**
Read the Signoff section of [the SemiAnalysis EDA
Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
specifically Design Rule Check, Layout vs Schematic, and Static Timing Analysis.
Stay in pairs.

**Background**
Three checks stand between a layout and a mask set, and they answer three
different questions.

Static timing analysis asks whether the design runs at the speed you claimed,
using resistance and capacitance measured off the wires that got built. Innovus
gave you its opinion in week 9. Tempus is the signoff tool and its answer counts.

DRC asks whether the geometry can be manufactured at all. Minimum spacing,
minimum width, layer overlaps. These rules come from the foundry because
lithography has physical limits.

LVS asks whether the layout is the circuit. It pulls a transistor netlist out of
your polygons and compares it against the netlist you meant to build. It catches
shorts you drew by accident and connections you never drew. A design can pass
DRC and still be completely wrong.

**Do this, in order**
1. `06-tempus-sta/README.md`
2. `09-drc/README.md`
3. `10-lvs/README.md`

**Deliverable**
Your GDS, the three reports, and a one page summary: setup and hold slack with
the corner each came from, DRC status, LVS status, and anything still open with
a specific reason.

If something did not close, say so with numbers. A documented near-miss is a
result. A faked pass is the one thing here that will get someone in trouble at
a real company.

**Done means**
- A GDS exists
- Setup and hold reported at the correct corners, and you can say which is which
- DRC clean, or every violation named with a reason it is open
- LVS clean, or every mismatch named
- Your summary is honest
