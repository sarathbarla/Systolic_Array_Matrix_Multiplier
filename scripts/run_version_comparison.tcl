# Vivado Synthesis & Implementation Script for Baseline (Version A)
# Used for exact comparative PPA analysis (Version A vs. Version B)

close_project -quiet

set PART "xc7a200tsbg484-1"
set TOP_MODULE "systolic_array_3x3"
set REPORT_DIR "reports/version_A"

file mkdir $REPORT_DIR

puts "=========================================================="
puts " Running Vivado for Baseline Version A (Unsigned, No Handshake)"
puts " Target Part: $PART"
puts "=========================================================="

# Read Version A RTL files from backup directory
read_verilog baseline_vA/pe.v
read_verilog baseline_vA/systolic_array_3x3.v

# Run Synthesis (Out of context)
synth_design -top $TOP_MODULE -part $PART -mode out_of_context

# Apply clock constraint
create_clock -period 10.000 -name clk [get_ports clk]

# Post-synthesis reports
report_utilization -file $REPORT_DIR/post_synth_utilization.rpt

# Implementation flow (with phys_opt_design to prevent hold race conditions)
opt_design
place_design
phys_opt_design
route_design

# Post-route reports
report_utilization -file $REPORT_DIR/post_route_utilization_summary.rpt
report_timing_summary -file $REPORT_DIR/post_route_timing_summary.rpt
report_power -file $REPORT_DIR/post_route_power.rpt

puts "=========================================================="
puts " Version A Run Completed! Reports in: $REPORT_DIR"
puts "=========================================================="
