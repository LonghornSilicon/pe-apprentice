# Week 9 Lab: Place and Route

*Week 9 of 11. Handout.*

**Goal:** Turn your gate netlist into a physical layout, with every cell in a
place and every wire drawn.

**Before you start**
No video this week. Your week 8 floorplan sketch is the starting point. Do not
be surprised when the tool pushes back on parts of it.

**Work in pairs this week and next.** Innovus is heavy and the chamber is shared
with other universities. Two people per run, one driving, both reading.

Check your disk first:

```
% df -h ~
```

Home is 20 GB and an Innovus run is 1 to 3 GB. If you are under about 6 GB free,
clean up before you start.

**Background**
Until now your design has been a list of gates and connections. Place and route
gives every gate an x and a y and draws every wire between them.

The moment that happens, wires get length, and length costs delay. Synthesis
estimated those delays. Now they are measured. That is why post-route timing is
almost always worse than post-synthesis timing, and why a design that closed in
week 7 can fail this week.

You are routing `rtl/pe_array_2x2.sv`, four of your PEs in a grid. Four, not one,
because floorplanning a single cell is not a decision.

**Do this**
`05-innovus-pnr/README.md`.

**Deliverable and Done means**
At the bottom of that README.
