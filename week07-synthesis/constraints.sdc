# Set the clock period to the number you argued for in week 6.
# 4.0 ns is a placeholder that is deliberately loose so a first pass closes.

create_clock -name clk -period 4.0 [get_ports clk]

set_clock_uncertainty 0.20 [get_clocks clk]
set_clock_transition  0.10 [get_clocks clk]

set_input_delay  -clock clk -max 0.80 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  -clock clk -min 0.00 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk -max 0.80 [all_outputs]
set_output_delay -clock clk -min 0.00 [all_outputs]

set_driving_cell -lib_cell BUFX2 -pin Y [remove_from_collection [all_inputs] [get_ports clk]]
set_load 0.05 [all_outputs]

# rst is asynchronous, so it is not timed against the clock.

set_false_path -from [get_ports rst]
