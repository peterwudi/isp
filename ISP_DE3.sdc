## Generated SDC file "ISP_DE3.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Full Version"

## DATE    "Thu Oct 24 13:57:53 2013"

##
## DEVICE  "EP3SL150F1152C2"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {DE3_CLK1} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC_BA}]
create_clock -name {DE3_CLK2} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC_BB}]
create_clock -name {DE3_CLK3} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC_BC}]
create_clock -name {DE3_CLK4} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC_BD}]
create_clock -name {DE3_CLK5} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC1_50}]
create_clock -name {DE3_CLK6} -period 20.000 -waveform { 0.000 10.000 } [get_ports {OSC2_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

