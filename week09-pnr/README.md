# Week 9: Place and Route

**Goal:** Turn your gate netlist into a physical layout, with every cell in a
place and every wire drawn.

**Not written yet.** This handout is still being finished.

## What it will cover

Innovus takes `../week07-synthesis/post-synth.v` and gives every gate an x and a
y, then draws every wire between them. The output is a GDS.

You route `rtl/pe_array_2x2.sv`, four of your PEs, not one.

Once wires exist they have length, and length costs delay. Synthesis estimated
those delays. Now they get measured. That is why post-route timing is almost
always worse than post-synthesis timing, and why a design that closed in week 7
can fail this week.

Work in pairs. Check `df -h ~` before you start; Innovus runs are 1 to 3 GB and
you have 20 GB.

Innovus and its licenses are confirmed working on the chamber. The flow script
is what is missing. Ask a lead where it stands.
