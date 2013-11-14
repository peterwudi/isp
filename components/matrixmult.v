
// Multiply a row in a 3x3 matrix
module rowMult_3x3
(
	input wire				clk,
	input wire				reset,
	input wire	[17:0] 	iX, iY, iZ,
	input wire	[17:0]	coef_1, coef_2, coef_3,
	
	output wire	[37:0]	row_o
);

multAdd_4_18x18 multADD_rowRes
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
	input								iValid,
	input	signed	[18*9-1:0]	coef,
	
	output signed	[37:0]		oA, oB, oC,
	output							oValid,
	output							oDone
);

/*
oA					iX

oB	=	coef	X	iY

oC					iZ
*/

parameter	frameSize = 320*240;

reg	[31:0]	pixelCnt;
reg				moDone;

always @(posedge clk) begin
	if (reset) begin
		pixelCnt	<= 'b0;
		moDone	<= 0;
	end
	else if (oValid) begin
		if (pixelCnt < frameSize) begin
			pixelCnt	<= pixelCnt+1;
		end
		else begin
			pixelCnt	<= 0;
			moDone	<= 1;
		end
	end
end

assign oDone = moDone;

localparam	pipelineDepth = 3;
reg	validPipeline [pipelineDepth-1:0];

genvar i;
generate
	for (i = 1; i < pipelineDepth; i = i+1) begin: a
		always @(posedge clk) begin
			if(reset) begin
				validPipeline[i]	<= 0;
			end
			else begin
				validPipeline[i]	<= validPipeline[i-1];
			end
		end
	end
endgenerate
			
always @(posedge clk) begin
	if(reset) begin
		validPipeline[0]	<= 0;
	end
	else begin
		validPipeline[0]	<= iValid;
	end
end

assign oValid = validPipeline[pipelineDepth-1];

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

