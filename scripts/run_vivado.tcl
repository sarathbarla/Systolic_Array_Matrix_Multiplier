# Vivado Non-Project Batch Flow Script for Version B (Enhanced)
# Target Device: xc7a200tsbg484-1 (AMD Xilinx Artix-7)

# Close any open designs/projects to prevent in-memory state contamination
close_project -quiet

set PART "xc7a200tsbg484-1"
set TOP_MODULE "systolic_array_3x3"
set OUTPUT_DIR "build_vivado"
set REPORT_DIR "reports/version_B"

file mkdir $OUTPUT_DIR
file mkdir $REPORT_DIR

puts "=========================================================="
puts " Starting Vivado Synthesis & Implementation for Version B"
puts " Target Part: $PART"
puts "=========================================================="

# 1. Read RTL source files for Version B
read_verilog RTL_Code/pe.v
read_verilog RTL_Code/relu.v
read_verilog RTL_Code/quantizer.v
read_verilog RTL_Code/systolic_array_3x3.v

# 2. Run Synthesis (Out of context)
synth_design -top $TOP_MODULE -part $PART -mode out_of_context

# 3. Apply timing constraint
read_xdc constraints/timing.xdc

# 4. Generate post-synthesis reports
report_utilization -file $REPORT_DIR/post_synth_utilization.rpt
report_timing_summary -file $REPORT_DIR/post_synth_timing_summary.rpt

# 5. Implementation flow
opt_design
place_design
phys_opt_design
route_design

# 6. Generate post-route reports
report_utilization -file $REPORT_DIR/post_route_utilization.rpt -hierarchical
report_utilization -file $REPORT_DIR/post_route_utilization_summary.rpt
report_timing_summary -file $REPORT_DIR/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 10 -path_type full -file $REPORT_DIR/post_route_timing_critical_paths.rpt
report_clock_utilization -file $REPORT_DIR/post_route_clock_utilization.rpt
report_power -file $REPORT_DIR/post_route_power.rpt
write_checkpoint -force $OUTPUT_DIR/post_route_checkpoint.dcp

puts "=========================================================="
puts " Version B Implementation Complete!"
puts "=========================================================="
