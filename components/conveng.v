`include "params.v"

module conveng
(
	input					clk,
	input					reset,

	input		[239:0]	iData,
	input					iValid,
	input		[2:0]		mode,
	
	output				oReq,
	output	[23:0]	oData,
	output				oValid,
	output				oDone
);

parameter	width			= 1920;
parameter	height		= 1080;

localparam	pipelineDepth = 8;

reg				colShift;
reg				rowShift;
reg	[255:0]	rf	[6:0];

reg				valid;
reg				valid_pipeline[pipelineDepth-1:0];

shift2drf shift2drf
(
	.clk(clk),
	.reset(reset),
	.iData(iData),
	.mode(mode),
	.colShift(colShift),
	.rowShift(rowShift),
	
	.rf(rf)
);

// Reduction tree
// Multiplier outputs
wire	signed	[27:0] multRes [14:0];

// Leaf level (level 1)
reg	signed	[27:0] multlvl1 [12:0];

// Level 2
reg	signed	[28:0] multlvl2 [7:0];

// Level 3
reg	signed	[29:0] multlvl3 [3:0];

// Level 4
reg	signed	[30:0] multlvl4 [1:0];
reg	signed	[30:0] pattern_3x3_out_lvl4 [3:0];	

// Level 5
reg	signed	[31:0] out;
reg	signed	[30:0] pattern_3x3_out_lvl5 [3:0];
reg	signed	[30:0] pattern_5x5_out_lvl5 [1:0];


always @(posedge clk) begin
	if (reset) begin
		out	<= 'b0;
	end
	else if (valid) begin
		// Produce valid results
		// Level 5
		out	<= multlvl4[0] + multlvl4[1];
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


genvar i;
genvar j;
generate
	// Level 1
	for (i = 0; i < 15; i = i + 1) begin: lvl1
		always @(posedge clk) begin
			if (reset) begin
				multlvl1[i] <= 'b0;
			end
			else if (valid) begin
				multlvl1[i]	<=	multRes[i][27:0];
			end
		end
	end

	// Level 2
	for (i = 0; i < 8; i = i + 1) begin: lvl2
		always @(posedge clk) begin
			if (reset) begin
				multlvl2[i] 	<= 'b0;
			end
			else if (valid) begin
				multlvl2[0]		<= multlvl1[0] + multlvl1[1];
				multlvl2[1]		<= multlvl1[2];
				multlvl2[2]		<= multlvl1[6] + multlvl1[7];
				multlvl2[3]		<= multlvl1[8] + multlvl1[12];
				multlvl2[4]		<= multlvl1[3] + multlvl1[4];
				multlvl2[5]		<= multlvl1[5] + multlvl1[13];
				multlvl2[6]		<= multlvl1[9] + multlvl1[10];
				multlvl2[7]		<= multlvl1[11] + multlvl1[14];
			end
		end
	end
	
	// Level 3
	for (i = 0; i < 4; i = i + 1) begin: lvl3
		always @(posedge clk) begin
			if (reset) begin
				multlvl3[i] 	<= 'b0;
			end
			else if (valid) begin
				multlvl3[i]	<=	multlvl2[i*2]+multlvl2[i*2+1];
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
	
	for (i = 0; i < 4; i = i + 1) begin: lvl3
		always @(posedge clk) begin
			if (reset) begin
				pattern_3x3_out_lvl4[i] 	<= 'b0;
				pattern_3x3_out_lvl5[i] 	<= 'b0;
			end
			else if (valid) begin
				pattern_3x3_out_lvl4[i]	<=	multlvl3[i];
				pattern_3x3_out_lvl5[i]	<=	pattern_3x3_out_lvl4[i];
			end
		end
	end
	
	// Level 5
	for (i = 0; i < 2; i = i + 1) begin: lvl4
		always @(posedge clk) begin
			if (reset) begin
				pattern_5x5_out_lvl5[i] <= 'b0;
			end
			else if (i_valid) begin
				pattern_5x5_out_lvl5[i]	<=	multlvl4[i];
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
endmodule

module shift2drf
(
	input						clk,
	input						reset,
	input			[255:0]	iData,
	input						colShift,
	input						rowShift,
	input			[2:0]		mode,
	
	output reg	[255:0]	rf	[6:0]
);

localparam numCol			= 32;
localparam numRow			= 7;
localparam numBits		= 8;
localparam numBits3x3	= 8*4;

localparam rowSize		= numCol*numBits;

genvar i;
integer j;
generate
	for (i = 0; i < numRow; i = i+1)	begin: a
		always @(posedge clk) begin
			for (j = 0; j < rowSize; j = j+1)	begin: b
				if (reset) begin
					rf[i] <= 'b0;
				end
				else if (colShift) begin
					if (mode == `pattern_3x3) begin
						// 3x3 pattern shifts 4 pixels at a time
						rf[i][j] <= rf[i][(j+numBits_3x3)%rowSize];
					end
					else begin
						rf[i][j] <= rf[i][(j+numBits)%rowSize];
					end
				end
				else if (rowShift) begin
					if (i < numRow - 1) begin
						rf[i] <= rf[i+1];
					end
					else begin
						rf[i] <= iData;
					end
				end
			end
		end
	end	
endgenerate


endmodule




