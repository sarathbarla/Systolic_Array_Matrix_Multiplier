# Timing constraints for 3x3 Systolic Array Matrix Multiplier
# Target Part: AMD Xilinx Artix-7 (xc7a200tsbg484-1)

# Primary Clock definition
# Default: 10.0 ns period (100 MHz target frequency)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Out-of-context I/O delay constraints:
# Constrains data inputs and outputs with a 20% arrival/departure window
set_input_delay -clock clk -max 2.000 [filter [get_ports {rst_n start valid_in clr_acc a_row* b_col*}] {DIRECTION == IN}]
set_input_delay -clock clk -min 0.500 [filter [get_ports {rst_n start valid_in clr_acc a_row* b_col*}] {DIRECTION == IN}]

set_output_delay -clock clk -max 2.000 [filter [get_ports {busy valid_out c*}] {DIRECTION == OUT}]
set_output_delay -clock clk -min 0.500 [filter [get_ports {busy valid_out c*}] {DIRECTION == OUT}]
