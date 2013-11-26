module conveng
(
	input					clk,
	input					reset,

	input		[239:0]	iData,
	input					iValid,
	
	output				oReq,
	output	[23:0]	oData,
	output				oValid,
	output				oDone
);
`define	pattern_1x3	0
`define	pattern_1x5	1
`define	pattern_1x7	2
`define	pattern_3x3	3
`define	pattern_5x5	4
`define	pattern_7x7	5

parameter	width			= 1920;
parameter	height		= 1080;

reg	[2:0]	mode			= `pattern_7x7;


always @(posedge clk) begin
	case (mode)
		`pattern_7x7:	begin
			
		end
end




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




genvar i;
genvar j;

`define	x	((i*4)/7)
`define	y	((i*4)%7)
generate
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
endmodule

module shift2drf
(
	input						clk,
	input			[239:0]	data,
	
	input						reset,
	input						colShift,
	input						rowShift,
	
	output reg	[239:0]	rf	[6:0]
);

localparam numCol		= 10;
localparam numRow		= 7;
localparam numBits	= 24;

localparam rowSize	= numCol*numBits;

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
					rf[i][j] <= rf[i][(j+numBits)%rowSize];
				end
				else if (rowShift) begin
					if (i < numRow - 1) begin
						rf[i] <= rf[i+1];
					end
					else begin
						rf[i] <= data;
					end
				end
			end
		end
	end	
endgenerate


endmodule




