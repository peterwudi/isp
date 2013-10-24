// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	Hex7_LUT
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN        :| 07/07/09  :| Initial Revision
// --------------------------------------------------------------------

module Hex_LUT(
	input			[3:0]	iDig,

	output reg	[6:0]	oHex
);

always @(iDig)
begin
		case(iDig)
		4'h1: oHex = 7'b1111001;	// ---t----
		4'h2: oHex = 7'b0100100; 	// |	  |
		4'h3: oHex = 7'b0110000; 	// lt	 rt
		4'h4: oHex = 7'b0011001; 	// |	  |
		4'h5: oHex = 7'b0010010; 	// ---m----
		4'h6: oHex = 7'b0000010; 	// |	  |
		4'h7: oHex = 7'b1111000; 	// lb	 rb
		4'h8: oHex = 7'b0000000; 	// |	  |
		4'h9: oHex = 7'b0011000; 	// ---b----
		4'ha: oHex = 7'b0001000;
		4'hb: oHex = 7'b0000011;
		4'hc: oHex = 7'b1000110;
		4'hd: oHex = 7'b0100001;
		4'he: oHex = 7'b0000110;
		4'hf: oHex = 7'b0001110;
		4'h0: oHex = 7'b1000000;
		endcase
end

endmodule

module Frame_Display (
	input		[7:0]	iDig,
	
	output	[6:0]		oHEX0,
	output	[6:0]		oHEX1
);

Hex_LUT	u0
(
	.oHex(oHEX0),
	.iDig(iDig[3:0])
);

Hex_LUT	u1
(
	.oHex(oHEX1),
	.iDig(iDig[7:4])
);

endmodule

