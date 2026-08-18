# Week 9: Place and Route

**Goal:** Turn your gate netlist into a physical layout, with every cell in a
place and every wire drawn, and write out a GDS.

Work in pairs. Innovus is heavy and the chamber is shared with other
universities.

Every command below was run on the chamber. The numbers quoted are what the
reference PE produced, so yours should land in the same neighbourhood. If yours
is wildly different, that is worth understanding before you continue.

## 1. Setup

```
% bash
% qsh -q normal.q -now n -V
% bash
% source ~/pe-apprentice/setup.sh
% df -h ~
```

Innovus writes 1 to 3 GB per run and your home is 20 GB. If you are under about
6 GB free, delete tool output from weeks you have finished before you start.

```
% mkdir -p ~/pe-apprentice/week09-pnr/work
% cd ~/pe-apprentice/week09-pnr/work
% ls ../../week07-synthesis/post-synth.v ../../week07-synthesis/post-synth.sdc
```

Both files must exist. They are what week 7 produced and what this week
consumes. If they are missing, go finish week 7.

## 2. Write the timing setup file

Innovus needs to know which libraries to use, at which corners, with which
constraints, **before** the design is loaded. That configuration is called MMMC:
multi-mode multi-corner.

```
% printf '%s\n' \
'create_library_set -name ss -timing [list $env(LIB_SS)]' \
'create_library_set -name ff -timing [list $env(LIB_FF)]' \
'create_timing_condition -name ss_cond -library_sets {ss}' \
'create_timing_condition -name ff_cond -library_sets {ff}' \
'create_delay_corner -name ss_corner -timing_condition ss_cond' \
'create_delay_corner -name ff_corner -timing_condition ff_cond' \
'create_constraint_mode -name func -sdc_files [list ../../week07-synthesis/post-synth.sdc]' \
'create_analysis_view -name setup_view -constraint_mode func -delay_corner ss_corner' \
'create_analysis_view -name hold_view -constraint_mode func -delay_corner ff_corner' \
'set_analysis_view -setup {setup_view} -hold {hold_view}' \
> mmmc.tcl
% cat mmmc.tcl
```

Read the ten lines you just wrote. A **library set** is a `.lib` file. A
**timing condition** wraps a library set. A **delay corner** wraps a timing
condition. An **analysis view** pairs a delay corner with a set of constraints,
and `set_analysis_view` says which view checks setup and which checks hold.

Setup is checked at the slow corner because slow silicon is when data arrives
latest. Hold is checked at the fast corner because fast silicon is when data
arrives earliest and can race through a flop. One corner cannot check both.

## 3. Load the design

```
% innovus -stylus
```

Innovus starts and checks out a license. You should see
`invs Innovus Implementation System 21.1 checkout succeeded` and land at an
`@innovus 1>` prompt. If it dies on a license, send a lead the exact message.

Everything from here is typed at that prompt, one line at a time.

```tcl
read_mmmc mmmc.tcl
```

Reads the file you just wrote and loads both `.lib` files. You should see
`Read 489 cells in library 'slow_vdd1v0'`, the same for `fast_vdd1v0`, and then
`timing_initialized`. The `No function defined for cell 'DECAP9'` warnings are
normal; decoupling capacitors have no logic function.

**If you skip this and try to create the library sets by hand at the prompt,
Innovus comes up in physical-only mode and every timing command fails.** The
MMMC has to arrive from a file, before the design.

```tcl
read_physical -lef [list $env(LEF_TECH) $env(LEF_MACRO)]
```

Loads the two LEF files: the technology LEF describes the metal layers and
spacing rules, the macro LEF describes each cell's physical shape. Nothing about
timing here, purely geometry. The `ANTENNA` macro warning is a known gap in this
kit and does not matter.

```tcl
read_netlist ../../week07-synthesis/post-synth.v -top pe
```

Reads your gate netlist from week 7. Look for two lines: `Hooked 978 DB cells to
tlib cells` proves the netlist bound to the timing libraries, and
`there are 1142 stdCell insts` should match the cell count Genus reported. If it
says `Hooked 0`, your MMMC did not load.

```tcl
init_design
```

Builds the internal database, creates routing tracks, and reads your SDC. The
`CornerSite` and `IOSite` warnings are normal since gsclib045's standard cells
only use `CoreSite`. At the end it prints the buffer and inverter lists the tool
is allowed to use.

```tcl
set_db design_process_node 45
```

Tells Innovus this is a 45 nm process. Without it the tool assumes 90 nm and
extraction is less accurate. One line, easy to forget, and it changes your
numbers.

```tcl
report_timing -nworst 1
```

Your first look at timing inside Innovus, before anything has been placed. The
reference PE reports **−0.020 ns**, where Genus reported 0.000 for the same
netlist. Two tools, same logic, 20 ps apart. That gap is normal and is worth
remembering the next time somebody quotes you a timing number without saying
which tool produced it.

## 4. Floorplan

```tcl
create_floorplan -site CoreSite -core_density_size 1.0 0.7 5 5 5 5
```

Creates the die and core area. The numbers are aspect ratio 1.0 (square), target
density 0.7, and 5 µm of margin on each of the four sides for the power ring.
`CoreSite` is 0.2 × 1.71 µm, so the core fills with rows 1.71 µm tall.

```tcl
gui_show
gui_fit
```

Opens the layout window and zooms to fit. You should see an empty core
rectangle filled with horizontal rows. Nothing is placed yet. Keep this window
open; the rest of this week is much easier to understand by looking at it.

## 5. Power

```tcl
create_net -name VDD -power
create_net -name VSS -ground
```

Creates the power and ground nets. **Genus writes a purely logical netlist with
no power nets in it**, so these do not exist until you make them. Skip this and
the next command fails with `global net 'VDD' doesn't exist in the design`.

```tcl
connect_global_net VDD -type pg_pin -pin_base_name VDD -all
connect_global_net VSS -type pg_pin -pin_base_name VSS -all
```

Connects every cell's `VDD` and `VSS` pin to those nets. Every standard cell in
gsclib045 has both, declared in the macro LEF with `USE POWER` and `USE GROUND`.
Both commands return silently when they work.

```tcl
add_rings -nets {VDD VSS} -type core_rings -follow core \
  -layer {top Metal6 bottom Metal6 left Metal5 right Metal5} \
  -width 1.0 -spacing 0.8 -offset 1.0
```

Draws a ring of power and ground around the core, horizontal segments on Metal6
and vertical on Metal5. You should see `add_rings created 8 wires` and 8 Via5.
Eight because two nets times four sides.

```tcl
add_stripes -nets {VDD VSS} -layer Metal5 -direction vertical \
  -width 0.8 -spacing 0.8 -set_to_set_distance 20
```

Drops vertical VDD and VSS stripes across the core every 20 µm so current does
not have to travel from the ring to the middle through thin wire. You should see
`add_stripes created 8 wires`. `gui_fit` and you will see them.

```tcl
route_special -connect core_pin -nets {VDD VSS}
```

Connects the stripes and ring down to the horizontal power rails that run along
every row. Look for `Number of Followpin connections: 37`, which is one per row,
and `Metal1 111` wires. Those Metal1 wires are the rails the cells actually sit
on.

```tcl
gui_fit
```

Now the picture is worth studying. Orange horizontal bars top and bottom are the
Metal6 ring, red verticals are the Metal5 stripes, and the blue horizontal lines
filling the core are the Metal1 rails. Everything a cell needs to be powered is
now in place, and no cells exist yet.

## 6. Place

```tcl
place_opt_design
```

Puts every cell at a specific location and then optimizes timing by resizing
cells and adding buffers. This takes a few minutes. Watch the summary table at
the end: the reference PE ends at **WNS −0.761 ns, TNS −11.996, 16 violating
paths, density 93.4%**.

Two things to notice. Timing got much worse than the −0.020 you saw before
placement, because cells now have real positions and the wires between them have
real length. And density climbed from the 0.7 you asked for to 0.93, because
optimization added buffers to fix timing.

```tcl
gui_fit
```

The core is now full of cells. Compare it to the empty rows from step 4.

## 7. Clock tree

```tcl
ccopt_design
```

Builds the clock tree. Until now the clock was assumed to reach every flop
instantly, which is not physical. This inserts buffers so the clock arrives at
all 82 flip-flops at close to the same time, then re-optimizes.

Look for `Total FF Count : 82`, which should match the flop count from your
synthesis run. The reference PE ends at **WNS −1.076 ns**. Timing got worse
again, because the clock tree itself has delay.

## 8. Route

```tcl
route_design
```

Draws every signal wire. Takes about 30 seconds on this design. The lines to
find at the end:

```
#Total number of DRC violations = 0
#Total number of process antenna violations = 0
#Total wire length = 15126 um.
```

Zero DRC means the router obeyed every spacing and width rule. Zero antenna
means no wire is long enough to damage a gate during manufacturing. The wire
length breakdown by layer is worth a look: most of the routing landed on Metal2
and Metal3, almost nothing above Metal7.

```tcl
gui_fit
```

Fully routed. Turn layers on and off in the panel on the right to see one metal
layer at a time. This is the clearest picture you will get of what your design
physically is.

```tcl
opt_design -post_route
```

A final optimization pass now that wires are real. You will see
`ERROR: (IMPOPT-6080): AAE-SI Optimization can only be turned on when the timing
analysis mode is set to OCV`. This one error is expected in our setup and does
not stop the flow. Everything after it still runs.

## 9. Extract and report

```tcl
extract_rc
```

Measures the resistance and capacitance of every wire that got built. The
reference PE extracts **22545 resistors, 22749 ground caps, 40304 coupling
caps**. Up to now every timing number came from an estimate; from here they come
from the actual geometry.

The warning about no cap table means Innovus built an approximate one from the
LEF instead of using a characterized file. Fine for this program, not fine for
a tapeout.

```tcl
report_timing -nworst 1 > timing_postroute.rpt
report_area > area_postroute.rpt
```

Writes your two headline reports to files. Open `timing_postroute.rpt` and find
the slack line. Compare it against three earlier numbers you have: what Genus
said, what Innovus said before placement, and what it said after the clock tree.
Those four numbers are the story of this week.

## 10. Write the outputs

```tcl
write_netlist post-pnr.v
```

The gate netlist as it now stands, including every buffer placement and clock
tree optimization added. It is not the same netlist week 7 gave you.

```tcl
write_sdf post-pnr.sdf
```

Standard Delay Format: the measured delay of every cell and wire. This is what a
back-annotated simulation would read to simulate with real timing.

```tcl
write_parasitics -spef_file post-pnr.spef
```

Standard Parasitic Exchange Format: the resistance and capacitance extraction as
a file. Week 10 feeds this to Tempus for signoff timing.

```tcl
write_stream post-pnr.gds -map_file $env(STREAM_MAP) \
             -merge $env(STDCELLS_GDS) -unit 2000
```

Writes the GDS, the file a foundry actually manufactures from. `-map_file` maps
Innovus layer names to the GDS layer numbers the foundry expects. `-merge`
pulls in the full layout of every standard cell, because your design only
references them by name.

Confirm it worked:

```
#####Streamout is finished!
```

and in the statistics, `Instances 1390` and `Via Instances 9189`. Without
`-merge` you would get a file full of empty boxes.

## 11. If your timing did not close

The reference PE ends this week with negative slack, and yours probably will
too. That is a normal outcome, not a failure, and you have three honest options:

- **Relax the clock.** Go back to `week07-synthesis/constraints.sdc`, increase
  the period, re-run week 7, and re-run this week. This is what you would do if
  the target speed was negotiable.
- **Lower the density.** Change `0.7` in step 4 to `0.6` or `0.5`. More room
  means shorter wires. Costs area.
- **Document it.** Write the ECO list described below and be specific.

Pick one, do it, and be able to say why.

## Turn in

Commit `mmmc.tcl` and a `run.tcl` containing every command from steps 3 through
10, ending with `exit`.

```
% cd ~/pe-apprentice
% git add week09-pnr/work/mmmc.tcl week09-pnr/work/run.tcl
% git commit -m "week 9: place and route"
% git bundle create ~/<your-username>-week9.bundle main..<your-username>
```

Move the bundle off the chamber, plus:

- `post-pnr.gds`, `post-pnr.v`, `post-pnr.spef`
- `timing_postroute.rpt` and `area_postroute.rpt`
- A screenshot of the routed layout
- Your four slack numbers in a row: Genus, Innovus pre-place, post-CTS,
  post-route. One sentence on what caused each drop.
- Your ECO list: every remaining violation with a specific named fix. "Look at
  it later" is not a plan. "Relax the clock to 5.5 ns because the multiplier
  path cannot close at 4.0" is.

## Done means

- The design routes with 0 DRC violations and 0 antenna violations
- `post-pnr.gds` exists and streamout reported the merge
- You can point at the floorplan in the GUI and say where power enters and where
  it reaches the cells
- You have four slack numbers and an explanation for each drop
- Every remaining violation has a specific, named fix
