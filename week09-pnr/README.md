# Week 9: Place and Route

**Goal:** Turn your gate netlist into a physical layout, with every cell in a
place and every wire drawn, and write out a GDS.

Work in pairs. Innovus is heavy and the chamber is shared with other
universities.

Every command below was run on the chamber. The numbers quoted are what the
reference PE produced. Yours should land nearby; if one is wildly different,
understand why before continuing.

## 1. Setup

```bash
srun -c 4 --mem=16G --pty bash
source ~/pe-apprentice/setup.sh
mkdir -p ~/pe-apprentice/week09-pnr/work
cd ~/pe-apprentice/week09-pnr/work
ls ../../week07-synthesis/post-synth.v ../../week07-synthesis/post-synth.sdc
```

Both week 7 files must exist. `post-synth.v` is your gate netlist and
`post-synth.sdc` is the constraints Genus wrote back out. If they are missing,
go finish week 7.

A full run leaves about 8 MB behind. Disk is not a concern at this scale, but
check `df -h ~` anyway; real blocks are thousands of times bigger and the habit
is the point.

## 2. Write the timing setup file

Innovus needs to know which libraries, at which corners, with which constraints,
**before** the design loads. That configuration is called MMMC, multi-mode
multi-corner.

```bash
printf '%s\n' \
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
cat mmmc.tcl
```

Read the ten lines. A **library set** is a `.lib`. A **timing condition** wraps
a library set. A **delay corner** wraps a timing condition. An **analysis view**
pairs a delay corner with constraints, and `set_analysis_view` says which view
checks setup and which checks hold.

Setup is checked at the slow corner because slow silicon is when data arrives
latest. Hold is checked at the fast corner because fast silicon is when data
arrives earliest and can race through a flop. One corner cannot check both.

A production chip has far more than two views. Real blocks run a dozen or more
across voltage, temperature, and process, and a large part of physical design is
deciding which subset is worth the runtime.

## 3. Load the design

```bash
innovus -stylus
```

Innovus starts and checks out a license. Look for
`invs Innovus Implementation System 21.1 checkout succeeded` and an
`@innovus 1>` prompt. If it dies on a license, send a lead the exact message.

Everything below is typed at that prompt, one line at a time.

```tcl
read_mmmc mmmc.tcl
```

Loads both `.lib` files. Expect `Read 489 cells in library 'slow_vdd1v0'`, the
same for `fast_vdd1v0`, then `timing_initialized`. The
`No function defined for cell 'DECAP9'` warnings are normal; decoupling
capacitors have no logic function.

**This must come first.** If you create the library sets by typing them at the
prompt instead, `init_design` sees no MMMC, comes up in physical-only mode, and
every timing command afterwards fails with `TA-965`. That failure appears eight
commands later with no hint of the cause, which is exactly the kind of thing
that costs an afternoon.

```tcl
read_physical -lef [list $env(LEF_TECH) $env(LEF_MACRO)]
```

Loads the two LEF files. The technology LEF describes metal layers and spacing
rules; the macro LEF describes each cell's physical shape. Pure geometry, no
timing. The `ANTENNA` macro warning is a known gap in this kit.

```tcl
read_netlist ../../week07-synthesis/post-synth.v -top pe
```

Reads your gate netlist. Two lines matter: `Hooked 978 DB cells to tlib cells`
proves the netlist bound to the timing libraries, and `1142 stdCell insts`
should match what Genus reported. **If it says `Hooked 0`, your MMMC did not
load** and everything after this will be wrong.

```tcl
init_design
```

Builds the database, creates routing tracks, reads your SDC. The `CornerSite`
and `IOSite` warnings are normal since gsclib045's standard cells only use
`CoreSite`. At the end it prints the buffer and inverter lists the tool may use.

```tcl
set_db design_process_node 45
```

Tells Innovus this is 45 nm. Watch what it prints back:

```
Applying the recommended capacitance filtering threshold values for 45nm:
total_c_th=0, relative_c_th=1, coupling_c_th=0.1
```

It is not a label. It changes the thresholds extraction uses later. Leave it out
and the tool assumes 90 nm and your parasitics are computed against the wrong
process.

```tcl
report_timing -nworst 1
```

Timing before anything is placed. The reference PE reports **−0.020 ns** where
Genus reported 0.000 on the identical netlist. Two tools, same logic, 20 ps
apart. Remember that the next time somebody quotes a timing number without
saying which tool produced it.

## 4. Floorplan

```tcl
create_floorplan -site CoreSite -core_density_size 1.0 0.7 5 5 5 5
```

Creates the die and core. The numbers are aspect ratio 1.0 (square), target
density 0.7, and 5 µm of margin on each side for the power ring. The reference
PE lands on a die of about 72 × 72 µm with a core of about 62 × 62 µm.

gsclib045 has two core sites, `CoreSite` at 1.71 µm tall and `CoreSiteDouble` at
3.42 µm, so Innovus lays down rows of both heights and picks per cell. You can
see all 53 of them later in the DEF.

Density is a guess at this stage and it will not hold; optimization adds cells.
The reference PE was asked for 0.7 and finished at 0.93.

```tcl
gui_show
gui_fit
```

Opens the layout window and zooms to fit. An empty core rectangle filled with
horizontal rows. Keep it open; the rest of this week makes far more sense
looking at it than reading about it.

## 5. Place your pins

This is where your week 8 sketch becomes real. Until you do this, every port is
unplaced and the router treats it as floating.

Two numbers from the tech LEF decide how the commands below are written. Read
them yourself; do not take them from here.

```bash
grep -A4 "^LAYER Metal2$" $LEF_TECH
grep -A4 "^LAYER Metal3$" $LEF_TECH
```

`DIRECTION` says which way wires on that layer prefer to run. A pin on the west
or east edge is reached by a horizontal wire, so it goes on the horizontal
layer; a north or south pin goes on the vertical one. `PITCH` and `OFFSET`
define the routing tracks: track `n` sits at `OFFSET + n × PITCH`. A pin
belongs on a track, and two tracks between pins is the usual minimum that lets
the router reach a pin without touching its neighbour. `setup.sh` names the two
layers as `PIN_LAYER_H` and `PIN_LAYER_V`; check them against what you just
read, and copy the four numbers into the block below.

The other thing a PE's pins have to do is line up with the PE next door: bit
`i` of `pe_input_in` on the west edge at the same height as bit `i` of
`pe_input_out` on the east edge, and the same for the two north/south pairs.
Two PEs placed side by side then connect with straight wires. That is what
"abuttable" means, and it is why the loop below assigns coordinates instead of
letting the tool spread the pins for you.

```tcl
set hL $env(PIN_LAYER_H)
set vL $env(PIN_LAYER_V)
set bb [get_db designs .bbox]
if {[llength $bb] == 1} { set bb [lindex $bb 0] }
set dieW [lindex $bb 2] ; set dieH [lindex $bb 3]
set pitchH 0.20 ; set offH 0.10 ;# replace both: PITCH and OFFSET of PIN_LAYER_H, from the grep above
set pitchV 0.20 ; set offV 0.10 ;# replace both: same two numbers for PIN_LAYER_V
set n0 [expr {int(ceil((12.0 - $offH) / $pitchH))}] ;# first track past the ring and the corner
set m0 [expr {int(ceil((12.0 - $offV) / $pitchV))}]
proc trk {off pitch n} { return [expr {$off + $n * $pitch}] }

proc pin_at {name side layer x y} {
  edit_pin -pin $name -side $side -layer $layer -assign [list $x $y] -fixed_pin
}
# Place the input pin, read back where Innovus actually put it, and give its
# output partner on the far edge that exact coordinate.
proc pin_pair {in side_in out side_out layer x y} {
  global dieW dieH
  pin_at $in $side_in $layer $x $y
  set loc [get_db [get_db ports $in] .location]
  if {[llength $loc] == 1} { set loc [lindex $loc 0] }
  if {$side_in eq "Left"} { pin_at $out $side_out $layer $dieW [lindex $loc 1] } \
  else                    { pin_at $out $side_out $layer [lindex $loc 0] 0 }
}
for {set i 0} {$i < 16} {incr i} {
  set y [trk $offH $pitchH [expr {$n0 + 2*$i}]]
  pin_pair "pe_input_in\[$i\]"  Left "pe_input_out\[$i\]"  Right  $hL 0  $y
  set x [trk $offV $pitchV [expr {$m0 + 2*$i}]]
  pin_pair "pe_psum_in\[$i\]"   Top  "pe_psum_out\[$i\]"   Bottom $vL $x $dieH
  set x [trk $offV $pitchV [expr {$m0 + 2*(18+$i)}]]
  pin_pair "pe_weight_in\[$i\]" Top  "pe_weight_out\[$i\]" Bottom $vL $x $dieH
}
set y [trk $offH $pitchH [expr {$n0 + 2*17}]] ; pin_pair pe_valid_in  Left pe_valid_out  Right $hL 0 $y
set y [trk $offH $pitchH [expr {$n0 + 2*18}]] ; pin_pair pe_switch_in Left pe_switch_out Right $hL 0 $y
set x [trk $offV $pitchV [expr {$m0 + 2*36}]] ; pin_at pe_accept_w_in Top $vL $x $dieH
set y [trk $offH $pitchH [expr {$n0 + 2*20}]] ; pin_at pe_enabled Left $hL 0 $y
set y [trk $offH $pitchH [expr {$n0 + 2*21}]] ; pin_at clk        Left $hL 0 $y
set y [trk $offH $pitchH [expr {$n0 + 2*22}]] ; pin_at rst        Left $hL 0 $y
```

West in, north in, south out, east out, matching how a PE sits in the grid.
`clk`, `rst` and `pe_enabled` have no neighbour on the other side; in an array
they arrive from a tree, not from the PE to the left, so they sit apart from
the bus. `-fixed_pin` locks every pin so later optimization cannot move it.

Why the read-back: Innovus keeps its own routing tracks, and they are not
always the LEF's. On the lab's kit it built Metal3 tracks at a different pitch
from the one in the tech LEF and then rounded the west and east edges in
opposite directions, so two pins assigned the same `y` landed one track apart.
Asking the tool where it put the first pin and copying that to the partner is
the only way to be sure they share a track. Check it in `post-pnr.def` later:
the `PINS` entries for `pe_input_in[0]` and `pe_input_out[0]` must carry the
same `y`.

```tcl
gui_fit
llength [get_db ports]
```

Marks on all four edges, and 104 ports. Confirm the sides look like your sketch,
and that the input bus on the west and the output bus on the east start at the
same height.

**Why not one `edit_pin` per side with `-spread_type center`?** It is shorter,
and it is what this handout used to say. With no `-spacing`, Innovus packs the
pins at one track pitch in a bunch at the middle of the edge: run on the lab's
sky130 kit with this same Innovus release, 21 west pins landed in a 6.8 µm band
of a 128 µm edge, 33 north pins in 14.7 µm, and because the west edge carries
21 pins and the east 18, bit 0 of `pe_input_in` sat 3.4 µm away from bit 0 of
`pe_input_out`. The design routes, but a PE built that way cannot be tiled. A
bare `-layer 3` is also a layer *index*, and it means a different metal in a
kit that has a local-interconnect layer. Name layers; never number them.

Skip this step entirely and Innovus prints
`IMPVFC-97: IO pin pe_psum_in[5] has not been assigned` for every port, then
routes anyway using a guessed location. On the reference PE, fixing the pins
moved post-route slack from **−1.470 ns to −0.825 ns**, 645 ps, because fixed
pins give placement something to cluster logic against. In a real chip the pin
locations are negotiated with the blocks next door and are usually fixed before
you start, not chosen by you.

## 6. Power

```tcl
create_net -name VDD -power
create_net -name VSS -ground
```

Creates the power and ground nets. **Genus writes a purely logical netlist with
no power in it**, so these do not exist until you make them. Skip this and the
next command fails with `global net 'VDD' doesn't exist in the design`, which
does not hint at the fix.

```tcl
connect_global_net VDD -type pg_pin -pin_base_name VDD -all
connect_global_net VSS -type pg_pin -pin_base_name VSS -all
```

Connects every cell's `VDD` and `VSS` pin to those nets. Every gsclib045 cell has
both, declared in the macro LEF as `USE POWER` and `USE GROUND`. Silent on
success.

```tcl
add_rings -nets {VDD VSS} -type core_rings -follow core \
  -layer {top Metal6 bottom Metal6 left Metal5 right Metal5} \
  -width 1.0 -spacing 0.8 -offset 1.0
```

A ring of power and ground around the core, horizontal on Metal6 and vertical on
Metal5. Expect `add_rings created 8 wires` and 8 Via5: two nets times four sides.
Upper metals are used because they are thicker and carry more current.

```tcl
add_stripes -nets {VDD VSS} -layer Metal5 -direction vertical \
  -width 0.8 -spacing 0.8 -set_to_set_distance 20
```

Vertical stripes every 20 µm so current does not have to reach the middle of the
core through thin wire. Expect `add_stripes created 8 wires`. Every stripe also
steals routing space, and choosing that balance is a real job at scale: too few
and the chip browns out under load, too many and signals cannot get through.

```tcl
route_special -connect core_pin -nets {VDD VSS}
```

Connects the ring and stripes down to the horizontal rails running along every
row. Look for `Number of Followpin connections: 37`, one per row, and
`Metal1 111` wires. Those Metal1 wires are the rails the cells sit on.

```tcl
gui_fit
```

Worth studying. Orange horizontal bars are the Metal6 ring, red verticals are
the Metal5 stripes, blue horizontals filling the core are the Metal1 rails.
Everything needed to power a cell now exists, and no cells do.

## 7. Place

```tcl
place_opt_design
```

Puts every cell somewhere, then optimizes timing by resizing cells and inserting
buffers. A few minutes. The reference PE finishes around **WNS −0.8 ns, density
93%**. Two `IMPSP-9099` errors about scan chains are printed on every design
without scan logic in this release; they change nothing and you can ignore them.

Two things to notice. Timing is much worse than the −0.020 from before
placement, because cells now have positions and the wires between them have
length. And density climbed well past the 0.7 you asked for, because
optimization added cells to fix timing. Area and speed trade against each other
and this is where you watch it happen.

```tcl
gui_fit
```

The core is full. Compare against the empty rows from step 4.

## 8. Clock tree

```tcl
ccopt_design
```

Builds the clock tree. Until now the clock was assumed to reach every flop
instantly, which is not physical. This inserts buffers so it arrives at all 82
flip-flops at close to the same time, then re-optimizes.

Look for `Total FF Count : 82`, matching your synthesis flop count. Timing gets
worse again, because the clock tree itself has delay. On large chips the clock
network can burn a third of total power, which is why clock gating exists.

## 9. Route

```tcl
route_design
```

Draws every signal wire. About 30 seconds here. The lines to find:

```
#Total number of DRC violations = 0
#Total number of process antenna violations = 0
#Total wire length = 15126 um.
```

Zero DRC means the router obeyed every spacing and width rule. Zero antenna
means no wire is long enough to damage a gate during manufacturing. The
per-layer breakdown is worth a look: most routing landed on Metal2 and Metal3,
almost nothing above Metal7. Upper metals are reserved for power and long global
nets, and on a real chip that reservation is planned, not accidental.

```tcl
gui_fit
```

Fully routed. Turn layers on and off in the panel on the right to see one metal
at a time. This is the clearest picture you will get of what your design
physically is.

```tcl
opt_design -post_route
```

A final optimization now that wires are real. You will see
`ERROR: (IMPOPT-6080): AAE-SI Optimization can only be turned on when the timing
analysis mode is set to OCV`. Expected in our setup, does not stop the flow.

## 10. Extract

```tcl
extract_rc
```

Measures the resistance and capacitance of every wire built. The reference PE
extracts **22545 resistors, 22749 ground caps, 40304 coupling caps**. Up to now
every timing number came from an estimate; from here they come from geometry.

The warning about no cap table means Innovus built an approximate one from the
LEF. Acceptable for this program. A tapeout uses a foundry-characterized table
and the difference is not small.

```tcl
report_timing -nworst 1        > timing_postroute.rpt
report_timing -nworst 1 -early > timing_postroute_hold.rpt
report_area                    > area_postroute.rpt
```

The second report is hold, checked at the fast corner through the `hold_view`
you set up in step 2. Setup asks whether data arrives in time; hold asks
whether it arrives too early and races through the flop. Both have to pass for
the chip to work, and week 10 reports both. If hold is negative here:

```tcl
opt_design -post_route -hold
```

inserts delay where data arrives too soon. It is cheap on a design this size.

## 11. Fill, then check that it can be built

```tcl
add_fillers -base_cells [get_db [get_db base_cells FILL*] .name]
```

Every empty site in every row gets a filler cell, so the n-well and the power
rails are continuous from one end of the row to the other. A row with gaps in
it fails DRC at the foundry even when the routed wires are perfect, which is
why fill goes in before the checks and before the GDS, never after. Look for
the count it prints.

Four checks, four different questions. Note that three take `-out_file` and one
takes `-report`; that inconsistency is Cadence's, not a typo.

Four checks, four different questions. Note that three take `-out_file` and one
takes `-report`; that inconsistency is Cadence's, not a typo.

```tcl
check_drc -out_file drc.rpt
```

Design Rule Check: does the geometry obey the foundry's manufacturing rules.
Minimum spacing, minimum width, layer overlap. A layout that breaks them cannot
be made.

```tcl
check_connectivity -type all -out_file conn.rpt
```

Is every net that should exist actually drawn, and is nothing shorted. DRC checks
shapes, this checks electrical intent. A layout can pass one and fail the other.

```tcl
check_process_antenna -out_file antenna.rpt
```

During manufacturing a long metal wire attached to a gate, before its protection
diode exists, can collect enough charge to punch through the gate oxide. This
finds wires long enough to do it. The usual fix is a diode or a jump to another
layer.

```tcl
check_metal_density -report density.rpt
```

Foundries require each metal layer to be neither too empty nor too full, because
chemical-mechanical polishing removes material unevenly otherwise. Sparse
regions get filled with dummy metal at tapeout.

Now read them:

```bash
less drc.rpt
less conn.rpt
less antenna.rpt
```

A clean DRC report is short:

```
#  Command:           check_drc -out_file drc.rpt
###############################################################

No DRC violations were found
```

Read all four even when clean. You need to recognise the shape of a passing
report to recognise a failing one, and in week 10 you will deliberately make one
fail.

## 12. Write everything out

Four kinds of output, and the difference between them matters.

```tcl
write_db pe_pnr
```

Innovus's own checkpoint, a directory not a file. `read_db pe_pnr` puts you back
exactly here without re-running seven minutes of place and route. Save one before
anything you might want to undo.

```tcl
write_def post-pnr.def
```

Design Exchange Format: the physical data as portable text. Unlike the GDS, you
can read it. Open it and look for four things:

```bash
less post-pnr.def
```

`DIEAREA ( 0 0 ) ( 144800 143640 )` in database units, 2000 per micron, so your
die is about 72 x 72 um. `ROW` lines, one per standard-cell row, naming which
site each uses. `TRACKS` lines, the routing grid for all eleven metal layers.
Then `COMPONENTS`, one line per cell with its type and exact position:

```
- FE_RC_427_0 INVX1 + SOURCE TIMING + PLACED ( 59600 88920 ) N
```

That is an `INVX1`, the cell you looked at in klayout in week 6, at x=29.8 um
y=44.46 um, oriented normally. `SOURCE TIMING` means Innovus added it during
optimization rather than Genus putting it in the netlist, which is why your
component count here is higher than the 1142 Genus reported.

DEF is what you hand another team or another tool. It is also the only physical
output in this flow you can debug by reading.

```tcl
write_netlist post-pnr.v
```

The logical netlist as it now stands, including every buffer and clock-tree cell
that got added. It is not the netlist week 7 gave you.

```tcl
write_sdf post-pnr.sdf
write_parasitics -spef_file post-pnr.spef
```

The measured delay of every cell and wire, and the extracted resistance and
capacitance. Week 10 feeds the SPEF to Tempus.

```tcl
write_stream post-pnr.gds -map_file $env(STREAM_MAP) \
             -merge $env(STDCELLS_GDS) -unit 2000
```

The GDS, which is what a foundry manufactures from. `-map_file` maps Innovus
layer names to the GDS layer numbers the foundry expects. `-merge` pulls in the
full layout of every standard cell, since your design only references them by
name. Confirm `Streamout is finished!` and `Instances 1390`. Without `-merge`
you get a file full of empty boxes, which looks fine until somebody tries to
build it.

```tcl
exit
```

```bash
ls -la
```

You should have `pe_pnr/`, `post-pnr.{def,v,sdf,spef,gds}`, four check reports,
and two timing reports.

## 13. Script it

You now know the flow. Put it in a file so you can run it again in one command,
because next week you will want to.

```bash
vi run.tcl
```

Every command from step 3 through step 12, in order, ending with `exit`. Then:

```bash
vi run
```

```bash
#!/usr/bin/env bash
innovus -stylus -no_gui -files run.tcl
```

```bash
chmod +x run
./run
```

`-no_gui` runs headless. You should get the same results without a window
opening. Every production flow runs this way; the GUI is for understanding and
debugging, not for doing.

## 14. Read your log

That run produced `innovus.log`, around 500 KB. The information you actually
want is about fifteen lines of it.

```bash
grep -E "Density:|WNS|Total wire length|DRC violations|unrouted" innovus.log
```

Learning which fifteen lines matter, and how to pull them out of half a megabyte
of noise, is a real skill and nobody will teach it to you directly. Tool logs
are the primary evidence when something goes wrong at 2am before a tapeout
deadline.

## Turn in

```bash
cd ~/pe-apprentice
git add week09-pnr/work/mmmc.tcl week09-pnr/work/run.tcl week09-pnr/work/run
git commit -m "week 9: place and route"
git bundle create ~/<your-username>-week9.bundle main..<your-username>
```

Move the bundle off the chamber, plus:

- `post-pnr.gds`, `post-pnr.def`, `post-pnr.v`, `post-pnr.spef`
- `timing_postroute.rpt`, `timing_postroute_hold.rpt`, `area_postroute.rpt`
- `drc.rpt`, `conn.rpt`, `antenna.rpt`, `density.rpt`
- A screenshot of the routed layout
- Your three setup slack numbers in a row: Genus, Innovus pre-placement,
  Innovus post-route. One sentence on what caused each change. Your hold slack
  and the corner it came from.
- Whether your week 8 pin placement survived contact with the tool, and what you
  would change about it now

## Done means

- The design routes with 0 DRC and 0 antenna violations, with fillers in
- Your pins are on the edges you chose in week 8, on the layer whose direction
  matches the edge, and bit `i` in lines up with bit `i` out in `post-pnr.def`
- `post-pnr.gds` exists and streamout reported the merge
- `./run` reproduces the whole thing headless from a clean shell
- You can point at the layout and say where power enters and how it reaches a cell
- You have read all four check reports, not just the timing one

## If timing did not close

It probably did not. That is expected and week 10 is where you deal with it, not
here. Bring the number.
