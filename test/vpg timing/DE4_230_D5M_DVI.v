// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
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
// Major Functions:	DE4_230+D5M+DVI Demo,VGA(640*480) or SXVGA(1280*1024) 
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Peli Li           :| 07/19/2010:| Initial Revision
// --------------------------------------------------------------------
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================
`include "vpg.h"

module DE4_230_D5M_DVI(

	//////// CLOCK //////////
	GCLKIN,
	GCLKOUT_FPGA,
	OSC_50_BANK2,
	OSC_50_BANK3,
	OSC_50_BANK4,
	OSC_50_BANK5,
	OSC_50_BANK6,
	OSC_50_BANK7,
	PLL_CLKIN_p,

	//////// External PLL //////////
	//MAX_CONF_D,
	MAX_I2C_SCLK,
	MAX_I2C_SDAT,

	//////// SMA //////////
	SMA_CLKIN_p,
	SMA_CLKOUT_p,
	//SMA_GXBCLK_p,

	//////// LED x 8 //////////
	LED,

	//////// BUTTON x 4, EXT_IO and CPU_RESET_n //////////
	BUTTON,
	CPU_RESET_n,
	EXT_IO,

	//////// DIP SWITCH x 8 //////////
	SW,

	//////// SLIDE SWITCH x 4 //////////
	SLIDE_SW,

	//////// SEG7 //////////
	SEG0_D,
	SEG0_DP,
	SEG1_D,
	SEG1_DP,


	//////// GPIO_1 //////////
	D5M_D,
	D5M_ESETn,
	D5M_FVAL,
	D5M_LVAL,
	D5M_PIXLCLK,
	D5M_SCLK,
	D5M_SDATA,
	D5M_STROBE,
	D5M_TRIGGER,
	D5M_XCLKIN,

	//////// HSMC-A //////////
	DVI_EDID_WP,
	DVI_RX_CLK,
	DVI_RX_CTL,
	DVI_RX_D,
	DVI_RX_DDCSCL,
	DVI_RX_DDCSDA,
	DVI_RX_DE,
	DVI_RX_HS,
	DVI_RX_SCDT,
	DVI_RX_VS,
	DVI_TX_CLK,
	DVI_TX_CTL,
	DVI_TX_D,
	DVI_TX_DDCSCL,
	DVI_TX_DDCSDA,
	DVI_TX_DE,
	DVI_TX_DKEN,
	DVI_TX_HS,
	DVI_TX_HTPLG,
	DVI_TX_ISEL,
	DVI_TX_MSEN,
	DVI_TX_PD_N,
	DVI_TX_SCL,
	DVI_TX_SDA,
	DVI_TX_VS,
	

	//////// HSMC I2C //////////
	HSMC_SCL,
	HSMC_SDA 
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input		          		GCLKIN;
output		          		GCLKOUT_FPGA;
input		          		OSC_50_BANK2;
input		          		OSC_50_BANK3;
input		          		OSC_50_BANK4;
input		          		OSC_50_BANK5;
input		          		OSC_50_BANK6;
input		          		OSC_50_BANK7;
input		          		PLL_CLKIN_p;

//////////// External PLL //////////
//input		     [4:0]		MAX_CONF_D;
output		          		MAX_I2C_SCLK;
input		          		MAX_I2C_SDAT;

//////////// SMA //////////
input		          		SMA_CLKIN_p;
output		          		SMA_CLKOUT_p;
//input		          		SMA_GXBCLK_p;

//////////// LED x 8 //////////
output		     [7:0]		LED;

//////////// BUTTON x 4, EXT_IO and CPU_RESET_n //////////
input		     [3:0]		BUTTON;
input		          		CPU_RESET_n;
input		          		EXT_IO;

//////////// DIP SWITCH x 8 //////////
input		     [7:0]		SW;

//////////// SLIDE SWITCH x 4 //////////
input		     [3:0]		SLIDE_SW;

//////////// SEG7 //////////
output		     [6:0]		SEG0_D;
output		          		SEG0_DP;
output		     [6:0]		SEG1_D;
output		          		SEG1_DP;



//////////// GPIO_0 //////////
input		    [11:0]		D5M_D;
output		          		D5M_ESETn;
input		          		D5M_FVAL;
input		          		D5M_LVAL;
input		          		D5M_PIXLCLK;
output		          		D5M_SCLK;
input		          		D5M_SDATA;
input		          		D5M_STROBE;
output		          		D5M_TRIGGER;
output		          		D5M_XCLKIN;

//////////// HSMC-A //////////
output		          		DVI_EDID_WP;
input		          		DVI_RX_CLK;
input		     [3:1]		DVI_RX_CTL;
input		    [23:0]		DVI_RX_D;
input		          		DVI_RX_DDCSCL;
input		          		DVI_RX_DDCSDA;
input		          		DVI_RX_DE;
input		          		DVI_RX_HS;
input		          		DVI_RX_SCDT;
input		          		DVI_RX_VS;
output		          		DVI_TX_CLK;
output		     [3:1]		DVI_TX_CTL; //no
output		    [23:0]		DVI_TX_D;
input		          		DVI_TX_DDCSCL; //no
input		          		DVI_TX_DDCSDA; //no
output		          		DVI_TX_DE;
output		          		DVI_TX_DKEN;   //no
output		          		DVI_TX_HS;
output		          		DVI_TX_HTPLG;
output		          		DVI_TX_ISEL;
output		          		DVI_TX_MSEN;   //no
output		          		DVI_TX_PD_N;   //no
output		          		DVI_TX_SCL;
output		          		DVI_TX_SDA;
output		          		DVI_TX_VS;

//////////// HSMC I2C //////////
output		          		HSMC_SCL;
input		          		HSMC_SDA;


//=======================================================
//  REG/WIRE declarations
//=======================================================
//	D5M
wire	[15:0]	Read_DATA1;
wire	[15:0]	Read_DATA2;
wire			VGA_CTRL_CLK;
wire	[11:0]	mCCD_DATA;
wire			mCCD_DVAL;
wire			mCCD_DVAL_d;
wire	[15:0]	X_Cont;
wire	[15:0]	Y_Cont;
wire	[9:0]	X_ADDR;
wire	[31:0]	Frame_Cont;
wire			DLY_RST_0;
wire			DLY_RST_1;
wire			DLY_RST_2;
wire			DLY_RST_3;
wire			DLY_RST_4;
wire			Read;
reg		[11:0]	rCCD_DATA;
reg				rCCD_LVAL;
reg				rCCD_FVAL;
wire	[11:0]	sCCD_R;
wire	[11:0]	sCCD_G;
wire	[11:0]	sCCD_B;
wire			sCCD_DVAL;
wire	[9:0]	oVGA_R;   				//	VGA Red[9:0]
wire	[9:0]	oVGA_G;	 				//	VGA Green[9:0]
wire	[9:0]	oVGA_B;   				//	VGA Blue[9:0]
reg		[1:0]	rClk;

//power on start
wire             auto_start;

//ddr2
wire	ip_init_done;
wire reset_n;
assign reset_n = BUTTON[0];
wire	wrt_full_port0;
wire	wrt_full_port1;
//DVI
wire reset_n_dvi;
wire pll_100M;
wire pll_100K;

wire gen_sck;
wire gen_i2s;
wire gen_ws;

//=======================================================
//  External PLL Configuration ==========================
//=======================================================

//  Signal declarations
wire [ 3: 0] clk1_set_wr, clk2_set_wr, clk3_set_wr;
wire         rstn;
wire         conf_ready;
wire         counter_max;
wire  [7:0]  counter_inc;
reg   [7:0]  auto_set_counter;
reg          conf_wr;


//=======================================================
//  Structural coding
//=======================================================
//D5M
assign	D5M_TRIGGER	=	1'b1;  // tRIGGER
assign	D5M_ESETn	=	DLY_RST_1;
//Fan
assign  FAN_CTRL    =   1'b1;
//DVI
assign DVI_TX_ISEL 	=   1'b0; 	// disable i2c
assign DVI_TX_SCL 	=   1'b1; 	// BSEL=0, 12-bit, dual-edge input
assign DVI_TX_HTPLG =   1'b1; 	// Note. *** EDGE=1, primary latch to occur on the rising edge of the input clock IDCK+
assign DVI_TX_SDA 	=   1'b1;  	// DSEL=X (VREF=3.3V)
assign DVI_TX_PD_N  =   1'b1;

//auto start when power on
assign auto_start = ((BUTTON[0])&&(DLY_RST_3)&&(!DLY_RST_4))? 1'b1:1'b0;



//system clocks generate
sys_pll sys_pll_inst(
	.areset(1'b0),
	.inclk0(OSC_50_BANK2),
	.c0(pll_100M),
	.c1(pll_100K),
	.c2(D5M_XCLKIN),//25M 
	.locked(reset_n_dvi)
	);
//---------------------------------------------------//
//				DVI Mode Change Button Monitor 			 //
//---------------------------------------------------//
wire		[3:0]	vpg_mode;	

assign vpg_mode = `VGA_640x480p60;

//----------------------------------------------//
// 			 Video Pattern Generator	  	   	//
//----------------------------------------------//
wire [3:0]	vpg_disp_mode;
wire [1:0]	vpg_disp_color;
wire vpg_pclk;
wire vpg_de;
wire vpg_hs;
wire vpg_vs;
wire [23:0]	vpg_data;
vpg	vpg_inst(
	.clk_100(pll_100M),
	//.reset_n(read_rstn & reset_n_dvi),//
	.reset_n(reset_n_dvi),//
	.mode(vpg_mode),
	.mode_change(1'b0),
	.disp_color(`COLOR_RGB444),       
	.vpg_pclk(vpg_pclk),
	.vpg_de(vpg_de),
	.vpg_hs(vpg_hs),
	.vpg_vs(vpg_vs),
	.vpg_r(vpg_data[23:16]), //
	.vpg_g(vpg_data[15:8]), //
	.vpg_b(vpg_data[7:0]) //
);
//DVI Signal
assign DVI_TX_DE = vpg_de;
assign DVI_TX_HS = vpg_hs;
assign DVI_TX_VS = vpg_vs;
assign DVI_TX_CLK = vpg_pclk;
//DVI data source selection via SW[0]
assign DVI_TX_D = SW[0] ? {32'hdeadbeef} : vpg_data;

endmodule
