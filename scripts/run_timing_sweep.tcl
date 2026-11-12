# Timing sweep across experimental frequencies: 50 MHz, 100 MHz, 125 MHz, 200 MHz
# Evaluates Version B (Enhanced) RTL

close_project -quiet

set PART "xc7a200tsbg484-1"
set TOP_MODULE "systolic_array_3x3"
set REPORT_DIR "reports/timing_sweep"

file mkdir $REPORT_DIR

# Read Version B sources
read_verilog RTL_Code/pe.v
read_verilog RTL_Code/relu.v
read_verilog RTL_Code/quantizer.v
read_verilog RTL_Code/systolic_array_3x3.v

# Synthesize once
synth_design -top $TOP_MODULE -part $PART -mode out_of_context

set periods {20.000 10.000 8.000 5.000}
set freqs   {"50MHz" "100MHz" "125MHz" "200MHz"}

for {set idx 0} {$idx < [llength $periods]} {incr idx} {
    set p [lindex $periods $idx]
    set f [lindex $freqs $idx]

    puts "--> Analyzing Timing at $f (Period: ${p} ns)..."
    create_clock -period $p -name clk [get_ports clk]

    report_timing_summary -file "$REPORT_DIR/timing_${f}.rpt"
}

puts "Timing sweep reports generated in: $REPORT_DIR"
