`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();


// Input/output of the filter
logic clk;
logic reset;
logic pipeline_rotate;
logic o_valid;
logic o_done;

logic unsigned [7:0]		i_data;
logic unsigned	[7:0]		o_data;


// Input/output array from file
logic unsigned	[7:0]		i_r_data_arr [totalInBytes - 1:0];
logic unsigned	[7:0]		o_r_data_arr [totalOutBytes - 1:0];
logic unsigned	[7:0]		i_g_data_arr [totalInBytes - 1:0];
logic unsigned	[7:0]		o_g_data_arr [totalOutBytes - 1:0];
logic unsigned	[7:0]		i_b_data_arr [totalInBytes - 1:0];
logic unsigned	[7:0]		o_b_data_arr [totalOutBytes - 1:0];

logic unsigned	[7:0]		o_golden_out;

filter dut ( .* );

initial clk = '1;
always #2.5 clk = ~clk;  // 200 MHz clock

// Producer
initial begin
	integer r_inFile;
	integer g_inFile;
	integer b_inFile;
	
	r_inFile = $fopen("rIntFile_orig", "r");
	g_inFile = $fopen("gIntFile_orig", "r");
	b_inFile = $fopen("bIntFile_orig", "r");
	
	for (int i = 0; i < totalInBytes; i++) begin
		integer in1, in2, in3;
		if (		(i < width + 2)
			 ||	(i > totalInBytes - width - 2)
			 ||	((i % (width + 2)) == 0)
			 ||	((i % (width + 2)) == (width + 1)))
		begin
			// The first or the last row, or the
			// beginning or ending of the row, put 0
			i_r_data_arr[i] = 8'b0;
			i_g_data_arr[i] = 8'b0;
			i_b_data_arr[i] = 8'b0;
		end
		else begin
			// Read from file
			in1 = $fscanf(r_inFile, "%d", i_r_data_arr[i]);
			in2 = $fscanf(g_inFile, "%d", i_g_data_arr[i]);
			in3 = $fscanf(b_inFile, "%d", i_b_data_arr[i]);
		end
		/*
		if (in1 == -1) begin
			$display("in1 = %d, data[%d] = %d", in1, i, i_r_data_arr[i]);
		end
		*/
		// Debug
		/*
		if (		(i < width + 2)
			 ||	(i > totalInBytes - width - 2)
			 ||	((i % (width + 2)) == 0)
			 ||	(d == -1))
		
		if (		(i < 2*(width + 2) + 2)
			 &&	(i >= width + 2))
		begin
			$display("d = %d, data[%d] = %d", d, i, i_data_arr[i]);
		end
		*/
	end
	$fclose(r_inFile);
	$fclose(g_inFile);
	$fclose(b_inFile);
	
	pipeline_rotate = 1'b0;
	i_data = 'd0;
	
	reset = 1'b1;
	@(negedge clk);
	reset = 1'b0;	
	
	
	// R
	for (int i = 0; i < totalInBytes; i++) begin
		@(negedge clk);
		i_data	= i_r_data_arr[i];

		pipeline_rotate	= 1'b1;
	end

	// Reset
	while(1) begin
		@(negedge clk);
		if (o_done == 0) begin
			pipeline_rotate	= 1'b1;
		end
		else begin
			// Image done, reset the filter
			pipeline_rotate	= 1'b0;
			reset					= 1'b1;
			break;
		end
	end
	
	@(negedge clk);
	reset = 1'b0;

	// G
	for (int i = 0; i < totalInBytes; i++) begin
		@(negedge clk);
		i_data	= i_g_data_arr[i];

		pipeline_rotate	= 1'b1;
	end
	
	// Reset
	while(1) begin
		@(negedge clk);
		if (o_done == 0) begin
			pipeline_rotate	= 1'b1;
		end
		else begin
			// Image done, reset the filter
			pipeline_rotate	= 1'b0;
			reset					= 1'b1;
			break;
		end
	end
	
	@(negedge clk);
	reset = 1'b0;
	
	// B
	for (int i = 0; i < totalInBytes; i++) begin
		@(negedge clk);
		i_data	= i_b_data_arr[i];

		pipeline_rotate	= 1'b1;
	end
	
	// Reset
	while(1) begin
		@(negedge clk);
		if (o_done == 0) begin
			pipeline_rotate	= 1'b1;
		end
		else begin
			// Image done, reset the filter
			pipeline_rotate	= 1'b0;
			reset					= 1'b1;
			break;
		end
	end
	
	@(negedge clk);
	reset = 1'b0;

	
end

// Consumer
initial begin
	static real rms = 0.0;
	static integer tmp = 0;
	
	integer r_outFile;
	integer g_outFile;
	integer b_outFile;
	
	r_outFile = $fopen("rIntFile_out", "r");
	g_outFile = $fopen("gIntFile_out", "r");
	b_outFile = $fopen("bIntFile_out", "r");
	
	for (int i = 0; i < totalOutBytes; i++) begin
		integer out1, out2, out3;
		out1 = $fscanf(r_outFile, "%d", o_r_data_arr[i]);
		out2 = $fscanf(g_outFile, "%d", o_g_data_arr[i]);
		out3 = $fscanf(b_outFile, "%d", o_b_data_arr[i]);
		//$display("d = %d, data[%d] = %d", d, i, o_data_arr[i]);
	end
	$fclose(r_outFile);
	$fclose(g_outFile);
	$fclose(b_outFile);
	
	o_golden_out = 8'b0;
	
	// R
	for (int i = 0; i < totalOutBytes; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!o_valid) begin
			@(posedge clk);
		end
		
		@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_data);
		o_golden_out = o_r_data_arr[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		if (diff != 0) begin
			$display("<R> diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
		end
	end
	
	rms /= totalOutBytes;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 10) begin
		$display("<R> Average RMS Error is above 10 units - something is probably wrong");
	end
	else begin
		$display("<R> Error is within 10 units - great success!!");
	end
	
	rms = 0;
	
	// G
	for (int i = 0; i < totalOutBytes; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!o_valid) begin
			@(posedge clk);
		end
		
		@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_data);
		o_golden_out = o_g_data_arr[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		if (diff != 0) begin
			$display("<G> diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
			tmp += 1;
		end
		
		// Debug
		if (tmp == 5) begin
			$stop(0);
		end
	end
	
	rms /= totalOutBytes;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 10) begin
		$display("<G> Average RMS Error is above 10 units - something is probably wrong");
	end
	else begin
		$display("<G> Error is within 10 units - great success!!");
	end
	
	rms = 0;
	
	// B
	for (int i = 0; i < totalOutBytes; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!o_valid) begin
			@(posedge clk);
		end
		
		@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_data);
		o_golden_out = o_b_data_arr[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		if (diff != 0) begin
			$display("<B> diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
		end
	end
	
	rms /= totalOutBytes;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 10) begin
		$display("<B> Average RMS Error is above 10 units - something is probably wrong");
	end
	else begin
		$display("<B> Error is within 10 units - great success!!");
	end
	
	
	
	$stop(0);
end







endmodule
