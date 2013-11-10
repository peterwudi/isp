
module processing(

	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);





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
















endmodule
