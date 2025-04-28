
## Clock Signal
set_property PACKAGE_PIN E3 [get_ports clk]              
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name clk -period 10.00 [get_ports clk]

set_property PACKAGE_PIN U9 [get_ports {Sw0}]
set_property IOSTANDARD LVCMOS33 [get_ports {Sw0}]

set_property PACKAGE_PIN E16 [get_ports btn_select]
set_property IOSTANDARD LVCMOS33 [get_ports btn_select]

set_property PACKAGE_PIN F15 [get_ports btn_up]
set_property IOSTANDARD LVCMOS33 [get_ports btn_up]

set_property PACKAGE_PIN T16 [get_ports btn_left]
set_property IOSTANDARD LVCMOS33 [get_ports btn_left]

set_property PACKAGE_PIN R10 [get_ports btn_right]
set_property IOSTANDARD LVCMOS33 [get_ports btn_right]

set_property PACKAGE_PIN V10 [get_ports btn_down]
set_property IOSTANDARD LVCMOS33 [get_ports btn_down]
