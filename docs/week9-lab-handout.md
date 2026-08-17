# Week 9 Lab: Place and Route

*Week 9 of 11. Handout.*

**Goal:** Turn your gate netlist into a physical layout, with every cell in a
specific place and every wire drawn.

**Before you start**
No video this week. Your week 8 floorplan sketch is the starting point. Do not
be surprised when the tool pushes back on parts of it.

**Work in pairs this week and next.** Innovus is heavy and the chamber is shared
with other universities. Two people per run, one driving, both reading. This is
also how it works in industry, and it is how Cornell runs the equivalent lab.

**Check your disk before you start:**

```
% df -h ~
```

Home is 20 GB and an Innovus run directory is 1 to 3 GB. If you are under about
6 GB free, delete old run directories first. A full home fails in confusing ways
rather than with a clean message.

**Background**
Up to now your design has been a list of gates and connections. Place and route
gives every one of those gates an x and a y, and draws every wire between them
on a specific metal layer.

The moment that happens, wires get length, and length costs delay. Synthesis
estimated those delays from a statistical model. Now they are measured. This is
why post-route timing is almost always worse than post-synthesis timing, and why
a design that closed in week 7 can fail this week.

You are routing `rtl/pe_array_2x2.sv`, four of your PEs wired into an array.
Four, not one, because floorplanning a single cell is not a decision. With four
there is a wrong answer and a right answer, and the difference shows up in wire
length.

**Tasks**

1. Confirm step 03 succeeded and its netlist is where step 05 expects it:

```
% cat ~/work/pe/03-genus-synth/latest/STATUS
```

   It should say PASS. If it does not, go back to week 7. You are not ready.

2. Open Innovus interactively and walk the flow by hand, the same way you did
   Genus in week 7:

```
% ./05-innovus-pnr/run --shell
```

   Read `05-innovus-pnr/run.tcl` and type its commands in one at a time. After
   each of the stages below, look at the design in the GUI (`gui_show`) before
   you move on. This is the one week where looking at the picture teaches you
   more than reading the report.

   The stages, and what to look for in each:

   - `init_design`, reads the netlist, the LEF, and the timing setup. Nothing to
     see yet.
   - `floorPlan`, sets die size and core area. Your week 8 sketch becomes numbers
     here. Too tight and placement fails, too loose and you waste area.
   - `addRing` and `addStripe`, power delivery. Every cell needs VDD and VSS, and
     they get there through this grid. Look at how much routing space it eats.
   - `place_design`, every cell gets a location. Look at where your four PEs
     landed relative to each other and ask whether it matches your sketch.
   - `ccopt_design`, clock tree synthesis. The clock has to reach every flop at
     close to the same time. Watch what it inserts to make that happen.
   - `routeDesign`, every wire gets drawn.
   - `extractRC`, measures the resistance and capacitance of what got built.

3. Run the whole flow as a script:

```
% ./05-innovus-pnr/run
```

4. Check post-route timing:

```
% cat ~/work/pe/05-innovus-pnr/latest/reports/timing_postroute.rpt
```

   Compare the worst slack here against your week 7 number. The gap between them
   is the cost of wires, and being able to explain that gap is most of what this
   week teaches.

5. Confirm the design routed completely. Zero unrouted nets, zero DRC violations
   reported by the router. If the router left nets open, your floorplan is too
   tight or your power grid is eating the tracks. Go back to the floorplan; do
   not try to fix it by rerouting.

**Deliverable**

```
% cd ~/longhorn-apprentice/pe-apprentice
% git commit --allow-empty -m "week 9: place and route"
% git bundle create ~/<your-username>-week9.bundle main..<your-username>
```

Transfer the bundle off the chamber, plus, from your run directory:

- `outputs/pe_array_2x2.gds`
- `outputs/pe_array_2x2_pnr.v` and the `.spef`
- `reports/timing_postroute.rpt`
- A screenshot of the routed layout in the Innovus GUI
- Your ECO list: every remaining timing violation with a specific named fix for
  each. "Look at it later" is not a plan. "Upsize the buffer on net X" is.

**Done means**
- Design routes completely, no unrouted nets
- Post-route timing report is included and you can read the worst path off it
- You can explain the difference between your week 7 slack and your week 9 slack
- Your floorplan choice has a reason behind it that you can state
- Every remaining violation has a specific, named fix plan
