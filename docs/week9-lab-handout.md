# Week 9 Lab: Run It

*Week 9 of 11. Handout.*

> **BEING REVISED (2026-08-16).** The commands in this handout predate the
> flow-step layout and the verified chamber paths. Use the `run` script in the
> matching `0N-*/` directory instead, and `docs/00-chamber-and-repo-setup.md`
> for anything chamber-related. The goals, tasks, and deliverables below are
> current; only the command lines are stale.


**Goal:** Actually place and route your PE array.

**Before you start**
No video this week. Use your week 8 floorplan sketch as a starting point, don't be surprised if the real tool pushes back on parts of it.

**Task**
1. Confirm you have your week 7 outputs (`pe_synth.v`, `pe_synth.sdc`) copied into `pe-apprentice/week9-pnr/`. If you don't, stop, you're not ready for this step yet.
2. Start Innovus and load your design:
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice/week9-pnr
% innovus
innovus:1> read_lef /path/to/tech.lef /path/to/stdcells.lef
innovus:1> read_verilog pe_synth.v
innovus:1> read_sdc pe_synth.sdc
innovus:1> init_design
```
3. Floorplan, turning your week 8 sketch into real numbers:
```
innovus:1> create_floorplan -core_density 0.7 -core_margins_by die -die2core 10 10 10 10
```
4. Power plan, rings around the core then stripes across it:
```
innovus:1> addRing -nets {VDD VSS} -type core_rings -layer {top M6 bottom M6 left M5 right M5} -width 2 -spacing 2
innovus:1> addStripe -nets {VDD VSS} -layer M5 -width 2 -spacing 2
```
5. Place, then check legality before moving on:
```
innovus:1> place_design
innovus:1> check_place
```
6. Clock tree synthesis:
```
innovus:1> create_ccopt_clock_tree_spec
innovus:1> ccopt_design
```
7. Route:
```
innovus:1> route_design
```
8. Extract parasitics and check post-route timing, now with real wire delays instead of the estimates synthesis used:
```
innovus:1> extractRC
innovus:1> timeDesign -postRoute -outDir timing_postroute
```
9. Write your outputs, you'll need these for week 10:
```
innovus:1> write_verilog pe_postroute.v
innovus:1> streamOut pe_layout.gds -mapFile /path/to/stream.map -libName DESIGN -structureName pe
innovus:1> exit
```

**Deliverable**
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice
% git add week9-pnr/pe_postroute.v week9-pnr/pe_layout.gds week9-pnr/timing_postroute
% git commit -m "week 9: place and route"
% git bundle create ~/<your_eid>-week9.bundle main..<your_eid>
```
SFTP `<your_eid>-week9.bundle` off the chamber, plus your ECO list: every remaining violation from the post-route timing report, and a specific plan for each one, not a general intention to look at it later.

**Done means**
- Design routes completely, no unrouted nets
- Timing report is included
- Every remaining violation has a specific, named fix plan
