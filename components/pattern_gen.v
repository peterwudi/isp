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

module pattern_gen(
				   reset_n,
				   pixel_clk,
				   pixel_de,
				   pixel_hs,
				   pixel_vs,
				   pixel_x,
				   pixel_y,
				   image_width,
				   image_height,
				   image_color,
				   gen_de,
				   gen_hs,
				   gen_vs,
				   gen_r,
				   gen_g,
				   gen_b
				  );

input			reset_n;
input			pixel_clk;
input			pixel_de;
input			pixel_hs;
input			pixel_vs;
input	[11:0]	pixel_x;
input	[11:0]	pixel_y;
input	[11:0]	image_width;
input	[11:0]	image_height;
input	[1:0]	image_color;
output		    gen_de;
output			gen_hs;
output			gen_vs;
output	[7:0]	gen_r;
output	[7:0]	gen_g;
output	[7:0]	gen_b;

reg				gen_de;
reg				gen_hs;
reg				gen_vs;
reg		[7:0]	gen_r;
reg		[7:0]	gen_g;
reg		[7:0]	gen_b;

////////////////////////////////////////////////
// Pattern Generator
////////////////////////////////////////////////
wire 	[7:0]   h_scale;
assign h_scale = pixel_x;

wire	[11:0]	v_group0;
wire	[11:0]	v_group1;
wire	[11:0]	v_group2;
assign v_group0 = image_height >> 2; //image_height/4;
assign v_group1 = image_height >> 1; //image_height/2;
assign v_group2 = v_group0 + v_group1; //image_height*3/4;


wire 	[7:0]   y_scale;
assign y_scale = h_scale; //16+h_scale%240;    // 16~255



always @(posedge pixel_clk or negedge reset_n)
begin
	if (!reset_n)
	begin
		{gen_r, gen_g, gen_b} <= {8'h00, 8'h00, 8'h00};
		gen_de <= 1'b0;
		gen_hs <= 1'b1;
		gen_vs <= 1'b1;
	end
	else
	begin
		//
		gen_de <= pixel_de;
		gen_hs <= pixel_hs;
		gen_vs <= pixel_vs;	
		//
		if (!pixel_de)
			{gen_r, gen_g, gen_b} <= {8'h00, 8'h00, 8'h00};
		else if (image_color == 0)
		begin
			if ((pixel_x == 0) || ((pixel_x+1) == image_width) ||
				(pixel_y == 0) || ((pixel_y+1) == image_height))  // border
				{gen_r, gen_g, gen_b} <= {8'hFF,8'hFF,8'hFF};
			else if (pixel_y < v_group0)  // red scale
				{gen_r, gen_g, gen_b} <= {h_scale, 8'h00, 8'h00};
			else if (pixel_y < v_group1) // green scale
				{gen_r, gen_g, gen_b} <= {8'h00, h_scale, 8'h00};
			else if (pixel_y < v_group2)  // blue scale
				{gen_r, gen_g, gen_b} <= {8'h00, 8'h00, h_scale};
			else	// gray scale
				{gen_r, gen_g, gen_b} <= {h_scale, h_scale, h_scale};
		end			
	end
end	

endmodule
