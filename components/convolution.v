// A generic 7x7 convolution
module convolution_7x7
(
	input	clk,
	input reset,
	input i_valid,
	input unsigned	[55:0]	i_data,

	output signed	[31:0]	o_data
);

localparam	kernel_size		= 7;

// Use 16-bit values
//	Kernel for sharpen (flipped)
// from http://lodev.org/cgtutor/filtering.html
//		-1,	-1,	-1,
//		-1,	9,		-1,
//		-1,	-1,	-1
//
localparam signed [49*16-1:0] h = {
	16'sd0, 	16'sd0, 	16'sd0, 	16'sd0,  16'sd0, 16'sd0, 16'sd0,
	16'sd0, 	16'sd0, 	16'sd0, 	16'sd0,  16'sd0, 16'sd0, 16'sd0,
	16'sd0, 	16'sd0, -16'sd1, -16'sd1, -16'sd1, 16'sd0, 16'sd0,
	16'sd0, 	16'sd0, -16'sd1,  16'sd9, -16'sd1, 16'sd0, 16'sd0,
	16'sd0,	16'sd0, -16'sd1, -16'sd1, -16'sd1, 16'sd0, 16'sd0,
	16'sd0,	16'sd0,  16'sd0,	16'sd0,  16'sd0, 16'sd0, 16'sd0,
	16'sd0,  16'sd0,  16'sd0,	16'sd0,  16'sd0, 16'sd0, 16'sd0

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

// Reduction tree
// Multiplier outputs
wire	signed	[27:0] multRes [12:0];

// Leaf level (level 1)
reg	signed	[27:0] multlvl1 [12:0];

// Level 2
reg	signed	[28:0] multlvl2 [6:0];

// Level 3
reg	signed	[29:0] multlvl3 [3:0];

// Level 4
reg	signed	[29:0] multlvl4 [1:0];

// Level 5
reg	signed	[31:0] out;

// Pipeline registers
reg	[15:0]	window	[kernel_size-1:0][kernel_size-1:0];

// Input/Ouput
always @(posedge clk) begin
	if (reset) begin
		window[0][0]	<= 'b0;
		window[1][0]	<= 'b0;
		window[2][0]	<= 'b0;
		window[3][0]	<= 'b0;
		window[4][0]	<= 'b0;
		window[5][0]	<= 'b0;
		window[6][0]	<= 'b0;
	end
	else begin
		if (i_valid) begin
			// Get new inputs
			window[0][0]	<= i_data[55:48];
			window[1][0]	<= i_data[47:40];
			window[2][0]	<= i_data[39:32];
			window[3][0]	<= i_data[31:24];
			window[4][0]	<= i_data[23:16];
			window[5][0]	<= i_data[15:8];
			window[6][0]	<= i_data[7:0];
			
			// Produce valid results
			// Level 5
			out				<= multlvl4[0] + multlvl4[1];
		end		
	end
end


genvar i;
genvar j;
//genvar x;
//genvar y;
`define	x	((i*4)/7)
`define	y	((i*4)%7)
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
	
	for (i = 0; i < 12; i = i + 1) begin: mult
		multAdd_4_16x16 mult(
			.chainin(44'b0),
			.clock0(clk),
			.dataa_0(window[`x][`y]),
			.dataa_1(window[`x+((`y>=6)?1:0)][(`y+1)%7]),
			.dataa_2(window[`x+((`y>=5)?1:0)][(`y+2)%7]),
			.dataa_3(window[`x+((`y>=4)?1:0)][(`y+3)%7]),
			.datab_0(h[(783-i*64):(768-i*64)]),
			.datab_1(h[(767-i*64):(752-i*64)]),
			.datab_2(h[(751-i*64):(736-i*64)]),
			.datab_3(h[(735-i*64):(720-i*64)]),
			.ena0(i_valid),
			.result(multRes[i]));
	end
	
	// Level 1
	for (i = 0; i < 13; i = i + 1) begin: lvl1
		always @(posedge clk) begin
			if (reset) begin
				multlvl1[i] <= 'b0;
			end
			else if (i_valid) begin
				multlvl1[i]	<=	multRes[i][27:0];
			end
		end
	end

	// Level 2
	for (i = 0; i < 7; i = i + 1) begin: lvl2
		always @(posedge clk) begin
			if (reset) begin
				multlvl2[i] 	<= 'b0;
			end
			else if (i_valid) begin
				if (i < 6) begin
					multlvl2[i]	<=	multlvl1[i*2]+multlvl1[i*2+1];
				end
				else begin
					multlvl2[i]	<= multlvl1[12];
				end
			end
		end
	end
	
	// Level 3
	for (i = 0; i < 4; i = i + 1) begin: lvl3
		always @(posedge clk) begin
			if (reset) begin
				multlvl3[i] 	<= 'b0;
			end
			else if (i_valid) begin
				if (i < 3) begin
					multlvl3[i]	<=	multlvl2[i*2]+multlvl2[i*2+1];
				end
				else begin
					multlvl3[i]	<= multlvl2[6];
				end
			end
		end
	end
	
	// Level 4
	for (i = 0; i < 2; i = i + 1) begin: lvl4
		always @(posedge clk) begin
			if (reset) begin
				multlvl4[i] 	<= 'b0;
			end
			else if (i_valid) begin
				multlvl4[i]	<=	multlvl3[i*2]+multlvl3[i*2+1];
			end
		end
	end
endgenerate

mult_1_16x16 mult_1(
	.clock0(clk),
	.dataa_0(window[6][6]),
	.datab_0(h[15:0]),
	.ena0(i_valid),
	.result(multRes[12]));


assign o_data		= out;

endmodule

// A symmetric 7x7 convolution
module convolution_7x7_sym
(
	input	clk,
	input reset,
	input i_valid,
	input unsigned	[55:0]	i_data,

	output signed	[31:0]	o_data
);

localparam	kernel_size		= 7;

// Use 16-bit values
//	Kernel for sharpen (flipped)
// from http://lodev.org/cgtutor/filtering.html
//		-1,	-1,	-1,
//		-1,	9,		-1,
//		-1,	-1,	-1
//
localparam signed [16*16-1:0] h = {
	16'sd0, 	16'sd0, 	16'sd0, 	16'sd0,
	16'sd0, 	16'sd0, 	16'sd0, 	16'sd0,
	16'sd0, 	16'sd0, -16'sd1, -16'sd1,
	16'sd0, 	16'sd0, -16'sd1,  16'sd9
};

// Reduction tree
// Summed operands
reg	signed	[8:0]		operandlvl1 [24:0];
reg	signed	[9:0]		operand[15:0];

// Multiplier outputs
wire	signed	[27:0]	multRes [3:0];

// Leaf level (level 1)
reg	signed	[27:0]	multlvl1 [3:0];

// Level 2
reg	signed	[28:0]	multlvl2 [1:0];

// Level 3
reg	signed	[31:0]	out;

// Pipeline registers
reg	[15:0]	window	[kernel_size-1:0][kernel_size-1:0];

// Input/Ouput
always @(posedge clk) begin
	if (reset) begin
		window[0][0]	<= 'b0;
		window[1][0]	<= 'b0;
		window[2][0]	<= 'b0;
		window[3][0]	<= 'b0;
		window[4][0]	<= 'b0;
		window[5][0]	<= 'b0;
		window[6][0]	<= 'b0;
	end
	else begin
		if (i_valid) begin
			// Get new inputs
			window[0][0]	<= i_data[55:48];
			window[1][0]	<= i_data[47:40];
			window[2][0]	<= i_data[39:32];
			window[3][0]	<= i_data[31:24];
			window[4][0]	<= i_data[23:16];
			window[5][0]	<= i_data[15:8];
			window[6][0]	<= i_data[7:0];
			
			// Produce valid results
			// Level 3
			out				<= multlvl2[0] + multlvl2[1];
		end		
	end
end


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
	
	integer index;
	always @(posedge clk) begin
		if (reset) begin
			for (index = 0; index < 25; index = index + 1) begin: oplvl1
				operandlvl1[index]	<= 'b0;
			end
		end
		else if (i_valid) begin
			operandlvl1[0]		<= window[0][0] + window[0][6];
			operandlvl1[1]		<= window[6][0] + window[6][6];
			operandlvl1[2]		<= window[0][1] + window[0][5];
			operandlvl1[3]		<= window[6][1] + window[6][5];
			operandlvl1[4]		<= window[0][2] + window[0][4];
			operandlvl1[5]		<= window[6][2] + window[6][4];
			
			operandlvl1[6]		<= window[0][3] + window[6][3];
			
			operandlvl1[7]		<= window[1][0] + window[1][6];
			operandlvl1[8]		<= window[5][0] + window[5][6];
			operandlvl1[9]		<= window[1][1] + window[1][5];
			operandlvl1[10]	<= window[5][1] + window[5][5];
			operandlvl1[11]	<= window[1][2] + window[1][4];
			operandlvl1[12]	<= window[5][2] + window[5][4];
			
			operandlvl1[13]	<= window[1][3] + window[5][3];
			
			operandlvl1[14]	<= window[2][0] + window[2][6];
			operandlvl1[15]	<= window[4][0] + window[4][6];
			operandlvl1[16]	<= window[2][1] + window[2][5];
			operandlvl1[17]	<= window[4][1] + window[4][5];
			operandlvl1[18]	<= window[2][2] + window[2][4];
			operandlvl1[19]	<= window[4][2] + window[4][4];
			
			operandlvl1[20]	<= window[2][3] + window[4][3];
			
			operandlvl1[21]	<= window[3][0] + window[1][6];
			operandlvl1[22]	<= window[3][1] + window[1][5];
			operandlvl1[23]	<= window[3][2] + window[3][4];
			operandlvl1[24]	<= window[3][3];
		end
	end
	
	
	always @(posedge clk) begin
		if (reset) begin
			for (index = 0; index < 16; index = index + 1) begin: op
				operand[index]	<= 'b0;
			end
		end
		else if (i_valid) begin
			operand[0]	<= operandlvl1[0] + operandlvl1[1];
			operand[1]	<= operandlvl1[2] + operandlvl1[3];
			operand[2]	<= operandlvl1[4] + operandlvl1[5];
			operand[3]	<= operandlvl1[6];
			
			operand[4]	<= operandlvl1[7] + operandlvl1[8];
			operand[5]	<= operandlvl1[9] + operandlvl1[10];
			operand[6]	<= operandlvl1[11] + operandlvl1[12];
			operand[7]	<= operandlvl1[13];
			
			operand[8]	<= operandlvl1[14] + operandlvl1[15];
			operand[9]	<= operandlvl1[16] + operandlvl1[17];
			operand[10]	<= operandlvl1[18] + operandlvl1[19];
			operand[11]	<= operandlvl1[20];
			
			operand[12]	<= operandlvl1[21];
			operand[13]	<= operandlvl1[22];
			operand[14]	<= operandlvl1[23];
			operand[15]	<= operandlvl1[24];
			
		end
	end
	
	for (i = 0; i < 4; i = i + 1) begin: mult
		multAdd_4_16x16 mult(
			.chainin(44'b0),
			.clock0(clk),
			.dataa_0(operand[i*4]),
			.dataa_1(operand[i*4+1]),
			.dataa_2(operand[i*4+2]),
			.dataa_3(operand[i*4+3]),
			.datab_0(h[(255-i*64):(240-i*64)]),
			.datab_1(h[(239-i*64):(224-i*64)]),
			.datab_2(h[(223-i*64):(208-i*64)]),
			.datab_3(h[(207-i*64):(192-i*64)]),
			.ena0(i_valid),
			.result(multRes[i]));
	end
	
	// Level 1
	for (i = 0; i < 4; i = i + 1) begin: lvl1
		always @(posedge clk) begin
			if (reset) begin
				multlvl1[i] <= 'b0;
			end
			else if (i_valid) begin
				multlvl1[i]	<=	multRes[i][27:0];
			end
		end
	end

	// Level 2
	for (i = 0; i < 2; i = i + 1) begin: lvl2
		always @(posedge clk) begin
			if (reset) begin
				multlvl2[i] 	<= 'b0;
			end
			else if (i_valid) begin
				multlvl2[i]	<=	multlvl1[i*2]+multlvl1[i*2+1];
			end
		end
	end
endgenerate

assign o_data		= out;

endmodule






// A generic 3x3 convolution
module convolution_3x3
(
	input	clk,
	input reset,
	input i_valid,
	input unsigned	[23:0]	i_data,

	output signed	[34:0]	o_data
);

localparam	kernel_size		= 3;
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

// Delay line of mult_3
reg	[15:0]	delay_3	[3:0];

// Input/Ouput
always @(posedge clk) begin
	if (reset) begin
		window[0][0]	<= 0;
		window[1][0]	<= 0;
		window[2][0]	<= 0;
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

