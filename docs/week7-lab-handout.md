# Week 7 Lab: Run It

*Week 7 of 11. Handout.*

> **BEING REVISED (2026-08-16).** The commands in this handout predate the
> flow-step layout and the verified chamber paths. Use the `run` script in the
> matching `0N-*/` directory instead, and `docs/00-chamber-and-repo-setup.md`
> for anything chamber-related. The goals, tasks, and deliverables below are
> current; only the command lines are stale.


**Goal:** Actually synthesize your PE and see if your week 6 prediction was right.

**Before you start**
No video this week. Use your week 6 constraints as a starting point.

**Task**
1. Turn your week 6 draft constraints into a real `constraints.sdc`. A template is already in `pe-apprentice/week7-synth/`, edit the numbers to match what you argued for in week 6:
```
create_clock -name clk -period 5.0 [get_ports clk]
set_input_delay -clock clk 0.5 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk 0.5 [all_outputs]
```
2. Start Genus and run synthesis:
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice/week7-synth
% genus
genus:/> read_libs /path/to/stdcells.lib
genus:/> read_hdl -sv ../week3-rtl/pe.sv
genus:/> elaborate
genus:/> read_sdc constraints.sdc
```
3. Run the three synthesis steps. Genus splits this into generic synthesis, technology mapping, then optimization, rather than one black-box `compile` command, so you can see what's happening at each stage:
```
genus:/> syn_generic
genus:/> syn_map
genus:/> syn_opt
```
4. Pull your reports before you touch anything else:
```
genus:/> report_area > area.rpt
genus:/> report_timing > timing.rpt
genus:/> report_power > power.rpt
```
5. Write your outputs, you'll need these for week 9:
```
genus:/> write_hdl > pe_synth.v
genus:/> write_sdc > pe_synth.sdc
genus:/> exit
```
6. Read `timing.rpt`. Find the line with the worst slack, that's your actual critical path. Compare it to what you predicted in week 6.

**Deliverable**
```
% cd ~/longhorn-apprentice/<your_eid>/pe-apprentice
% git add week7-synth/constraints.sdc week7-synth/area.rpt week7-synth/timing.rpt week7-synth/pe_synth.v week7-synth/pe_synth.sdc
% git commit -m "week 7: synthesis"
% git bundle create ~/<your_eid>-week7.bundle main..<your_eid>
```
SFTP `<your_eid>-week7.bundle` off the chamber, plus a short writeup: was your prediction right? If not, what's the actual critical path, and why did you miss it?

**Done means**
- Synthesis completes clean
- Timing report is included and readable
- Writeup correctly reads WNS and TNS off the real report, and gives a real reason for any mismatch with the prediction, not just "I was wrong"
