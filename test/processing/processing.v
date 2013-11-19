
module processing(

	input 							clk,
	input 							reset,
	input								newFrame,
	input								iValid,
	input		unsigned [7:0]		iData,
	
	// Demosaic
	output	unsigned	[7:0]		oR, oG, oB,
	output							oValidDemosaic,
	output							oDoneDemosaic,
	
	// Test
	output	unsigned	[7:0]		iRFilter, iGFilter, iBFilter,
	output							o_iValidFilter,
	
	// Filter
	output	unsigned	[23:0]	oDataFilter,
	output							oValidFilter,
	output							oDoneFilter,
	
	// rgb2ycc
	output	signed	[17:0]	y, cb, cr,
	output							oValidYcc,
	output							oDoneYcc
);

parameter	width			= 320;
parameter	height		= 240;
parameter	frameSize	= width * height;

wire	[31:0]	xCnt, yCnt, demosaicCnt;

demosaic_neighbor #(.width(width), .height(height))
demosaic
(
	.clk(clk),
	.iData(iData),
	.reset(reset | oDoneDemosaic),
	.iValid(iValid),
	
	.oR(oR),
	.oG(oG),
	.oB(oB),
	.xCnt(xCnt),
	.yCnt(yCnt),
	.demosaicCnt(demosaicCnt),
	.oValid(oValidDemosaic),
	.oDone(oDoneDemosaic)
);
parameter	kernelSize					= 3;
localparam	boundaryWidth				= (kernelSize-1)/2;
localparam	rows_needed_before_proc = (kernelSize-1)/2;
localparam	skipPixelCnt				= rows_needed_before_proc*(width+boundaryWidth);
localparam	totalPixelCnt				= (rows_needed_before_proc*2+height)*(width+boundaryWidth*2);

reg				[31:0]	skipCnt;
reg							skipCntEn;

reg							iValidFilter;
reg	unsigned	[2:0]		boundaryCnt;
reg				[23:0]	iDataFilter;
reg	unsigned	[31:0]	startBoundary;

// Test
assign	iRFilter			= iDataFilter[23:16];
assign	iGFilter 		= iDataFilter[15:8];
assign	iBFilter 		= iDataFilter[7:0];
assign	o_iValidFilter = iValidFilter;

always @ (posedge clk) begin
	if (reset) begin
		skipCnt			<= 'b0;
		skipCntEn		<= 0;
		iValidFilter	<= 0;
		boundaryCnt		<= 'b0;
		iDataFilter		<= 'b0;
		startBoundary	<= width*(rows_needed_before_proc+1);
	end
	else begin
		if (newFrame|oDoneDemosaic) begin
			skipCntEn	<= 1;
		end
		else begin
			//	TODO: if kernel size is large, is it possible, that there's
			// not enough time to insert the blanks?
			if ((skipCnt < skipPixelCnt) && skipCntEn) begin
				skipCnt		<= skipCnt + 1;
			end
			else begin
				skipCnt		<= 'b0;
				skipCntEn	<= 0;
			end
		end
		
		if (!skipCntEn) begin
			// At start/end boundary
			if (demosaicCnt == startBoundary) begin
				if ((xCnt == 0) && (yCnt == 0)) begin
					// The first pixel OR the last pixel, just need 1 boundary
					boundaryCnt		<= (kernelSize-1)/2;
				end
				else begin
					// Need 2 boundaries, 1 at the end and the other at the beginning
					// of the next row.
					// NOTE: the kernelSize should be an odd number
					boundaryCnt		<= kernelSize-1;
				end
				
				startBoundary	<= startBoundary + width;
			end
		end
		
		if (skipCntEn) begin
			iDataFilter		<= 'b0;
			iValidFilter	<=	1;
		end
		else if (boundaryCnt > 0) begin
			// Need to add boundary to the input
			iDataFilter		<= 'b0;
			iValidFilter	<=	1;
			boundaryCnt		<= boundaryCnt - 1;
		end
		else begin
			// Actual data
			iDataFilter		<= (oValidDemosaic == 1) ? {oR, oG, oB} : 'b0;
			iValidFilter	<= oValidDemosaic;
		end
	end
end

reg				filterPipelineEn;
reg	[31:0]	filterInputCnt;

always @(posedge clk) begin
	if (reset | oDoneFilter) begin
		filterPipelineEn	<= 0;
		filterInputCnt		<= 'b0;
	end
	else begin
		if (iValidFilter | filterPipelineEn) begin
			filterInputCnt	<= filterInputCnt + 1;
		end
		
		if (filterInputCnt >= totalPixelCnt) begin
			// Input is finished, need to keep enabling the filter pipeline
			filterPipelineEn	<= 1;
		end
	end
end


filter_fifo #(.width(width), .height(height), .kernel_size(kernelSize))
filter
(
	.clk(clk),
	.reset(reset | oDoneFilter),
	.iValid(iValidFilter | filterPipelineEn),
	.oValid(oValidFilter),
	.oDone(oDoneFilter),
	
	.iData(iDataFilter),
	.oData(oDataFilter)
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

matrixmult_3x3 #(.frameSize(frameSize))
rgb2ycc
(
	.clk(clk),
	.reset(reset | oDoneYcc),
	.iValid(oValidFilter),
	.iX({10'b0, oDataFilter[23:16]}),
	.iY({10'b0, oDataFilter[15:8]}),
	.iZ({10'b0, oDataFilter[7:0]}),
	
	.coef(rgb2ycc_coef),
	
	.oA(moA),
	.oB(moB),
	.oC(moC),
	.oValid(oValidYcc),
	.oDone(oDoneYcc)
);

// 18bits int x (18bits with 17 bits after the decimal point)
// gets you a 36bits number with 17 bits after the decimal
// point. We want only 9.
assign	y	= moA[25:8];
assign	cb	= moB[25:8];
assign	cr	= moC[25:8];




endmodule
