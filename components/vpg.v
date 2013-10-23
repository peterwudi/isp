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

`include "vpg.h"

module vpg(
		   clk_100,
		   reset_n,
		   mode,
		   mode_change,
		   disp_color,
		   vpg_pclk,
		   vpg_de,
		   vpg_hs,
		   vpg_vs,
		   vpg_r,
		   vpg_g,
		   vpg_b
	      );


input			clk_100;
input			reset_n;
input	[3:0]	mode;
input			mode_change;
input	[1:0]	disp_color; 
output			vpg_pclk;
output			vpg_de;
output			vpg_hs;
output			vpg_vs;
output	[7:0] 	vpg_r;
output	[7:0] 	vpg_g;
output	[7:0] 	vpg_b;


//============= config sequnce control
`define CONFIG_NONE						0	
`define CONFIG_INIT						1
`define CONFIG_PLL_INT					2
`define CONFIG_PLL_READ_CONFIG			3
`define CONFIG_PLL_READ_CONFIG_DONE		4
`define CONFIG_PLL_UPDATE_CONFIG		5
`define CONFIG_PLL_UPDATE_CONFIG_DONE	6
`define CONFIG_PLL_WAIT_STABLE			7
`define CONFIG_START_VPG  				8

reg		[3:0]	config_state;
reg		[3:0]	disp_mode;
reg 	[2:0]   timing_change_dur;
reg				timing_change;

always @ (posedge clk_100 or negedge reset_n)
begin
	if (!reset_n)
	begin
		//config_state <= `CONFIG_NONE;
		config_state   	  <= `CONFIG_INIT;
		disp_mode 	   	  <= mode;
		pll_reconfig   	  <= 1'b0;
		write_from_rom 	  <= 1'b0;		
		timing_change  	  <= 1'b0;
		timing_change_dur <= 0;
	end	
	else if (mode_change)
			begin
				config_state 	  <= `CONFIG_INIT;
				disp_mode 		  <= mode;
				pll_reconfig 	  <= 1'b0;
				write_from_rom 	  <= 1'b0;
				timing_change 	  <= 1'b0;
				timing_change_dur <= 0;
	end
	else if (config_state == `CONFIG_INIT)
			begin
				config_state <= `CONFIG_PLL_INT;
			end
	else if (config_state == `CONFIG_PLL_INT)
			begin
				pll_reconfig   <= 1'b0;
				write_from_rom <= 1'b0;
				config_state   <= `CONFIG_PLL_READ_CONFIG;
			end
	else if (config_state == `CONFIG_PLL_READ_CONFIG && !pll_busy)
			begin
				config_state   <= `CONFIG_PLL_READ_CONFIG_DONE;
				write_from_rom <= 1'b1;
			end
	else if (config_state == `CONFIG_PLL_READ_CONFIG_DONE && !pll_busy)
			begin
				config_state   <= `CONFIG_PLL_UPDATE_CONFIG;
				write_from_rom <= 1'b0;
			end	
	else if (config_state == `CONFIG_PLL_UPDATE_CONFIG && !pll_busy)
			begin
				config_state <= `CONFIG_PLL_UPDATE_CONFIG_DONE;
				pll_reconfig <= 1'b1;
			end	
	else if (config_state == `CONFIG_PLL_UPDATE_CONFIG_DONE && !pll_busy)
			begin
				pll_reconfig <= 1'b0;
				config_state <= `CONFIG_PLL_WAIT_STABLE;
			end		
	else if (config_state == `CONFIG_PLL_WAIT_STABLE && gen_clk_locked)
			begin
				config_state      <= `CONFIG_START_VPG;
				timing_change_dur <= 3'b111;
				timing_change     <= 1'b1;
	end		
	else if (config_state == `CONFIG_START_VPG)
			begin
				if (timing_change_dur)
					timing_change_dur <= timing_change_dur - 1'b1;
			else	
				begin
					config_state  <= `CONFIG_NONE;
					timing_change <= 1'b0;
				end	
			end
	
		
end




//============= assign timing constant

reg 	[11:0] 	h_disp;
reg 	[11:0] 	h_fporch;
reg 	[11:0]  h_sync;
reg 	[11:0]  h_bporch;
reg 	[11:0]  v_disp;
reg 	[11:0]  v_fporch;
reg 	[11:0]  v_sync;
reg 	[11:0]  v_bporch;
reg			    hs_polarity;
reg			    vs_polarity;
reg			    frame_interlaced;

// sync_polarity = 0: 
// ______    _________
//       |__|
//        sync (hs_vs)
//
// sync_polarity = 1: 
//        __
// ______|  |__________
//       sync (hs/vs)




always @(posedge clk_100)
begin
	if (config_state == `CONFIG_INIT) 
	begin
	case(disp_mode)
		`VGA_640x480p60: begin  // 640x480@60 25.175 MHZ
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd640, 12'd16, 12'd96, 12'd48}; 
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd480, 12'd10, 12'd2,  12'd33}; 
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end
	
		`MODE_720x480: begin  // 720x480@60 27MHZ (VIC=3, 480P)
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd720, 12'd16, 12'd62, 12'd60}; // total: 858
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd480, 12'd9, 12'd6,  12'd30};  // total: 525
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end
		`MODE_1024x768: begin //1024x768@60 65MHZ (XGA)
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd1024, 12'd24, 12'd136, 12'd160}; 
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd768,  12'd3,  12'd6,   12'd29}; 
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end
		`MODE_1280x1024: begin //1280x1024@60   108MHZ (SXGA) ???check again
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd1280, 12'd48, 12'd112, 12'd248}; 
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd1024,  12'd1,  12'd3,   12'd38}; 
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end	
		`FHD_1920x1080p60: begin
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd1920, 12'd88, 12'd44, 12'd148};
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd1080,  12'd4, 12'd5,  12'd36};
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end		
		`VESA_1600x1200p60: begin
			{h_disp, h_fporch, h_sync, h_bporch} <= {12'd1600, 12'd64, 12'd192, 12'd304};
			{v_disp, v_fporch, v_sync, v_bporch} <= {12'd1200,  12'd1,  12'd3,   12'd46};
			{frame_interlaced, vs_polarity, hs_polarity} <= 3'b000;
		end
	endcase
	end
end

//=============== PLL reconfigure

wire 	gen_clk;
wire 	gen_clk_locked;

wire	  pll_areset; //
wire	  pll_configupdate;//
wire	  pll_scanclk;//
wire	  pll_scanclkena;//
wire	  pll_scandata;//
wire	  pll_scandataout;//
wire	  pll_scandone;//
	
wire	  pll_busy;
reg		  pll_reconfig;

gen_pll gen_pll_inst(
					 .areset(pll_areset),
					 .configupdate(pll_configupdate),
					 .inclk0(clk_100),
					 .scanclk(pll_scanclk),
					 .scanclkena(pll_scanclkena),
					 .scandata(pll_scandata),
				     .c0(gen_clk),
					 .locked(gen_clk_locked),
					 .scandataout(pll_scandataout),
					 .scandone(pll_scandone)
					);
	

pll_reconfig pll_reconfig_inst(
							   .clock(clk_100),
							   .counter_param(),
							   .counter_type(),
							   .data_in(),
							   .pll_areset_in(~reset_n),
							   .pll_scandataout(pll_scandataout),
							   .pll_scandone(pll_scandone),
							   .read_param(),
							   .reconfig(pll_reconfig),
						       .reset(~reset_n),
							   .reset_rom_address(~reset_n),
							   .rom_data_in(rom_data),
							   .write_from_rom(write_from_rom),
							   .write_param(),
							   .busy(pll_busy),
							   .data_out(),
							   .pll_areset(pll_areset),
							   .pll_configupdate(pll_configupdate),
							   .pll_scanclk(pll_scanclk),
							   .pll_scanclkena(pll_scanclkena),
							   .pll_scandata(pll_scandata),
							   .rom_address_out(rom_addr),
							   .write_rom_ena(rom_read)
							   );
							


//================== select PLL reconfigur ROM	
	
`define PLL_25		0	
`define PLL_27		1
`define PLL_65		2
`define PLL_108		3
`define PLL_148		4
`define PLL_162		5
	
reg [2:0]	pllconfig_select;	

always @(posedge clk_100)
begin
	if (config_state == `CONFIG_INIT) 
		begin
			case(disp_mode)
				`VGA_640x480p60: 
								begin  
									pllconfig_select <= `PLL_25;
								end
				`MODE_720x480: 
							    begin  // 720x480@60 27MHZ (VIC=2/3, 480P) 16:9
									pllconfig_select <= `PLL_27;
								end
				`MODE_1024x768: begin //1024x768@60 65MHZ (XGA)
									pllconfig_select <= `PLL_65;
								end
				`MODE_1280x1024: begin //1280x1024@60   108MHZ (SXGA) ???check again
									pllconfig_select <= `PLL_108;
								 end
				`FHD_1920x1080p60: begin 
								    pllconfig_select <= `PLL_148;
								   end
				`VESA_1600x1200p60: begin 
										pllconfig_select <= `PLL_162;
									end
				endcase
		end
end


rom_selector rom_selector_inst(
							   .data0(rom_data_25),
							   .data1(rom_data_27),
							   .data2(rom_data_65),
							   .data3(rom_data_108),
							   .data4(rom_data_148),
							   .data5(rom_data_162),
							   .sel(pllconfig_select),
							   .result(rom_data)
							  );	
	
	
wire 			rom_data;	
wire 			rom_data_25;	
wire 			rom_data_27;	
wire 			rom_data_65;	
wire 			rom_data_108;	
wire 			rom_data_148;	
wire 			rom_data_162;	
wire 	[7:0]	rom_addr;
wire 			rom_read;
reg       	    write_from_rom;
	
	
rom_pll_25 rom_pll_25_inst(
						   .address(rom_addr),
						   .clock(clk_100),
						   .rden(rom_read),
						   .q(rom_data_25)
						  );
	
rom_pll_27 rom_pll_27_inst(
						   .address(rom_addr),
						   .clock(clk_100),
						   .rden(rom_read),
						   .q(rom_data_27)
						  );
	
rom_pll_65 rom_pll_65_inst(
						   .address(rom_addr),
						   .clock(clk_100),
						   .rden(rom_read),
						   .q(rom_data_65)
						  );

	
rom_pll_108 rom_pll_108_inst(
							 .address(rom_addr),
							 .clock(clk_100),
							 .rden(rom_read),
							 .q(rom_data_108)
							);
	
rom_pll_148 rom_pll_148_inst(
							 .address(rom_addr),
							 .clock(clk_100),
							 .rden(rom_read),
							 .q(rom_data_148)
							 );
	
rom_pll_162 rom_pll_162_inst(
							 .address(rom_addr),
							 .clock(clk_100),
							 .rden(rom_read),
							 .q(rom_data_162)
							);						


//============ pattern generator: vga timming generator


wire 			time_hs;
wire 			time_vs;
wire 			time_de;

wire 	[11:0]	time_x;
wire 	[11:0]	time_y;

	
vga_time_generator vga_time_generator_inst(
										   .clk(gen_clk),
										   .reset_n(gen_clk_locked),
										   .timing_change(timing_change),
        
									       .h_disp(h_disp),
										   .h_fporch(h_fporch),
										   .h_sync(h_sync),   
										   .h_bporch(h_bporch),
 
										   .v_disp(v_disp),
										   .v_fporch(v_fporch),
										   .v_sync(v_sync),   
										   .v_bporch(v_bporch),   
           
										   .hs_polarity(hs_polarity),
										   .vs_polarity(vs_polarity),
										   .frame_interlaced(frame_interlaced),              
           
										   .vga_hs(time_hs),
										   .vga_vs(time_vs),
										   .vga_de(time_de),
										   .pixel_i_odd_frame(),
										   .pixel_x(time_x),
										   .pixel_y(time_y)
										   );		
	
//===== pattern generator according to vga timing

wire  			gen_hs;
wire  			gen_vs;
wire 			gen_de;
wire 	[7:0]	gen_r;
wire 	[7:0]	gen_g;
wire 	[7:0]	gen_b;

//convert time: 1-clock 
pattern_gen pattern_gen_inst(
							 .reset_n(gen_clk_locked & ~timing_change),
						     .pixel_clk(gen_clk),
							 .pixel_de(time_de),
							 .pixel_hs(time_hs),
							 .pixel_vs(time_vs),
							 .pixel_x(time_x),
							 .pixel_y(time_y),
							 .image_width(h_disp),
							 .image_height(v_disp),
							 .image_color(disp_color),
							 .gen_de(gen_de),
							 .gen_hs(gen_hs),
							 .gen_vs(gen_vs),
							 .gen_r(gen_r),
							 .gen_g(gen_g),
							 .gen_b(gen_b)
							 );


//===== output
assign vpg_pclk = gen_clk;
assign vpg_de 	= gen_de;
assign vpg_hs 	= gen_hs;
assign vpg_vs 	= gen_vs;
assign vpg_r 	= gen_r;
assign vpg_g 	= gen_g;
assign vpg_b 	= gen_b;


endmodule


