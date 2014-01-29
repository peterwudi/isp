`include "params.v"

module processing(
	input 							clk,
	input 							reset,
	input								newFrame,
	input								iValid,
	input		unsigned [7:0]		iData,
	
	// Demosaic
	output	unsigned	[7:0]		oDemosaicR, oDemosaicG, oDemosaicB,
	output				[7:0]		oT,
	output							oValidDemosaic,
	output							oDoneDemosaic,
	
	// Test
	output	unsigned	[7:0]		iRFilter, iGFilter, iBFilter,
	output							o_iValidFilter,
	
	// Filter
	output	unsigned	[23:0]	oDataFilter,
	output							oValidFilter,
	output							oDoneFilter,
	
	// Conveng
	input		[63:0]				irData, igData, ibData,
	//input		[55:0]				irData, igData, ibData,
	input		[2:0]					mode,
	output							oReq,
	output	[31:0]				oRdAddress,// oWrAddress,
	output	[31:0]				oConvPixelCnt,
	output	[7:0]					orData, ogData, obData,
	
	// rgb2ycc
	output	signed	[17:0]	y, cb, cr,
	output							oValidYcc,
	output							oDoneYcc,
	
	// ycc2rgb
	output	unsigned	[7:0]		oFinalR, oFinalG, oFinalB,
	output							oValidRGB,
	output							oDoneRGB
);

//parameter	width			= 1920;
//parameter	height		= 1080;

parameter	width			= 320;
parameter	height		= 240;

localparam	frameSize	= width * height;

parameter	kernelSize					= 7;
localparam	boundaryWidth				= (kernelSize-1)/2;
localparam	rows_needed_before_proc = (kernelSize-1)/2;
localparam	skipPixelCnt				= rows_needed_before_proc*(width+boundaryWidth*2)-1;
localparam	totalPixelCnt				= (rows_needed_before_proc*2+height)*(width+boundaryWidth*2);

wire	[31:0]	xCnt, yCnt, demosaicCnt;

demosaic_acpi #(.width(width), .height(height), .kernelSize(kernelSize))
demosaic
(
	.clk(clk),
	.iData(iData),
	.reset(reset | oDoneDemosaic),
	.iValid(iValid),
	
	.oR(oDemosaicR),
	.oG(oDemosaicG),
	.oB(oDemosaicB),
	.xCnt(xCnt),
	.yCnt(yCnt),
	.demosaicCnt(demosaicCnt),
	.oT(oT),
	.oValid(oValidDemosaic),
	.oDone(oDoneDemosaic)
);

//
//reg				[31:0]	skipCnt;
//reg							skipCntEn;
//
//reg							iValidFilter;
//reg	unsigned	[2:0]		boundaryCnt;
//reg				[23:0]	iDataFilter;
//reg	unsigned	[31:0]	startBoundary;
//
//// Test
//assign	iRFilter			= iDataFilter[23:16];
//assign	iGFilter 		= iDataFilter[15:8];
//assign	iBFilter 		= iDataFilter[7:0];
//assign	o_iValidFilter = iValidFilter;
//
//always @ (posedge clk) begin
//	if (reset) begin
//		skipCnt			<= 'b0;
//		skipCntEn		<= 0;
//		iValidFilter	<= 0;
//		boundaryCnt		<= 'b0;
//		iDataFilter		<= 'b0;
//		startBoundary	<= width*(rows_needed_before_proc+1);
//	end
//	else begin
//		if (newFrame|oDoneDemosaic) begin
//			skipCntEn	<= 1;
//		end
//		else begin
//			//	TODO: if kernel size is large, is it possible, that there's
//			// not enough time to insert the blanks?
//			if ((skipCnt < skipPixelCnt) && skipCntEn) begin
//				skipCnt		<= skipCnt + 1;
//			end
//			else begin
//				skipCnt		<= 'b0;
//				skipCntEn	<= 0;
//			end
//		end
//		
//		// At this point all skips has to be done
//		if (!skipCntEn) begin
//			// At start/end boundary
//			if (demosaicCnt == startBoundary) begin
//				if ((xCnt == 0) && (yCnt == 0)) begin
//					// The first pixel OR the last pixel, just need 1 boundary
//					boundaryCnt		<= (kernelSize-1)/2;
//				end
//				else begin
//					// Need 2 boundaries, 1 at the end and the other at the beginning
//					// of the next row.
//					// NOTE: the kernelSize should be an odd number
//					boundaryCnt		<= kernelSize-1;
//				end
//				
//				startBoundary	<= startBoundary + width;
//			end
//		end
//		
//		if (skipCntEn) begin
//			iDataFilter		<= 'b0;
//			iValidFilter	<=	1;
//		end
//		else if (boundaryCnt > 0) begin
//			// Need to add boundary to the input
//			iDataFilter		<= 'b0;
//			iValidFilter	<=	1;
//			boundaryCnt		<= boundaryCnt - 1;
//		end
//		else begin
//			// Actual data
//			iDataFilter		<= (oValidDemosaic == 1) ? {oDemosaicR, oDemosaicG, oDemosaicB} : 'b0;
//			iValidFilter	<= oValidDemosaic;
//		end
//	end
//end
//
//reg				filterPipelineEn;
//reg	[31:0]	filterInputCnt;
//
//always @(posedge clk) begin
//	if (reset | oDoneFilter) begin
//		filterPipelineEn	<= 0;
//		filterInputCnt		<= 'b0;
//	end
//	else begin
//		if (iValidFilter | filterPipelineEn) begin
//			filterInputCnt	<= filterInputCnt + 1;
//		end
//		
//		if (filterInputCnt >= totalPixelCnt) begin
//			// Input is finished, need to keep enabling the filter pipeline
//			filterPipelineEn	<= 1;
//		end
//	end
//end
//
//
//reg	[7:0]	convengResetCnt;
//reg			convengReset;
//always @(posedge clk) begin
//	if (reset) begin
//		convengReset		<= 1;
//		convengResetCnt	<= 'b0;
//	end
//	else begin
//		if (convengResetCnt == 15) begin
//			convengReset	<= 0;
//		end
//		else begin 
//			convengResetCnt	<= convengResetCnt + 1;
//		end
//	end
//end
//	
//filter_fifo_conveng #(.width(width), .height(height))
//filter
//(
//	.clk(clk),
//	.reset(convengReset),
//	.iValid(iValid),
//	.mode(mode),
//	.irData(irData),
//	.igData(igData),
//	.ibData(ibData),
//	
//	.oReq(oReq),
//	.oRdAddress(oRdAddress),
//	.oPixelCnt(oConvPixelCnt),
//	//.oWrAddress(oWrAddress),
//	.orData(orData),
//	.ogData(ogData),
//	.obData(obData),
//	
//	.oValid(oValidFilter),
//	.oDone(oDoneFilter)
//);
//
//assign oDataFilter = {orData, ogData, obData};
//
//
////filter_fifo_7 #(.width(width), .height(height), .kernel_size(kernelSize))
////filter
////(
////	.clk(clk),
////	.reset(reset | oDoneFilter),
////	.iValid(iValidFilter | filterPipelineEn),
////	.oValid(oValidFilter),
////	.oDone(oDoneFilter),
////	
////	.iData(iDataFilter),
////	.oData(oDataFilter)
////);
//
////
////filter_fifo_7_sym #(.width(width), .height(height), .kernel_size(kernelSize))
////filter
////(
////	.clk(clk),
////	.reset(reset | oDoneFilter),
////	.iValid(iValidFilter | filterPipelineEn),
////	.oValid(oValidFilter),
////	.oDone(oDoneFilter),
////	
////	.iData(iDataFilter),
////	.oData(oDataFilter)
////);
//
//
//// 18-bit singed fixed point number, 9 bits
//// before/after the decimal point
//
///*
//Y     0.2988   0.5869   0.1143        R
//
//Cb  = -0.1689  -0.3311  0.5000    X   G
//
//Cr    0.5000   -0.4189  -0.0811       B
//*/
//
//// Coef has 17 bits after decimal point
//localparam signed [9*18-1:0] rgb2ycc_coef =
//{
//	18'sd39164,  18'sd76926,  18'sd14982,
//	-18'sd22138, -18'sd43398, 18'sd65536,
//	18'sd65536, -18'sd54906, -18'sd10630
//};
//
//wire	[37:0]	moY, moCb, moCr;
//
//matrixmult_3x3 #(.frameSize(frameSize))
//rgb2ycc
//(
//	.clk(clk),
//	.reset(reset | oDoneYcc),
//	.iValid(oValidFilter),
//	.iX({10'b0, oDataFilter[23:16]}),
//	.iY({10'b0, oDataFilter[15:8]}),
//	.iZ({10'b0, oDataFilter[7:0]}),
//	
//	.coef(rgb2ycc_coef),
//	
//	.oA(moY),
//	.oB(moCb),
//	.oC(moCr),
//	.oValid(oValidYcc),
//	.oDone(oDoneYcc)
//);
//
//// 18bits int x (18bits with 17 bits after the decimal point)
//// gets you a 36bits number with 17 bits after the decimal
//// point. We want only 9.
//assign	y	= moY[25:8];
//assign	cb	= moCb[25:8];
//assign	cr	= moCr[25:8];
//
//
//// Color correction
//// Only put it here for measurement...
//wire				[37:0]	moColorR, moColorG, moColorB;
//wire							oDoneColor, oValidColor;
//wire	signed	[17:0]	oColorR, oColorG, oColorB;
//localparam signed [9*18-1:0] colorcorr_coef =
//{
//	18'sd1, 18'sd0, 18'sd0,
//	18'sd0, 18'sd1, 18'sd0,
//	18'sd0, 18'sd0, 18'sd1
//};
//
//matrixmult_3x3 #(.frameSize(frameSize))
//colorcorr
//(
//	.clk(clk),
//	.reset(reset | oDoneColor),
//	.iValid(oValidYcc),
//	.iX(y),
//	.iY(cb),
//	.iZ(cr),
//	
//	.coef(colorcorr_coef),
//	
//	.oA(moColorR),
//	.oB(moColorG),
//	.oC(moColorB),
//	.oValid(oValidColor),
//	.oDone(oDoneColor)
//);
//
//assign	oColorR	= moColorR[17:0];
//assign	oColorG	= moColorG[17:0];
//assign	oColorB	= moColorB[17:0];
//
//
//// Gamma correction
//wire	[17:0]	yGamma, cbGamma, crGamma;
//wire				oValidGamma;
//
//gamma gamma
//(
//	.clk(clk),
//	.reset(reset),
//	.iY(oColorR),
//	.iCb(oColorG),
//	.iCr(oColorB),
//	.iValid(oValidColor),
//	
//	.oY(yGamma),
//	.oCb(cbGamma),
//	.oCr(crGamma),
//	.oValid(oValidGamma)
//);
//
//localparam signed [9*18-1:0] ycc2rgb_coef =
//{
//	18'sd65536,  18'sd0,       18'sd91881,
//	18'sd65536, -18'sd22551,  -18'sd46799,
//	18'sd65536,  18'sd112853,  18'sd10
//};
//
//wire	[37:0]	moFinalR, moFinalG, moFinalB;
//
//matrixmult_3x3 #(.frameSize(frameSize))
//ycc2rgb
//(
//	.clk(clk),
//	.reset(reset | oDoneRGB),
//	.iValid(oValidGamma),
//	.iX(yGamma),
//	.iY(cbGamma),
//	.iZ(crGamma),
//	
//	.coef(ycc2rgb_coef),
//	
//	.oA(moFinalR),
//	.oB(moFinalG),
//	.oC(moFinalB),
//	.oValid(oValidRGB),
//	.oDone(oDoneRGB)
//);
//
////	ycc x ycc2rgb_coef
//// aaaaaaaaa bbbbbbbbb	x	cc dddddddddddddddd
////	  9 bits   9 bits     2bits   16 bits
//// = aaaaaaaaaaaa bbbbbbbbbbbbbbbbbbbbbbbbb
////    12 bits            25 bits
//// Want to take the lower 8 bits of the integer part
//// i.e. [32:25]
//assign	oFinalR	= moFinalR[32:25];
//assign	oFinalG	= moFinalG[32:25];
//assign	oFinalB	= moFinalB[32:25];



endmodule
