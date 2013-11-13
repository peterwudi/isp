
module processing(

	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	output	[17:0] y, cb, cr,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);


// 18-bit singed fixed point number, 9 bits
// before/after the decimal point

/*
Y     0.2988   0.5869   0.1143        R

Cb  = -0.1689  -0.3311  0.5000    X   G

Cr    0.5000   -0.4189  -0.0811       B
*/

// TODO: make this loadable
// Coef has 17 bits after decimal point
localparam signed [9*18-1:0] rgb2ycc_coef =
{
	18'sd39164,  18'sd76926,  18'sd14982,
	-18'sd22138, -18'sd43398, 18'sd65536,
	18'sd65536, -18'sd54906, -18'sd10630
};

wire	[37:0]	moA, moB, moC;

matrixmult_3x3 rgb2ycc
(
	.clk(clk),
	.reset(clk),
	.iX({10'b0, iData[23:16]}),
	.iY({10'b0, iData[15:8]}),
	.iZ({10'b0, iData[7:0]}),
	
	.coef(rgb2ycc_coef),
	
	.oA(moA),
	.oB(moB),
	.oC(moC)
);

// 18bits int x (18bits with 17 bits after the decimal point)
// gets you a 36bits number with 17 bits after the decimal
// point. We want only 9.
assign	y	= moA[25:8];
assign	cb	= moB[25:8];
assign	cr	= moC[25:8];


/*
filter_fifo filter
(
	.clk(clk),
	.reset(reset),
	.iValid(iValid),
	.oValid(oValid),
	.oDone(oDone),
	
	.iData(iData),
	.oData(oData)
);
*/















endmodule
