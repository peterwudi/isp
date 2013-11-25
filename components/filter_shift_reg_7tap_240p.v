// megafunction wizard: %Shift register (RAM-based)%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: ALTSHIFT_TAPS 

// ============================================================
// File Name: filter_shift_reg_7tap_240p.v
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


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module filter_shift_reg_7tap_240p (
	clken,
	clock,
	shiftin,
	shiftout,
	taps0x,
	taps1x,
	taps2x,
	taps3x,
	taps4x,
	taps5x,
	taps6x);

	input	  clken;
	input	  clock;
	input	[23:0]  shiftin;
	output	[23:0]  shiftout;
	output	[23:0]  taps0x;
	output	[23:0]  taps1x;
	output	[23:0]  taps2x;
	output	[23:0]  taps3x;
	output	[23:0]  taps4x;
	output	[23:0]  taps5x;
	output	[23:0]  taps6x;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clken;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [167:0] sub_wire0;
	wire [23:0] sub_wire9;
	wire [167:144] sub_wire13 = sub_wire0[167:144];
	wire [71:48] sub_wire12 = sub_wire0[71:48];
	wire [71:48] sub_wire11 = sub_wire12[71:48];
	wire [143:120] sub_wire10 = sub_wire0[143:120];
	wire [143:120] sub_wire8 = sub_wire10[143:120];
	wire [95:72] sub_wire7 = sub_wire0[95:72];
	wire [95:72] sub_wire6 = sub_wire7[95:72];
	wire [47:24] sub_wire5 = sub_wire0[47:24];
	wire [47:24] sub_wire4 = sub_wire5[47:24];
	wire [119:96] sub_wire3 = sub_wire0[119:96];
	wire [119:96] sub_wire2 = sub_wire3[119:96];
	wire [23:0] sub_wire1 = sub_wire0[23:0];
	wire [23:0] taps0x = sub_wire1[23:0];
	wire [23:0] taps4x = sub_wire2[119:96];
	wire [23:0] taps1x = sub_wire4[47:24];
	wire [23:0] taps3x = sub_wire6[95:72];
	wire [23:0] taps5x = sub_wire8[143:120];
	wire [23:0] shiftout = sub_wire9[23:0];
	wire [23:0] taps2x = sub_wire11[71:48];
	wire [23:0] taps6x = sub_wire13[167:144];

	altshift_taps	ALTSHIFT_TAPS_component (
				.clock (clock),
				.clken (clken),
				.shiftin (shiftin),
				.taps (sub_wire0),
				.shiftout (sub_wire9)
				// synopsys translate_off
				,
				.aclr ()
				// synopsys translate_on
				);
	defparam
		ALTSHIFT_TAPS_component.intended_device_family = "Stratix III",
		ALTSHIFT_TAPS_component.lpm_hint = "RAM_BLOCK_TYPE=AUTO",
		ALTSHIFT_TAPS_component.lpm_type = "altshift_taps",
		ALTSHIFT_TAPS_component.number_of_taps = 7,
		ALTSHIFT_TAPS_component.tap_distance = 326,
		ALTSHIFT_TAPS_component.width = 24;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ACLR NUMERIC "0"
// Retrieval info: PRIVATE: CLKEN NUMERIC "1"
// Retrieval info: PRIVATE: GROUP_TAPS NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix III"
// Retrieval info: PRIVATE: NUMBER_OF_TAPS NUMERIC "7"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "3"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: TAP_DISTANCE NUMERIC "326"
// Retrieval info: PRIVATE: WIDTH NUMERIC "24"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix III"
// Retrieval info: CONSTANT: LPM_HINT STRING "RAM_BLOCK_TYPE=AUTO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altshift_taps"
// Retrieval info: CONSTANT: NUMBER_OF_TAPS NUMERIC "7"
// Retrieval info: CONSTANT: TAP_DISTANCE NUMERIC "326"
// Retrieval info: CONSTANT: WIDTH NUMERIC "24"
// Retrieval info: USED_PORT: clken 0 0 0 0 INPUT VCC "clken"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: shiftin 0 0 24 0 INPUT NODEFVAL "shiftin[23..0]"
// Retrieval info: USED_PORT: shiftout 0 0 24 0 OUTPUT NODEFVAL "shiftout[23..0]"
// Retrieval info: USED_PORT: taps0x 0 0 24 0 OUTPUT NODEFVAL "taps0x[23..0]"
// Retrieval info: USED_PORT: taps1x 0 0 24 0 OUTPUT NODEFVAL "taps1x[23..0]"
// Retrieval info: USED_PORT: taps2x 0 0 24 0 OUTPUT NODEFVAL "taps2x[23..0]"
// Retrieval info: USED_PORT: taps3x 0 0 24 0 OUTPUT NODEFVAL "taps3x[23..0]"
// Retrieval info: USED_PORT: taps4x 0 0 24 0 OUTPUT NODEFVAL "taps4x[23..0]"
// Retrieval info: USED_PORT: taps5x 0 0 24 0 OUTPUT NODEFVAL "taps5x[23..0]"
// Retrieval info: USED_PORT: taps6x 0 0 24 0 OUTPUT NODEFVAL "taps6x[23..0]"
// Retrieval info: CONNECT: @clken 0 0 0 0 clken 0 0 0 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @shiftin 0 0 24 0 shiftin 0 0 24 0
// Retrieval info: CONNECT: shiftout 0 0 24 0 @shiftout 0 0 24 0
// Retrieval info: CONNECT: taps0x 0 0 24 0 @taps 0 0 24 0
// Retrieval info: CONNECT: taps1x 0 0 24 0 @taps 0 0 24 24
// Retrieval info: CONNECT: taps2x 0 0 24 0 @taps 0 0 24 48
// Retrieval info: CONNECT: taps3x 0 0 24 0 @taps 0 0 24 72
// Retrieval info: CONNECT: taps4x 0 0 24 0 @taps 0 0 24 96
// Retrieval info: CONNECT: taps5x 0 0 24 0 @taps 0 0 24 120
// Retrieval info: CONNECT: taps6x 0 0 24 0 @taps 0 0 24 144
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL filter_shift_reg_7tap_240p_bb.v FALSE
// Retrieval info: LIB_FILE: altera_mf
