// megafunction wizard: %Shift register (RAM-based)%VBB%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: ALTSHIFT_TAPS 

// ============================================================
// File Name: demosaic_acpi_G_interploation_240p.v
// Megafunction Name(s):
// 			ALTSHIFT_TAPS
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 13.0.1 Build 232 06/12/2013 SP 1 SJ Full Version
// ************************************************************

//Copyright (C) 1991-2013 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, Altera MegaCore Function License 
//Agreement, or other applicable license agreement, including, 
//without limitation, that your use is for the sole purpose of 
//programming logic devices manufactured by Altera and sold by 
//Altera or its authorized distributors.  Please refer to the 
//applicable agreement for further details.

module demosaic_acpi_G_interploation_240p (
	aclr,
	clken,
	clock,
	shiftin,
	shiftout,
	taps0x,
	taps1x,
	taps2x,
	taps3x,
	taps4x);

	input	  aclr;
	input	  clken;
	input	  clock;
	input	[7:0]  shiftin;
	output	[7:0]  shiftout;
	output	[7:0]  taps0x;
	output	[7:0]  taps1x;
	output	[7:0]  taps2x;
	output	[7:0]  taps3x;
	output	[7:0]  taps4x;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  aclr;
	tri1	  clken;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACLR NUMERIC "1"
// Retrieval info: PRIVATE: CLKEN NUMERIC "1"
// Retrieval info: PRIVATE: GROUP_TAPS NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix III"
// Retrieval info: PRIVATE: NUMBER_OF_TAPS NUMERIC "5"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "3"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: TAP_DISTANCE NUMERIC "320"
// Retrieval info: PRIVATE: WIDTH NUMERIC "8"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix III"
// Retrieval info: CONSTANT: LPM_HINT STRING "RAM_BLOCK_TYPE=AUTO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altshift_taps"
// Retrieval info: CONSTANT: NUMBER_OF_TAPS NUMERIC "5"
// Retrieval info: CONSTANT: TAP_DISTANCE NUMERIC "320"
// Retrieval info: CONSTANT: WIDTH NUMERIC "8"
// Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT VCC "aclr"
// Retrieval info: USED_PORT: clken 0 0 0 0 INPUT VCC "clken"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: shiftin 0 0 8 0 INPUT NODEFVAL "shiftin[7..0]"
// Retrieval info: USED_PORT: shiftout 0 0 8 0 OUTPUT NODEFVAL "shiftout[7..0]"
// Retrieval info: USED_PORT: taps0x 0 0 8 0 OUTPUT NODEFVAL "taps0x[7..0]"
// Retrieval info: USED_PORT: taps1x 0 0 8 0 OUTPUT NODEFVAL "taps1x[7..0]"
// Retrieval info: USED_PORT: taps2x 0 0 8 0 OUTPUT NODEFVAL "taps2x[7..0]"
// Retrieval info: USED_PORT: taps3x 0 0 8 0 OUTPUT NODEFVAL "taps3x[7..0]"
// Retrieval info: USED_PORT: taps4x 0 0 8 0 OUTPUT NODEFVAL "taps4x[7..0]"
// Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
// Retrieval info: CONNECT: @clken 0 0 0 0 clken 0 0 0 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @shiftin 0 0 8 0 shiftin 0 0 8 0
// Retrieval info: CONNECT: shiftout 0 0 8 0 @shiftout 0 0 8 0
// Retrieval info: CONNECT: taps0x 0 0 8 0 @taps 0 0 8 0
// Retrieval info: CONNECT: taps1x 0 0 8 0 @taps 0 0 8 8
// Retrieval info: CONNECT: taps2x 0 0 8 0 @taps 0 0 8 16
// Retrieval info: CONNECT: taps3x 0 0 8 0 @taps 0 0 8 24
// Retrieval info: CONNECT: taps4x 0 0 8 0 @taps 0 0 8 32
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL demosaic_acpi_G_interploation_240p_bb.v TRUE
// Retrieval info: LIB_FILE: altera_mf
