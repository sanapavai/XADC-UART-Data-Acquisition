###############################################################################
# Clock
###############################################################################
set_property PACKAGE_PIN E3 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.000 \
-waveform {0 5} [get_ports CLK100MHZ]

###############################################################################
# UART TX (USB-UART)
###############################################################################
set_property PACKAGE_PIN C4 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

###############################################################################
# XADC Dedicated Analog Inputs
###############################################################################
set_property PACKAGE_PIN A9 [get_ports vp]
set_property PACKAGE_PIN B9 [get_ports vn]

###############################################################################
# XADC Auxiliary Inputs
###############################################################################
set_property PACKAGE_PIN G13 [get_ports vauxp2]
set_property PACKAGE_PIN B11 [get_ports vauxn2]

set_property PACKAGE_PIN A11 [get_ports vauxp3]
set_property PACKAGE_PIN A12 [get_ports vauxn3]

set_property PACKAGE_PIN D12 [get_ports vauxp10]
set_property PACKAGE_PIN D13 [get_ports vauxn10]

set_property PACKAGE_PIN B18 [get_ports vauxp11]
set_property PACKAGE_PIN A18 [get_ports vauxn11]