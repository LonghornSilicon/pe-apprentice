# Week 10: Signoff

**Goal:** Prove the design meets timing using a dedicated signoff tool, and
prove the layout can actually be manufactured.

Two questions, two tools. Tempus asks *does it run at the speed you claimed*.
Innovus asks *can this geometry be built*.

Work in pairs. Everything below was run on the chamber and the numbers quoted
are what the reference PE produced.

## 1. Setup

```bash
bash
qsh -q normal.q -now n -V
bash
source ~/pe-apprentice/setup.sh
mkdir -p ~/pe-apprentice/week10-signoff/work
cd ~/pe-apprentice/week10-signoff/work
```

Check the banner shows `tempus` and `klayout` with real paths. If either says
`MISSING`, your `setup.sh` is out of date.

You need three files from week 9. Confirm they exist:

```bash
ls ~/pe-apprentice/week09-pnr/work/post-pnr.{v,spef,gds}
```

`post-pnr.v` is the netlist as it stands after every buffer and clock-tree cell
was added. `post-pnr.spef` is the measured resistance and capacitance of every
wire. `post-pnr.gds` is the layout.

---

# Part A: Signoff timing

Innovus already gave you a post-route timing number. So why run another tool?

Because Innovus is an implementation tool. Its timing engine exists to guide
placement and routing decisions, and it makes approximations to stay fast enough
to run inside an optimization loop. Tempus does one job, timing, and does it
more carefully. When a company signs off a chip, this is the number they sign.

## 2. Start Tempus

```bash
tempus
```

You get a `tempus 1>` prompt. Same Tcl shell as Innovus and Genus.

## 3. Load the design

```tcl
read_lib $env(LIB_SS)
```

Reads the slow-corner Liberty. Setup timing is checked at the slow corner
because slow silicon is when data arrives latest.

```tcl
read_verilog ~/pe-apprentice/week09-pnr/work/post-pnr.v
set_top_module pe
```

Reads the post-route netlist and names the top module. This is not the netlist
Genus wrote in week 7; place and route added cells to it.

```tcl
read_spef ~/pe-apprentice/week09-pnr/work/post-pnr.spef
```

Reads the parasitics. This is the whole point: every wire's actual resistance
and capacitance, measured off the geometry that got built. Without this, Tempus
would be guessing the same way synthesis did.

```tcl
read_sdc ~/pe-apprentice/week07-synthesis/post-synth.sdc
```

Reads your constraints, so the tool knows what "fast enough" means.

```tcl
update_timing
```

Builds the timing graph and propagates delays. Read the header it prints:

```bash
# Design Mode: 65nm
# Analysis Mode: MMMC OCV
# Parasitics Mode: SPEF/RCDB
# Signoff Settings: SI Off
```

Four facts about how this run is configured. `SPEF/RCDB` confirms your
parasitics loaded. Note `65nm`, which is wrong; nobody told Tempus this is a
45 nm process. Note also `OCV`.

## 4. Report

```tcl
report_timing -late -max_paths 1
```

`-late` means setup: is data arriving in time. The reference PE reports
**slack −1.406 ns**, on the path from `pe_switch_in` to `pe_psum_out_reg[7]/D`.

```tcl
report_timing -early -max_paths 1
```

`-early` means hold: is data arriving *too soon* and racing through a flop
before it captures the previous value. Setup and hold fail for opposite reasons
and need opposite corners, which is why they are two separate reports.

```tcl
report_timing -late -max_paths 1 > sta_setup.rpt
report_timing -early -max_paths 1 > sta_hold.rpt
exit
```

## 5. Compare the two tools

You now have the same design measured by two signoff-capable tools with
identical inputs:

| | Innovus post-route | Tempus |
|---|---|---|
| Setup slack | see your own report | see your own report |
| Setup time used | 0.107 ns | 0.134 ns |
| Analysis mode | MMMC Non-OCV | MMMC OCV |
| Signal integrity | On | Off |
| Process node assumed | 90 nm | 65 nm |

Same start point, same endpoint, same netlist, same SPEF, and the answers differ
by **64 ps**. Three reasons are visible in the table.

**OCV** stands for on-chip variation. Transistors on opposite corners of a die
are not identical, so a careful analysis pessimises one path against another.
Innovus ran without it, Tempus ran with it.

**Signal integrity** models a switching wire coupling into its neighbour and
shifting its delay. Innovus had it on post-route, Tempus had it off.

**Process node** was guessed by both tools and both guessed wrong, because
nobody set it. That changes the delay models.

None of these tools is lying. They answered slightly different questions and
nobody told them to answer the same one. **A timing number without its analysis
mode, its corner, and its parasitics source attached is not a number.** That is
the single most useful thing to take out of this week.

---

# Part B: Is it manufacturable

## 6. Physical verification

Reopen your routed design in Innovus:

```bash
cd ~/pe-apprentice/week09-pnr/work
innovus -stylus
```

```tcl
read_mmmc mmmc.tcl
read_physical -lef [list $env(LEF_TECH) $env(LEF_MACRO)]
read_netlist post-pnr.v -top pe
init_design
```

```tcl
verify_drc -report drc.rpt
```

Design Rule Check. Every foundry publishes rules about minimum spacing, minimum
width, and layer overlap, because lithography has physical limits. A layout that
breaks them cannot be manufactured. Your `route_design` in week 9 already
reported `Total number of DRC violations = 0`; this confirms it on the finished
design and writes a report.

```tcl
verify_connectivity -type all -report conn.rpt
```

Checks that every net the netlist says should exist is actually drawn, and that
nothing is shorted to anything it should not touch. DRC checks geometry, this
checks electrical intent. A layout can pass one and fail the other.

```tcl
verify_process_antenna -report antenna.rpt
```

During manufacturing, a long metal wire connected to a gate before its
protection diode exists can collect enough charge to blow through the gate
oxide. This finds wires long enough to do that. Week 9 reported zero.

## 7. Look at the GDS with no tool behind it

```bash
klayout -e ~/pe-apprentice/week09-pnr/work/post-pnr.gds &
```

You met klayout in week 6 looking at a single `INVX1`. This is the same viewer
pointed at your own design.

Zoom in until individual cells resolve, then keep zooming until you recognise the
inverter you studied in week 6. It arrived here through `-merge` during
streamout. Everything you built this semester is somewhere in this file as
polygons, and nothing else knows or cares that it was ever Verilog.

---

## 8. Write your signoff summary

One page. It should answer, with numbers:

- Setup slack and hold slack, each with the corner it came from
- Which analysis mode and SI setting produced them
- Why Tempus and Innovus disagree, in your own words
- DRC, connectivity, and antenna status
- Anything still open, named specifically, with a reason

If your timing did not close, say so with the number. A documented near-miss is
a result. A faked pass is the one thing in this program that would actually get
someone in trouble at a real company.

## Turn in

```bash
cd ~/pe-apprentice
git add week10-signoff/work/
git commit -m "week 10: signoff"
git bundle create ~/<your-username>-week10.bundle main..<your-username>
```

Plus `sta_setup.rpt`, `sta_hold.rpt`, `drc.rpt`, `conn.rpt`, `antenna.rpt`, a
klayout screenshot zoomed in far enough to see transistor geometry, and your
one-page summary.

## Done means

- Tempus produced setup and hold numbers from your own SPEF
- You can explain why Tempus and Innovus disagree without reading this handout
- DRC, connectivity, and antenna reports exist and are clean, or every violation
  is named with a reason it is open
- You have looked at your own transistors
- Your summary is honest

## Stretch: Assura

gsclib045 ships full Assura DRC and LVS rule decks at
`/process/hosted/gpdk/gpdk045/oa/v6p0/assura/`, and Assura is installed.

Assura is a signoff physical-verification tool, and unlike the Innovus checks
above it runs the foundry's own rule deck. LVS in particular is something
Innovus cannot do at all: it extracts a transistor netlist out of your polygons
and compares it against the netlist you meant to build, which catches shorts you
drew by accident.

Nobody has got the runset syntax working yet. If you want it, the pieces are
`assuraDRC.rul`, `compare.rul`, `extract.rul`, and the `avParameters(...)` block
shape shown in `fill.rsf`. Talk to a lead first.
