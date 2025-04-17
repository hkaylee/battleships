
## Clock Signal
set_property PACKAGE_PIN E3 [get_ports ClkPort]              
set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]
create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]

set_property PACKAGE_PIN U9 [get_ports {Sw0}]
set_property IOSTANDARD LVCMOS33 [get_ports {Sw0}]

set_property PACKAGE_PIN E16 [get_ports BtnC]
set_property IOSTANDARD LVCMOS33 [get_ports BtnC]

set_property PACKAGE_PIN F15 [get_ports BtnU]
set_property IOSTANDARD LVCMOS33 [get_ports BtnU]

set_property PACKAGE_PIN T16 [get_ports BtnL]
set_property IOSTANDARD LVCMOS33 [get_ports BtnL]

set_property PACKAGE_PIN R10 [get_ports BtnR]
set_property IOSTANDARD LVCMOS33 [get_ports BtnR]

set_property PACKAGE_PIN V10 [get_ports BtnD]
set_property IOSTANDARD LVCMOS33 [get_ports BtnD]
