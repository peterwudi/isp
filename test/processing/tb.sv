`timescale 1ns/1ns

//localparam	width				= 1920;
//localparam	height			= 1080;

localparam	width				= 320;
localparam	height			= 240;


localparam	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;
localparam	rowSize			= width+boundaryWidth*2;
localparam	frontSkip		= rowSize*boundaryWidth;

localparam	totalPixels		= width * height;
localparam	totalInFilter	= rowSize*(height+boundaryWidth*2);


// TODO: add pading bytes if need be, not necessary for 240p

module tb();

// Input/output of the ISP
logic 						clk;
logic 						reset;
logic							newFrame;
logic							iValid;
logic	unsigned [7:0]		iData;

// Demosaic
logic	unsigned [7:0]		oDemosaicR, oDemosaicG, oDemosaicB;
logic				[7:0]		oT;
logic							oValidDemosaic;
logic							oDoneDemosaic;

// Test
logic	unsigned	[7:0]		iRFilter, iGFilter, iBFilter;
logic							o_iValidFilter;

// Filter
logic	unsigned	[23:0]	oDataFilter;
logic							oValidFilter;
logic							oDoneFilter;

// Conveng
logic	[63:0]				irData, igData, ibData;
//logic	[55:0]				irData, igData, ibData;
logic	[2:0]					mode = 5;
logic							oReq;
logic	[31:0]				oRdAddress, oWrAddress;
logic	[31:0]				oConvPixelCnt;
logic	[7:0]					orData, ogData, obData;

// rgb2ycc
logic	signed	[17:0]	y, cb, cr;
logic							oValidYcc;
logic							oDoneYcc;

// ycc2rgb
logic	unsigned	[7:0]		oFinalR, oFinalG, oFinalB;
logic							oValidRGB;
logic							oDoneRGB;

// Input/output array from file

// NOTE: Use filter data size to test filter only!
logic unsigned	[7:0]		rOrig [totalInFilter - 1:0];
logic unsigned	[7:0]		gOrig [totalInFilter - 1:0];
logic unsigned	[7:0]		bOrig [totalInFilter - 1:0];

// RAW data
logic unsigned	[7:0]		raw	[totalInFilter - 1:0];

// Demosaic output
logic unsigned	[7:0]		rDemosaic [totalPixels-1:0];
logic unsigned	[7:0]		gDemosaic [totalPixels-1:0];
logic unsigned	[7:0]		bDemosaic [totalPixels-1:0];

// Demosaic output with boundary
logic unsigned	[7:0]		o_irFilter [totalInFilter-1:0];
logic unsigned	[7:0]		o_igFilter [totalInFilter-1:0];
logic unsigned	[7:0]		o_ibFilter [totalInFilter-1:0];

// Filter output
logic unsigned	[7:0]		rFilter [totalPixels-1:0];
logic unsigned	[7:0]		gFilter [totalPixels-1:0];
logic unsigned	[7:0]		bFilter [totalPixels-1:0];

// YCC matrix output
logic unsigned	[17:0]	yMatrix [totalPixels-1:0];
logic unsigned	[17:0]	cbMatrix [totalPixels-1:0];
logic unsigned	[17:0]	crMatrix [totalPixels-1:0];

// RGB matrix output
logic unsigned	[17:0]	rMatrix [totalPixels-1:0];
logic unsigned	[17:0]	gMatrix [totalPixels-1:0];
logic unsigned	[17:0]	bMatrix [totalPixels-1:0];

processing dut ( .* );

initial clk = '1;
always #10 clk = ~clk;  // 50 MHz clock

logic unsigned	[7:0]		iR;
logic unsigned	[7:0]		iG;
logic unsigned	[7:0]		iB;

// Stream Producer
initial begin
	integer r_inFile;
	integer g_inFile;
	integer b_inFile;
	
	r_inFile = $fopen("rOrig", "r");
	g_inFile = $fopen("gOrig", "r");
	b_inFile = $fopen("bOrig", "r");

	for (int i = 0; i < totalPixels; i++) begin
		integer in1, in2, in3;
		
		// Read from file
		in1 = $fscanf(r_inFile, "%d", rOrig[i]);
		in2 = $fscanf(g_inFile, "%d", gOrig[i]);
		in3 = $fscanf(b_inFile, "%d", bOrig[i]);
	end
	
	for (int i = 0; i < totalPixels; i++) begin
		if ((i / width) % 2 == 0) begin
			// Even row, G B G B ......
			if ((i % width) % 2 == 0) begin
				// Even col
				raw[i] = gOrig[i];
			end
			else begin
				raw[i] = bOrig[i];
			end
		end
		else begin			
			// Odd row, R G R G ......
			if ((i % width) % 2 == 0) begin
				// Even col
				raw[i] = rOrig[i];
			end
			else begin
				raw[i] = gOrig[i];
			end
			
			// Debug
//			if (i > totalPixels - 3) begin
//				$display("i = %d, gOrig[i] = %d, raw[i] = %d", i, gOrig[i], raw[i]);
//			end			
		end
	end
	
	$fclose(r_inFile);
	$fclose(g_inFile);
	$fclose(b_inFile);
	
	iValid = 1'b0;
	iData = 'd0;
	newFrame = 0;
	
	reset = 1'b1;
	@(negedge clk);
	@(negedge clk);
	reset = 1'b0;	
	@(negedge clk);
	newFrame = 1;
	for (int i = 0; i < 32; i++) begin
		@(negedge clk);
		newFrame = 0;
	end
	
	// RGB
	for (int i = 0; i < totalPixels; i++) begin
		//iData	= {rOrig[i], gOrig[i], bOrig[i]};
		iData = raw[i];
		
		iR	= rOrig[i];
		iG	= gOrig[i];
		iB	= bOrig[i];
		iValid	= 1'b1;
		@(negedge clk);
		
		if ((i%width) == width - 1) begin
			// Boundary in between rows
			for (int j = 0; j < 16; j++) begin
				iValid = 0;
				@(negedge clk);
			end
		end
		
	end
	
	iData = 'b0;
	
	
	// Need iValid to be high to keep the pipeline moving
	@(negedge clk);
	// Still need to move the pipeline and leave blanks each row
	for (int i = 0; i < width; i++) begin
		iValid	= 1'b1;
		@(negedge clk);
	
		if (oDoneDemosaic == 1) begin
			iValid = 0;
			break;
		end
	end
	
	@(negedge clk);
	reset = 1'b0;
	
	@(negedge clk);
	reset = 1'b0;
end

//logic	[7:0] rInput [7:0];

//// Conveng Producer
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//	
//	r_outFile = $fopen("demosaicROut", "r");
//	g_outFile = $fopen("demosaicGOut", "r");
//	b_outFile = $fopen("demosaicBOut", "r");
//
//	for (int i = 0; i < totalInFilter; i++) begin
//		integer out1, out2, out3;
//		if (		(i < frontSkip)
//			 ||	(i > totalInFilter - frontSkip)
//			 ||	((i % rowSize) < boundaryWidth)
//			 ||	((i % rowSize) >= (width + boundaryWidth)))
//		begin
//			o_irFilter[i] = 8'b0;
//			o_igFilter[i] = 8'b0;
//			o_ibFilter[i] = 8'b0;
//		end
//		else begin
//			// Read from file
//			out1 = $fscanf(r_outFile, "%d", o_irFilter[i]);
//			out2 = $fscanf(g_outFile, "%d", o_igFilter[i]);
//			out3 = $fscanf(b_outFile, "%d", o_ibFilter[i]);
//			
//			// Debug
////			if (i > 76000) begin
////				$display("in1 = %d, data[%d] = %d, in2 = %d, data[%d] = %d, in3 = %d, data[%d] = %d",
////							in1, i, rOrig[i], in2, i, gOrig[i], in3, i, bOrig[i]);
////			end
//		end
//	end
//	
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);
//	
//	iValid = 1'b0;
//	irData = 'd0;
//	igData = 'd0;
//	ibData = 'd0;
//	newFrame = 0;
//	
//	reset = 1'b1;
//	@(negedge clk);
//	@(negedge clk);
//	reset = 1'b0;	
//	@(negedge clk);
//	newFrame = 1;
//	for (int i = 0; i < 8; i++) begin
//		@(negedge clk);
//		newFrame = 0;
//	end
//	
//	// Provide data as requested
//	while(1) begin
//		@(negedge clk);
//		
//		if (oReq == 1) begin
//			irData	<= {	o_irFilter[oRdAddress+7], o_irFilter[oRdAddress+6], o_irFilter[oRdAddress+5], o_irFilter[oRdAddress+4],
//								o_irFilter[oRdAddress+3], o_irFilter[oRdAddress+2], o_irFilter[oRdAddress+1], o_irFilter[oRdAddress]};
//			rInput[7]	<= o_irFilter[oRdAddress+7]; 
//			rInput[6]	<= o_irFilter[oRdAddress+6];
//			rInput[5]	<= o_irFilter[oRdAddress+5];
//			rInput[4]	<= o_irFilter[oRdAddress+4];
//			rInput[3]	<= o_irFilter[oRdAddress+3];
//			rInput[2]	<= o_irFilter[oRdAddress+2];
//			rInput[1]	<= o_irFilter[oRdAddress+1];
//			rInput[0]	<= o_irFilter[oRdAddress];
//			
//			igData	<= {	o_igFilter[oRdAddress+7], o_igFilter[oRdAddress+6], o_igFilter[oRdAddress+5], o_igFilter[oRdAddress+4],
//								o_igFilter[oRdAddress+3], o_igFilter[oRdAddress+2], o_igFilter[oRdAddress+1], o_igFilter[oRdAddress]};
//				
//			ibData	<= {	o_ibFilter[oRdAddress+7], o_ibFilter[oRdAddress+6], o_ibFilter[oRdAddress+5], o_ibFilter[oRdAddress+4],
//								o_ibFilter[oRdAddress+3], o_ibFilter[oRdAddress+2], o_ibFilter[oRdAddress+1], o_ibFilter[oRdAddress]};
//
//			iValid	= 1'b1;
//		end
//		else begin
//			iValid	= 0;
//		end
//	end	
//	
//	for (int j = 0; j < 16; j++) begin
//		iValid = 0;
//		@(negedge clk);	
//	end
//	
//	@(negedge clk);
//	reset = 1'b0;
//	
//	@(negedge clk);
//	reset = 1'b0;
//end

//logic unsigned	[7:0]		filter_r, filter_g, filter_b;
//logic unsigned	[7:0]		g_filter_r, g_filter_g, g_filter_b;
//logic unsigned [31:0]	pixelCnt = 0;
//// Conveng Consumer
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//
//	r_outFile = $fopen("sharpenROut", "r");
//	g_outFile = $fopen("sharpenGOut", "r");
//	b_outFile = $fopen("sharpenBOut", "r");
//	
//	for (int i = 0; i < totalPixels; i++) begin
//		integer out1, out2, out3;
//		out1 = $fscanf(r_outFile, "%d", rFilter[i]);
//		out2 = $fscanf(g_outFile, "%d", gFilter[i]);
//		out3 = $fscanf(b_outFile, "%d", bFilter[i]);
//		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
//	end
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);	
//	
//	// Wait for reset
//	for (int i = 0; i < 16; i++) begin
//		@(negedge clk);
//	end
//	
//	for (int i = 0; i < totalPixels; i++) begin
//		real rDiff;
//		real gDiff;
//		real bDiff;
//		
//		// Wait for a valid output
//		@(negedge clk);
//		while (!oValidFilter) begin
//			@(negedge clk);
//		end
//		
//		// 7x7 for stripe width 2 and 240p
//		// Each stripe has 480 pixels
//		// Finished (oConvPixelCnt/480) stripes, each stripe has 2 pixels
//		// The current stripe has finished (oConvPixelCnt%480) pixels
//		// The start of the current line is (((oConvPixelCnt%480)-1)>>1)*320
//		// The pixel on the current stripe is (oConvPixelCnt%2);
//		oWrAddress	= (pixelCnt/(height*2))*2 + ((pixelCnt%(height*2))>>1)*width + (pixelCnt%2);
//		
//		//$display("pixelCnt = %d @ time: ", pixelCnt, $time);
//		pixelCnt++;
//		
//		filter_r		= orData;
//		filter_g		= ogData;
//		filter_b		= obData;
//
//		g_filter_r	= rFilter[oWrAddress];
//		g_filter_g	= gFilter[oWrAddress];
//		g_filter_b	= bFilter[oWrAddress];
//		
//		// For power, no validity check
//		rDiff = (filter_r - g_filter_r);
//		gDiff = (filter_g - g_filter_g);
//		bDiff = (filter_b - g_filter_b);
//		
//		if ((rDiff != 0) || (gDiff != 0) || (bDiff != 0)) begin
//			$display("<Conv filter> r: %f, r_golden: %f; g: %f, g_golden: %f; b: %f, b_golden: %f, at time: ",
//						filter_r, g_filter_r, filter_g, g_filter_g, filter_b, g_filter_b, $time);
//			failed = 1;
//		end
//		
//		if (oDoneFilter) begin
//			$display("i = %d, break\n", i, $time);
//			break;
//		end
//		
//		// For power
//		if (i >= 1080) begin
//			$stop(0);
//		end
//	end
//	
//	if (failed == 1) begin
//		$display("Conv filter is wrong");
//	end
//	else begin
//		$display("Conv filter great success!!");
//	end
//	
//	for (int i = 0; i < 10; i++) begin
//		@(negedge clk);
//	end
//	$stop(0);
//end


logic unsigned	[7:0]		g_demosaic_r, g_demosaic_g, g_demosaic_b;

// Demosaic Consumer at demosaic output
initial begin
	integer r_outFile;
	integer g_outFile;
	integer b_outFile;
	
	integer failed = 0;
	
	r_outFile = $fopen("demosaicROut", "r");
	g_outFile = $fopen("demosaicGOut", "r");
	b_outFile = $fopen("demosaicBOut", "r");

	for (int i = 0; i < totalPixels; i++) begin
		integer out1, out2, out3;
		// Read from file
		out1 = $fscanf(r_outFile, "%d", rDemosaic[i]);
		out2 = $fscanf(g_outFile, "%d", gDemosaic[i]);
		out3 = $fscanf(b_outFile, "%d", bDemosaic[i]);
			
			// Debug
//			if (i > 76000) begin
//				$display("in1 = %d, data[%d] = %d, in2 = %d, data[%d] = %d, in3 = %d, data[%d] = %d",
//							in1, i, rOrig[i], in2, i, gOrig[i], in3, i, bOrig[i]);
//			end
	end

	$fclose(r_outFile);
	$fclose(g_outFile);
	$fclose(b_outFile);
	
	for (int i = 0; i < totalPixels; i++) begin
		real rDiff;
		real gDiff;
		real bDiff;
		
		// Wait for a valid output
		@(negedge clk);
		while (!oValidDemosaic) begin
			@(negedge clk);
		end

		g_demosaic_r 	= rDemosaic[i];
		g_demosaic_g	= gDemosaic[i];
		g_demosaic_b	= bDemosaic[i];

		rDiff = (oDemosaicR - g_demosaic_r);
		gDiff = (oDemosaicG - g_demosaic_g);
		bDiff = (oDemosaicB - g_demosaic_b);
		
		if ((rDiff != 0) || (gDiff != 0) || (bDiff != 0)) begin
			$display("<Demosaic> r: %f, r_golden: %f; g: %f, g_golden: %f; b: %f, b_golden: %f, at time: ",
						oDemosaicR, g_demosaic_r, oDemosaicG, g_demosaic_g, oDemosaicB, g_demosaic_b, $time);
			failed = 1;
		end
	end
	
	if (failed == 1) begin
		$display("Demosaic is wrong");
	end
	else begin
		$display("Demosaic great success!!");
	end
	
	for (int i = 0; i < 10; i++) begin
		@(negedge clk);
	end
	
	$stop(0);
end





//// Demosaic Consumer at filter input
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//	
//	r_outFile = $fopen("demosaicROut", "r");
//	g_outFile = $fopen("demosaicGOut", "r");
//	b_outFile = $fopen("demosaicBOut", "r");
//
//	for (int i = 0; i < totalInFilter; i++) begin
//		integer out1, out2, out3;
//		if (		(i < frontSkip)
//			 ||	(i > totalInFilter - frontSkip)
//			 ||	((i % rowSize) < boundaryWidth)
//			 ||	((i % rowSize) >= (width + boundaryWidth)))
//		begin
//			o_irFilter[i] = 8'b0;
//			o_igFilter[i] = 8'b0;
//			o_ibFilter[i] = 8'b0;
//		end
//		else begin
//			// Read from file
//			out1 = $fscanf(r_outFile, "%d", o_irFilter[i]);
//			out2 = $fscanf(g_outFile, "%d", o_igFilter[i]);
//			out3 = $fscanf(b_outFile, "%d", o_ibFilter[i]);
//			
//			// Debug
////			if (i > 76000) begin
////				$display("in1 = %d, data[%d] = %d, in2 = %d, data[%d] = %d, in3 = %d, data[%d] = %d",
////							in1, i, rOrig[i], in2, i, gOrig[i], in3, i, bOrig[i]);
////			end
//		end
//	end
//
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);
//	
//	for (int i = 0; i < totalInFilter; i++) begin
//		real rDiff;
//		real gDiff;
//		real bDiff;
//		
//		// Wait for a valid output
//		@(negedge clk);
//		while (!o_iValidFilter) begin
//			@(negedge clk);
//		end
//
//		g_demosaic_r 	= o_irFilter[i];
//		g_demosaic_g	= o_igFilter[i];
//		g_demosaic_b	= o_ibFilter[i];
//
//		rDiff = (iRFilter - g_demosaic_r);
//		gDiff = (iGFilter - g_demosaic_g);
//		bDiff = (iBFilter - g_demosaic_b);
//		
//		if ((rDiff != 0) || (gDiff != 0) || (bDiff != 0)) begin
//			$display("<Demosaic> r: %f, r_golden: %f; g: %f, g_golden: %f; b: %f, b_golden: %f, at time: ",
//						iRFilter, g_demosaic_r, iGFilter, g_demosaic_g, iBFilter, g_demosaic_b, $time);
//			failed = 1;
//		end
//	end
//	
//	if (failed == 1) begin
//		$display("Demosaic is wrong");
//	end
//	else begin
//		$display("Demosaic great success!!");
//	end
//	
//	for (int i = 0; i < 10; i++) begin
//		@(negedge clk);
//	end
//	
//	//$stop(0);
//end
//
//
//logic unsigned	[7:0]		filter_r, filter_g, filter_b;
//logic unsigned	[7:0]		g_filter_r, g_filter_g, g_filter_b;
//
//// Filter Consumer
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//	
//	r_outFile = $fopen("sharpenROut", "r");
//	g_outFile = $fopen("sharpenGOut", "r");
//	b_outFile = $fopen("sharpenBOut", "r");
//	
//	for (int i = 0; i < totalPixels; i++) begin
//		integer out1, out2, out3;
//		out1 = $fscanf(r_outFile, "%d", rFilter[i]);
//		out2 = $fscanf(g_outFile, "%d", gFilter[i]);
//		out3 = $fscanf(b_outFile, "%d", bFilter[i]);
//		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
//	end
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);
//	
//	// RGB
//	for (int i = 0; i < totalPixels; i++) begin
//		real rDiff;
//		real gDiff;
//		real bDiff;
//		
//		// Wait for a valid output
//		@(negedge clk);
//		while (!oValidFilter) begin
//			@(negedge clk);
//		end
//		
//		filter_r		= oDataFilter[23:16];
//		filter_g		= oDataFilter[15:8];
//		filter_b		= oDataFilter[7:0];
//
//		g_filter_r	= rFilter[i];
//		g_filter_g	= gFilter[i];
//		g_filter_b	= bFilter[i];
//		
//		rDiff = (filter_r - g_filter_r);
//		gDiff = (filter_g - g_filter_g);
//		bDiff = (filter_b - g_filter_b);
//		
//		if ((rDiff != 0) || (gDiff != 0) || (bDiff != 0)) begin
//			$display("<Filter> r: %f, r_golden: %f; g: %f, g_golden: %f; b: %f, b_golden: %f, at time: ",
//						filter_r, g_filter_r, filter_g, g_filter_g, filter_b, g_filter_b, $time);
//			failed = 1;
//		end
//	end
//	
//	if (failed == 1) begin
//		$display("Filter is wrong");
//	end
//	else begin
//		$display("Filter great success!!");
//	end
//	
//	for (int i = 0; i < 10; i++) begin
//		@(negedge clk);
//	end
//	//$stop(0);
//end

//logic signed	[17:0]	g_ycc_y, g_ycc_cb, g_ycc_cr;
//
//// YCC Consumer
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//	
//	r_outFile = $fopen("yOut", "r");
//	g_outFile = $fopen("cbOut", "r");
//	b_outFile = $fopen("crOut", "r");
//	
//	for (int i = 0; i < totalPixels; i++) begin
//		integer out1, out2, out3;
//		out1 = $fscanf(r_outFile, "%d", yMatrix[i]);
//		out2 = $fscanf(g_outFile, "%d", cbMatrix[i]);
//		out3 = $fscanf(b_outFile, "%d", crMatrix[i]);
//		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
//	end
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);
//	
//	// YCC
//	for (int i = 0; i < totalPixels; i++) begin
//		real yDiff;
//		real cbDiff;
//		real crDiff;
//		
//		// Wait for a valid output
//		@(negedge clk);
//		while (!oValidYcc) begin
//			@(negedge clk);
//		end
//		
//		//@(negedge clk);  // Give time for o_out to be updated.
//		g_ycc_y 	= yMatrix[i];
//		g_ycc_cb	= cbMatrix[i];
//		g_ycc_cr	= crMatrix[i];
//		
//		yDiff		= (y - g_ycc_y);
//		cbDiff	= (cb - g_ycc_cb);
//		crDiff	= (cr - g_ycc_cr);
//		
//		if ((yDiff != 0) || (cbDiff != 0) || (crDiff != 0)) begin
//			$display("<YCC> y: %f, y_golden: %f; cb: %f, cb_golden: %f; cr: %f, cr_golden: %f, at time: ",
//						y, g_ycc_y, cb, g_ycc_cb, cr, g_ycc_cr, $time);
//			failed = 1;
//		end
//	end
//	
//	if (failed == 1) begin
//		$display("YCC is wrong");
//	end
//	else begin
//		$display("YCC great success!!");
//	end
//	
//	for (int i = 0; i < 10; i++) begin
//		@(negedge clk);
//	end
//	
//	//$stop(0);
//end
//
//logic signed	[17:0]	g_rgb_r, g_rgb_g, g_rgb_b;
//
//// RGB Consumer
//initial begin
//	integer r_outFile;
//	integer g_outFile;
//	integer b_outFile;
//	
//	integer failed = 0;
//	
//	r_outFile = $fopen("rOut", "r");
//	g_outFile = $fopen("gOut", "r");
//	b_outFile = $fopen("bOut", "r");
//	
//	for (int i = 0; i < totalPixels; i++) begin
//		integer out1, out2, out3;
//		out1 = $fscanf(r_outFile, "%d", rMatrix[i]);
//		out2 = $fscanf(g_outFile, "%d", gMatrix[i]);
//		out3 = $fscanf(b_outFile, "%d", bMatrix[i]);
//		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
//	end
//	$fclose(r_outFile);
//	$fclose(g_outFile);
//	$fclose(b_outFile);
//	
//	// RGB
//	for (int i = 0; i < totalPixels; i++) begin
//		real rDiff;
//		real gDiff;
//		real bDiff;
//		
//		// Wait for a valid output
//		@(negedge clk);
//		while (!oValidRGB) begin
//			@(negedge clk);
//		end
//		
//		g_rgb_r 	= rMatrix[i];
//		g_rgb_g	= gMatrix[i];
//		g_rgb_b	= bMatrix[i];
//		
////		rDiff		= (oFinalR - g_rgb_r);
////		gDiff		= (oFinalG - g_rgb_g);
////		bDiff		= (oFinalB - g_rgb_b);
//		
//		// For power, don't validate
////		if ((rDiff != 0) || (gDiff != 0) || (bDiff != 0)) begin
////			$display("<RGB> r: %f, r_golden: %f; g: %f, g_golden: %f; b: %f, b_golden: %f, at time: ",
////						oFinalR, g_rgb_r, oFinalG, g_rgb_g, oFinalB, g_rgb_b, $time);
////			failed = 1;
////		end
//		
//		// For power
//		if (i >= 1926) begin
//			$stop(0);
//		end
//	end
//	
//	if (failed == 1) begin
//		$display("RGB is wrong");
//	end
//	else begin
//		$display("RGB great success!!");
//	end
//	
//	for (int i = 0; i < 10; i++) begin
//		@(negedge clk);
//	end
//	
//	$stop(0);
//end




endmodule
