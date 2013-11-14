`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInMatrix	= width*height;
localparam	totalInFilter	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();


// Input/output of the filter
logic 	clk;
logic 	reset;
logic		iValid;
logic		oDone;

logic	signed	[17:0]	y, cb, cr;
logic							yccValid;
logic							yccDone;

logic	unsigned [23:0]	iData;
logic	unsigned	[23:0]	oData;
logic							oValid;


// Input/output array from file
logic unsigned	[7:0]		rOrig [totalInMatrix - 1:0];
logic unsigned	[7:0]		gOrig [totalInMatrix - 1:0];
logic unsigned	[7:0]		bOrig [totalInMatrix - 1:0];

logic unsigned	[17:0]	yMatrix [totalOutBytes-1:0];
logic unsigned	[17:0]	cbMatrix [totalOutBytes-1:0];
logic unsigned	[17:0]	crMatrix [totalOutBytes-1:0];


logic unsigned	[53:0]	o_golden_out;

processing #(.width(width),	.height(height))
dut ( .* );

initial clk = '1;
always #2.5 clk = ~clk;  // 200 MHz clock


// Producer
initial begin
	integer r_inFile;
	integer g_inFile;
	integer b_inFile;
	
	r_inFile = $fopen("rOrig", "r");
	g_inFile = $fopen("gOrig", "r");
	b_inFile = $fopen("bOrig", "r");
	
	for (int i = 0; i < totalInMatrix; i++) begin
		integer in1, in2, in3;
		
		// Read from file
		in1 = $fscanf(r_inFile, "%d", rOrig[i]);
		in2 = $fscanf(g_inFile, "%d", gOrig[i]);
		in3 = $fscanf(b_inFile, "%d", bOrig[i]);
	end
	
	$fclose(r_inFile);
	$fclose(g_inFile);
	$fclose(b_inFile);
	
//	r_inFile = $fopen("rIntFile_orig", "r");
//	g_inFile = $fopen("gIntFile_orig", "r");
//	b_inFile = $fopen("bIntFile_orig", "r");
//	
//	// feeding filter
//	
//	for (int i = 0; i < totalInBytes; i++) begin
//		integer in1, in2, in3;
//		if (		(i < width + 2)
//			 ||	(i > totalInBytes - width - 2)
//			 ||	((i % (width + 2)) == 0)
//			 ||	((i % (width + 2)) == (width + 1)))
//		begin
//			// The first or the last row, or the
//			// beginning or ending of the row, put 0
//			i_r_data_arr[i] = 8'b0;
//			i_g_data_arr[i] = 8'b0;
//			i_b_data_arr[i] = 8'b0;
//		end
//		else begin
//			// Read from file
//			in1 = $fscanf(r_inFile, "%d", i_r_data_arr[i]);
//			in2 = $fscanf(g_inFile, "%d", i_g_data_arr[i]);
//			in3 = $fscanf(b_inFile, "%d", i_b_data_arr[i]);
//		end
//	
//		//$display("d = %d, data[%d] = %d", d, i, i_data_arr[i]);
//
//	end
//	$fclose(r_inFile);
//	$fclose(g_inFile);
//	$fclose(b_inFile);
	
	iValid = 1'b0;
	iData = 'd0;
	
	reset = 1'b1;
	@(negedge clk);
	@(negedge clk);
	reset = 1'b0;	
	
	// RGB
	for (int i = 0; i < totalInMatrix; i++) begin
		@(negedge clk);
		iData	= {rOrig[i], gOrig[i], bOrig[i]};
		iValid	= 1'b1;
	end
	
	// Need iValid to be high to keep the pipeline moving
	while(1) begin
		@(negedge clk);
		if (yccDone == 0) begin
			iValid	= 1'b1;
		end
		else begin
			// Image done, ycc should be automatically reset
			// .(reset|yccDone)
			iValid	= 1'b0;
			//reset		= 1'b1;
			break;
		end
	end
	
	@(negedge clk);
	reset = 1'b0;
	
	@(negedge clk);
	reset = 1'b0;

	
end

logic signed	[17:0]	golden_y, golden_cb, golden_cr;


// YCC Consumer
initial begin
	static real rms = 0.0;
	static integer tmp = 0;
	
	integer r_outFile;
	integer g_outFile;
	integer b_outFile;
	
	r_outFile = $fopen("yOut", "r");
	g_outFile = $fopen("cbOut", "r");
	b_outFile = $fopen("crOut", "r");
	
	for (int i = 0; i < totalOutBytes; i++) begin
		integer out1, out2, out3;
		out1 = $fscanf(r_outFile, "%d", yMatrix[i]);
		out2 = $fscanf(g_outFile, "%d", cbMatrix[i]);
		out3 = $fscanf(b_outFile, "%d", crMatrix[i]);
		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
	end
	$fclose(r_outFile);
	$fclose(g_outFile);
	$fclose(b_outFile);
	
	o_golden_out = 'b0;
	
	// YCC
	for (int i = 0; i < totalOutBytes; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(negedge clk);
		while (!yccValid) begin
			@(negedge clk);
		end
		
		//@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'({y, cb, cr});
		o_golden_out = {yMatrix[i], cbMatrix[i], crMatrix[i]};
		
		golden_y 	= yMatrix[i];
		golden_cb	= cbMatrix[i];
		golden_cr	= crMatrix[i];
		
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		if (diff != 0) begin
			$display("<YCC> diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
		end
	end
	
	rms /= totalOutBytes;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 10) begin
		$display("<YCC> Average RMS Error is above 10 units - something is probably wrong");
	end
	else begin
		$display("<YCC> Error is within 10 units - great success!!");
	end
	
	
	
//	// RGB
//	for (int i = 0; i < totalOutBytes; i++) begin
//		real v1;
//		real v2;
//		real diff;
//		
//		// Wait for a valid output
//		@(posedge clk);
//		while (!oValid) begin
//			@(posedge clk);
//		end
//		
//		@(negedge clk);  // Give time for o_out to be updated.
//		v1 = real'(oData);
//		o_golden_out = {o_r_data_arr[i], o_g_data_arr[i], o_b_data_arr[i]};
//		v2 = real'(o_golden_out);
//		diff = (v1 - v2);
//		
//		rms += diff*diff;
//		if (diff != 0) begin
//			$display("<R> diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
//		end
//	end
//	
//	rms /= totalOutBytes;
//	rms = rms ** (0.5);
//	
//	$display("RMS Error: %f", rms);
//	if (rms > 10) begin
//		$display("Average RMS Error is above 10 units - something is probably wrong");
//	end
//	else begin
//		$display("Error is within 10 units - great success!!");
//	end
	
	for (int i = 0; i < 10; i++) begin
		@(negedge clk);
	end
	
	rms = 0;
	
	$stop(0);
end







endmodule
