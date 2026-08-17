# Week 10 Lab: Signoff

*Week 10 of 11. Handout.*

**Goal:** Prove the layout meets timing with measured wire delays, obeys the
foundry's manufacturing rules, and matches the circuit you meant to build.

**Before you start**
Read the Signoff section of [the SemiAnalysis EDA
Primer](https://newsletter.semianalysis.com/p/the-eda-primer-from-rtl-to-silicon),
specifically Design Rule Check, Layout vs Schematic, and Static Timing Analysis
at signoff. Stay in pairs. Check your disk again.

**Background**
Three checks stand between a layout and a mask set, and they answer three
different questions.

Static timing analysis asks whether the design runs at the speed you claimed,
using the resistance and capacitance measured off the wires that actually got
built. Innovus already told you its opinion in week 9. Tempus is the signoff
tool, and its answer is the one that counts, because it uses a more careful
delay calculation and it is the tool the foundry flow expects.

DRC asks whether the geometry can be manufactured at all. Minimum spacing,
minimum width, layer overlaps, density. These rules come from the foundry and
they exist because lithography has physical limits. A layout that violates them
is a picture, not a chip.

LVS asks whether the layout is the circuit. It extracts a transistor netlist out
of your polygons and compares it against the netlist you meant to build. It
catches shorts you drew by accident and connections you never drew at all. A
design can be DRC clean and completely wrong.

Passing all three is what makes a layout real. Nothing before this point proves
your design can be built.

**Tasks**

1. Signoff timing:

```
% ./06-tempus-sta/run
```

   This reads your routed netlist, the extracted parasitics from week 9, and
   your constraints, and reports setup slack at the slow corner and hold slack
   at the fast corner.

   Setup and hold need different corners because they fail for opposite reasons.
   Setup fails when data arrives too late, which is worst on slow silicon.
   Hold fails when data arrives too early, which is worst on fast silicon. One
   corner cannot check both.

   Compare Tempus's numbers to Innovus's from week 9. They will not be
   identical. Write down which is more pessimistic and think about why.

2. Design rule check:

```
% ./09-drc/run
```

   This runs Assura against the gpdk045 rule deck. Read `drc.rpt`.

   For each violation: find it in the layout, work out which rule it broke, and
   fix the cause rather than the symptom. Most first-pass DRC violations on a
   small block come from the floorplan or the power grid, not from the router
   being wrong. Re-run until clean.

3. Layout versus schematic:

```
% ./10-lvs/run
```

   This extracts a transistor netlist from your GDS and compares it against the
   netlist from week 9. Read `lvs.rpt`.

   LVS reports come in two flavours and they mean different things. A device
   mismatch means the layout has different transistors than the schematic. A net
   mismatch means the connectivity differs, which usually means a short or an
   open. Net mismatches are the ones that would kill a chip.

   Re-run until clean.

4. Write your signoff summary. One page, covering: setup and hold slack with the
   corner each came from, DRC status, LVS status, and anything still open with a
   specific reason it is still open.

   If something did not close, say so with numbers. A documented near-miss is a
   real result. A faked pass is not, and it is the one thing in this program
   that will actually get someone in trouble at a real company.

**Deliverable**

```
% cd ~/longhorn-apprentice/pe-apprentice
% git commit --allow-empty -m "week 10: signoff"
% git bundle create ~/<your-username>-week10.bundle main..<your-username>
```

Transfer the bundle off the chamber, plus, from your run directories:

- The final `pe_array_2x2.gds`
- `06-tempus-sta/latest/reports/` setup and hold reports
- `09-drc/latest/drc.rpt`
- `10-lvs/latest/lvs.rpt`
- Your one page signoff summary

**Done means**
- A GDS exists, generated, not planned
- Setup and hold slack reported at the correct corners, and you can say which
  corner each came from and why
- DRC report included and clean, or every remaining violation named with a
  reason it is open
- LVS report included and clean, or every remaining mismatch named
- Your summary is honest about anything that did not close

**If you finish early**
Two more steps are written and runnable, and they are the two most interesting
ones nobody has time for:

```
% ./07-xcelium-baglsim/run     # your testbench, with wire delays back-annotated
% ./08-voltus-pwr/run          # power, from measured switching activity
```

Step 07 is where a hold violation stops being a number in a report and becomes a
test that fails in front of you. Worth doing if you can.
