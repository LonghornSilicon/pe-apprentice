# ============================================================================
# constraints.sdc.  Yours. You set these numbers in week 7.
# ----------------------------------------------------------------------------
# This is a template with placeholder values that are deliberately loose. Your
# week-6 deliverable was an argument for a specific clock period. Put that
# number here and be ready to defend it. "It was in the template" is not
# an answer.
#
# SDC is the contract between you and the tool. Synthesis does not know what
# speed you want, what drives your inputs, or what your outputs drive. If you
# do not tell it, it invents something, and its invention is usually either so
# pessimistic you burn area for nothing or so optimistic the design fails in
# silicon. Every line below is you closing one of those gaps.
# ============================================================================

# ---- Clock -----------------------------------------------------------------
# gsclib045 is a 45 nm kit; simple datapaths in it typically land somewhere in
# the 400-700 MHz range at the slow corner. 4.0 ns (250 MHz) is intentionally
# loose so the first pass closes and gives you a report to read. Once you have
# a baseline, tighten it and re-run: 4.0 -> 2.5 -> 2.0 -> 1.5 ns. The period at
# which slack first goes negative is your design's actual fmax, and finding it
# is worth more than any single number you could have guessed up front.
create_clock -name clk -period 4.0 [get_ports clk]

# Real clocks are not ideal. Uncertainty covers jitter plus the skew the clock
# tree will add in place-and-route, which does not exist yet at synthesis time.
# Leaving this out means synthesis signs off on timing that place-and-route
# then breaks.
set_clock_uncertainty 0.20 [get_clocks clk]
set_clock_transition  0.10 [get_clocks clk]

# ---- Boundary conditions ---------------------------------------------------
# Your PE is one cell in an array; its neighbours consume part of the cycle at
# both ends. set_input_delay says "the data arrives this late after the edge";
# set_output_delay says "the next block needs it this early before the edge".
# Budget 20% of the period at each boundary as a starting point.
set_input_delay  -clock clk -max 0.80 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  -clock clk -min 0.00 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk -max 0.80 [all_outputs]
set_output_delay -clock clk -min 0.00 [all_outputs]

# ---- Drive and load --------------------------------------------------------
# Without these, synthesis assumes an infinitely strong driver on every input
# and a zero-capacitance load on every output, and reports timing that cannot
# happen. gsclib045 ships BUFX1/X2/X4/X8; BUFX2 is a reasonable neighbour.
set_driving_cell -lib_cell BUFX2 -pin Y \
    [remove_from_collection [all_inputs] [get_ports clk]]
set_load 0.05 [all_outputs]

# ---- Reset -----------------------------------------------------------------
# rst is asynchronous, so it is not timed against the clock. Saying so stops
# the tool from reporting violations on a path that has no meaning. Do NOT
# reach for set_false_path to silence a path you have not fixed. Here it is
# correct because the path is genuinely not synchronous.
set_false_path -from [get_ports rst]
