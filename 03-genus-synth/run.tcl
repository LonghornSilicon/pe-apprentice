# ============================================================================
# run.tcl — Genus synthesis flow for the PE. Given to you; you edit the SDC.
# ----------------------------------------------------------------------------
# Week 7. Genus Common UI (Common UI is the DEFAULT in Genus — unlike Innovus,
# which needs -stylus. That asymmetry is Cadence's, not ours.)
#
# In week 7 you run this interactively FIRST, one command at a time, so you see
# what each stage does to your design. Only then do you use this script. That
# order matters: a script you ran before you understood it is a script you
# cannot debug when it breaks.
#
# All paths come from the environment (tools/lib/pe-env.sh) so there is exactly
# one place where a PDK path is written down.
# ============================================================================

set REPO   $env(PE_ROOT)
set LIB_SS $env(LIB_SS)
set LIB_FF $env(LIB_FF)

file mkdir reports outputs

# ---------------------------------------------------------------------------
# 1. Libraries
# ---------------------------------------------------------------------------
# The library is where the tool learns what gates exist, how big they are, how
# much they leak, and how long they take. Change the library and the same RTL
# gives a different netlist — this file is as much a part of your design as the
# Verilog is.
set_db library [list $LIB_SS]

# ---------------------------------------------------------------------------
# 2. Read and elaborate
# ---------------------------------------------------------------------------
# read_hdl parses. elaborate resolves parameters, builds the hierarchy, and
# infers registers. Most "why did I get a latch" questions are answered by
# reading elaborate's output carefully, so do not skip past it.
read_hdl -sv [list $REPO/rtl/fxp.sv $REPO/rtl/pe.sv]
elaborate pe

# A latch you did not ask for is always a bug — it means a combinational block
# does not assign something on every path. Fail loudly here rather than
# discovering it in place-and-route.
check_design -unresolved

# ---------------------------------------------------------------------------
# 3. Constraints, two corners
# ---------------------------------------------------------------------------
# SETUP is checked at the SLOW corner (0.9 V, 125 C) because slow silicon is
# when data arrives latest. HOLD is checked at the FAST corner (1.1 V, -40 C)
# because fast silicon is when data arrives earliest and can race through a
# flop. One corner cannot check both — that is why multi-corner analysis exists.
read_sdc constraints.sdc

create_constraint_mode -name func -sdc_files [list constraints.sdc]
create_library_set -name ss -timing [list $LIB_SS]
create_library_set -name ff -timing [list $LIB_FF]
create_delay_corner -name ss_corner -library_set ss
create_delay_corner -name ff_corner -library_set ff
create_analysis_view -name view_ss -constraint_mode func -delay_corner ss_corner
create_analysis_view -name view_ff -constraint_mode func -delay_corner ff_corner
set_analysis_view -setup [list view_ss] -hold [list view_ff]

# ---------------------------------------------------------------------------
# 4. Synthesize, in three visible stages
# ---------------------------------------------------------------------------
# Genus splits this deliberately instead of hiding it behind one `compile`:
#   syn_generic  RTL -> generic boolean logic. No real cells yet.
#   syn_map      generic logic -> actual gsclib045 cells. Now it has real delay.
#   syn_opt      timing-driven optimization against your constraints.
# Run report_timing after each of the three the first time you do this by hand.
# Watching the slack move is the fastest way to build intuition for what
# synthesis actually does.
syn_generic
syn_map
syn_opt

# ---------------------------------------------------------------------------
# 5. Reports — pull these BEFORE you touch anything else
# ---------------------------------------------------------------------------
report_qor                              > reports/qor.rpt
report_area    -depth 5                 > reports/area.rpt
report_timing  -nworst 10 -view view_ss > reports/timing_setup.rpt
report_timing  -nworst 10 -view view_ff > reports/timing_hold.rpt
report_power                            > reports/power.rpt
report_gates                            > reports/gates.rpt

# ---------------------------------------------------------------------------
# 6. Outputs — step 04 and step 05 read these
# ---------------------------------------------------------------------------
write_hdl -mapped > outputs/pe_synth.v
write_sdc         > outputs/pe_synth.sdc

puts "==================================================================="
puts " Genus complete."
puts "   Read FIRST : reports/qor.rpt"
puts "   Setup slack: reports/timing_setup.rpt   (the WNS line)"
puts "   Hold  slack: reports/timing_hold.rpt"
puts "   Netlist    : outputs/pe_synth.v         -> steps 04 and 05"
puts "==================================================================="

exit
