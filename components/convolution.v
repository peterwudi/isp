// A generic 3x3 convolution
module convolution
(
	input	clk,
	input reset,
	input i_valid,
	input i_done,
	
	input unsigned	[23:0]	i_data,
	
	//output 						o_valid,
	//output						o_img_done,
	output signed	[34:0]	o_data
);

localparam	kernel_size		= 3;

localparam	pipeline_depth = 9;
localparam	mult1Res_delay = 3;

// Use 16-bit values
//	Kernel for sharpen (flipped)
// from http://lodev.org/cgtutor/filtering.html
//		-1,	-1,	-1,
//		-1,	9,		-1,
//		-1,	-1,	-1
//
localparam signed [9*16-1:0] h = {
	-16'sd1,	-16'sd1,	-16'sd1,
	-16'sd1,	16'sd9,	-16'sd1,
	-16'sd1,	-16'sd1,	-16'sd1
};



// TODO: temporarily use the old one to verify
// http://www.songho.ca/dsp/convolution/convolution2d_example.html
//	1	2	1
//	0	0	0
//	-1	-2	-1
/*
localparam signed [9*16-1:0] h = {
	16'sd1,	16'sd2,	16'sd1,
	16'sd0,	16'sd0,	16'sd0,
	-16'sd1,	-16'sd2,	-16'sd1
};
*/

wire	signed	[31:0] mult1Res;
wire	signed	[43:0] mult2Res;
wire	signed	[43:0] mult3Res;

reg	signed 	[43:0] mult3Res_r;

// Delay line of mult1Res
reg	signed	[31:0] mult1Res_r [mult1Res_delay - 1: 0];

reg	signed	[43:0] out;

// Pipeline registers
reg	[15:0]	window	[kernel_size-1:0][kernel_size-1:0];
//reg				valid		[pipeline_depth - 1 : 0];
//reg				img_done	[pipeline_depth - 1 : 0];

// Delay line of mult_3
reg	[15:0]	delay_3	[3:0];

// Input/Ouput
always @(posedge clk) begin
	if (reset) begin
		window[0][0]	<= 0;
		window[1][0]	<= 0;
		window[2][0]	<= 0;
		
		//valid[0]			<= 0;
		//img_done[0]		<= 0;
	end
	else begin
		if (i_valid) begin
			// Get new inputs
			window[0][0]	<= i_data[23:16];
			window[1][0]	<= i_data[15:8];
			window[2][0]	<= i_data[7:0];
			
			delay_3[0]		<= window[1][2];
			delay_3[1]		<= window[2][0];
			delay_3[2]		<= window[2][1];
			delay_3[3]		<= window[2][2];
			
			//valid[0]			<= i_valid;
			//img_done[0]		<= i_done;
			
			// Produce valid results
			mult1Res_r[0]	<= mult1Res;
			mult3Res_r		<= mult3Res;
			out				<=	mult3Res_r + mult1Res_r[mult1Res_delay - 1];
		end		
	end
end

// Multipliers
mult_1_16x16 mult_1(
	.clock0(clk),
	.dataa_0(window[0][0]),
	.datab_0(h[143:128]),
	.ena0(i_valid),
	.result(mult1Res));
	
multAdd_4_16x16 mult_2(
	.chainin(44'b0),
	.clock0(clk),
	.dataa_0(window[0][1]),
	.dataa_1(window[0][2]),
	.dataa_2(window[1][0]),
	.dataa_3(window[1][1]),
	.datab_0(h[127:112]),
	.datab_1(h[111:96]),
	.datab_2(h[95:80]),
	.datab_3(h[79:64]),
	.ena0(i_valid),
	.result(mult2Res));

// Need to delay operand for 1 cycle
multAdd_4_16x16 mult_3(
	.chainin(mult2Res),
	.clock0(clk),
	.dataa_0(delay_3[0]),
	.dataa_1(delay_3[1]),
	.dataa_2(delay_3[2]),
	.dataa_3(delay_3[3]),
	.datab_0(h[64:49]),
	.datab_1(h[47:32]),
	.datab_2(h[31:16]),
	.datab_3(h[15:0]),
	.ena0(i_valid),
	.result(mult3Res));

assign o_data		= out;
//assign o_valid		= valid[pipeline_depth - 1];
//assign o_img_done	= img_done[pipeline_depth - 1];

genvar i;
genvar j;
generate
	for (i = 0; i < kernel_size; i = i + 1) begin: a
		for (j = 1; j < kernel_size; j = j + 1) begin: b
			always @(posedge clk) begin
				if (reset) begin
					window[i][j] 	<= 16'b0;
				end
				else if (i_valid) begin
					window[i][j]	<= window[i][j-1];
				end
			end
		end
	end
	
//	for (i = 1; i < pipeline_depth; i = i + 1) begin: c
//		always @(posedge clk) begin
//			if (reset) begin
//				valid[i]		<= 0;
//				img_done[i]	<= 0;
//			end
//			else if (i_valid) begin
//				valid[i]		<= valid[i-1];
//				img_done[i]	<= img_done[i-1];
//			end
//		end
//	end
	
	for (i = 1; i < mult1Res_delay; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				mult1Res_r[i] <= 0;
			end
			else if (i_valid) begin
				mult1Res_r[i] <= mult1Res_r[i-1];
			end
		end
	end
	
endgenerate



endmodule

