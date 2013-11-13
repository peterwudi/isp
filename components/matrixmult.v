
// Multiply a row in a 3x3 matrix
module rowMult_3x3
(
	input wire				clk,
	input wire				reset,
	input wire	[17:0] 	iX, iY, iZ,
	input wire	[17:0]	coef_1, coef_2, coef_3,
	
	output wire	[37:0]	row_o
);

multAdd_18x18 multADD_rowRes
(
	.clock0(clk),
	.dataa_0(iX),
	.dataa_1(iY),
	.dataa_2(iZ),
	.datab_0(coef_1),
	.datab_1(coef_2),
	.datab_2(coef_3),
	.result(row_o)
);

endmodule

module matrixmult_3x3
(
	input wire						clk,
	input wire						reset,
	input signed	[17:0]		iX, iY, iZ,
	input	signed	[18*9-1:0]	coef,
	
	output signed	[37:0]		oA, oB, oC
);

/*
oA					iX

oB	=	coef	X	iY

oC					iZ
*/

wire	[37:0] moA

rowMult_3x3 resA
(
	.clk(clk),
	.reset(reset),
	.iX(iX),
	.iY(iY),
	.iZ(iZ),
	.coef_1(coef[161:144]),
	.coef_2(coef[143:126]),
	.coef_3(coef[125:108]),
	.row_o(oA)
);

rowMult_3x3 resB
(
	.clk(clk),
	.reset(reset),
	.iX(iX),
	.iY(iY),
	.iZ(iZ),
	.coef_1(coef[107:90]),
	.coef_2(coef[89:72]),
	.coef_3(coef[71:54]),
	.row_o(oB)
);

rowMult_3x3 resC
(
	.clk(clk),
	.reset(reset),
	.iX(iX),
	.iY(iY),
	.iZ(iZ),
	.coef_1(coef[53:36]),
	.coef_2(coef[35:18]),
	.coef_3(coef[17:0]),
	.row_o(oC)
);


endmodule

