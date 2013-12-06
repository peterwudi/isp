`include "params.v"

module filter_fifo_conveng
(
	input 				clk,
	input 				reset,
	input					iValid,
	input		[2:0]		mode,
	input		[63:0]	irData, igData, ibData,
	
	output				oReq,
	output	[31:0]	oRdAddress,
	output	[31:0]	oPixelCnt,
	//output	[31:0]	oWrAddress,
	//output	[31:0]	oData,
	// TODO, for now use 7x7
	output	[7:0]		orData, ogData, obData,
	
	output				oValid,
	output				oDone
);
parameter	width			= 1920;
parameter	height		= 1080;
parameter	kernel_size	= 7;

wire	[31:0]	r_conv_out, g_conv_out, b_conv_out;

conveng r_conv
(
	.clk(clk),
	.reset(reset),

	.iData(irData),
	.iValid(iValid),
	.mode(mode),
	
	.iWidth(width),
	.iHeight(height),
	
	.oReq(oReq),
	.oRdAddress(oRdAddress),
	//.oWrAddress(oWrAddress),
	.oPixelCnt(oPixelCnt),
	.oData(r_conv_out),
	.oValid(oValid),
	.oDone(oDone)
);

conveng g_conv
(
	.clk(clk),
	.reset(reset),

	.iData(igData),
	.iValid(iValid),
	.mode(mode),
	
	.iWidth(width),
	.iHeight(height),
	
	.oReq(),
	.oRdAddress(),
	.oPixelCnt(),
	//.oWrAddress(),
	.oData(g_conv_out),
	.oValid(),
	.oDone()
);

conveng b_conv
(
	.clk(clk),
	.reset(reset),

	.iData(ibData),
	.iValid(iValid),
	.mode(mode),
	
	.iWidth(width),
	.iHeight(height),
	
	.oReq(),
	.oRdAddress(),
	.oPixelCnt(),
	//.oWrAddress(),
	.oData(b_conv_out),
	.oValid(),
	.oDone()
);

assign orData = r_conv_out[31:24];
assign ogData = g_conv_out[31:24];
assign obData = b_conv_out[31:24];

endmodule


module filter_fifo_7
(
	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);

parameter	width			= 1920;
parameter	height		= 1080;
parameter	kernel_size	= 7;

localparam	boundary_width			= (kernel_size - 1)/2;
localparam	row_pipeline_depth	= width + 2*boundary_width;
localparam	frontSkipPixels		= row_pipeline_depth * boundary_width;

// For odd x odd kernels, need (kernel_size-1)/2 rows
// of 0's before and after the actual image.
// e.g. 3x3 kernel needs 1 row.


// For odd x odd kernels, need kernel_size-1 cycles
// before a row can be processed.
// e.g. 3x3 kernel needs 2 cycles to get the boundary 0 to
// the 2nd to last stage, and the next cycle performs a valid
// result.
localparam	pixels_needed_before_proc = boundary_width+1;

localparam	cycles_proc	= 10;
// Cycles needed for post processing, (e.g. factor, bias, truncation etc.)
localparam	cycles_post_proc	= 1;


// number of data ready rows, data is valid when ready_rows == kernel_size
reg	[6:0]	ready_rows;
wire			valid;
reg			img_done;

// Row counter
reg	[31:0] row_cnt;

// Regs to detect whether an image is done
// NOTE: this is NOT height
reg	[31:0] rows_done;


// Post processing
//	The output need to be in the range 0 - 255
reg			o_valid_pipeline	[cycles_proc+cycles_post_proc-1 : 0];
reg			o_done_pipeline	[cycles_proc+cycles_post_proc-1 : 0];

wire	signed	[31:0]	conv_o_r;
wire	signed	[31:0]	conv_o_g;
wire	signed	[31:0]	conv_o_b;

reg				[7:0]		res_r;
reg				[7:0]		res_g;
reg				[7:0]		res_b;


wire	unsigned	[23:0]	tap		[6:0];	

wire	unsigned	[55:0]	data_r;
wire	unsigned	[55:0]	data_g;
wire	unsigned	[55:0]	data_b;

reg							r_iValid;
reg	unsigned [23:0]	r_iData;

// "r_iData" is a buffer of input data. iData always gets buffered
// here first, and then depending on what iValid is, we decide
// whether to write it into the FIFO or not.
//
// "r_iValid" is the delayed iValid, it controls the pipeline. i.e.
// when r_iValid is low, the pipeline is stalled, and no invalid
// data can get into the pipeline.
//
// "valid" is used to identify which output data is valid. All data
// inside the pipeline are valid, however, when the pixel being
// processed is outside of the boundary, the result is not valid.
// "valid" is carried outside of the convolution unit.
always @(posedge clk) begin
	if (reset) begin
		r_iValid		<= 0;
		r_iData		<= 'b0;
	end
	else begin
		r_iValid		<= iValid;
		r_iData		<= iData;
	end
end

// Depth is width+boundary_width*2
filter_shift_reg_7tap u0
(
	.clken(r_iValid),
	.clock(clk),
	.shiftin(r_iData),
	.shiftout(),
	.taps0x(tap[0]),
	.taps1x(tap[1]),
	.taps2x(tap[2]),
	.taps3x(tap[3]),
	.taps4x(tap[4]),
	.taps5x(tap[5]),
	.taps6x(tap[6])
);

//filter_shift_reg_7tap_240p u0
//(
//	.clken(r_iValid),
//	.clock(clk),
//	.shiftin(r_iData),
//	.shiftout(),
//	.taps0x(tap[0]),
//	.taps1x(tap[1]),
//	.taps2x(tap[2]),
//	.taps3x(tap[3]),
//	.taps4x(tap[4]),
//	.taps5x(tap[5]),
//	.taps6x(tap[6])
//);


always @(posedge clk) begin
	if (reset) begin
		ready_rows		<= 'b0;
		row_cnt			<= 'b0;
		rows_done		<= 'b0;
		img_done			<= 1'b0;
	end
	else begin
		if (r_iValid) begin
			// The row buffer will be filled with i_data
			// need to put a 0 before the 1st pixel
			//
			// row_cnt range from 0 to row_pipeline_depth - 1
			if (row_cnt < row_pipeline_depth - 1) begin
				// Increment row counter
				row_cnt	<= row_cnt + 1;
			end
			else begin
				// Reset row counter and use the next buffer,
				// which is always available because all the data
				// are perfectly aligned
				row_cnt	<= 0;
				
				rows_done <= rows_done + 1;
				
				if (rows_done < height + 2*boundary_width) begin
					img_done		<= 1'b0;
				end
				else begin
					img_done		<= 1'b1;
					rows_done	<= 'b0;
				end
				
				// Just finished a row, increment ready_rows
				if (ready_rows < kernel_size) begin
					ready_rows	<= ready_rows + 1;
				end
			end
		end
	end
	
end

assign	data_r	= {tap[0][23:16],	tap[1][23:16],	tap[2][23:16], tap[3][23:16],
							tap[4][23:16],	tap[5][23:16],	tap[6][23:16]};
assign	data_g	= {tap[0][15:8],	tap[1][15:8],	tap[2][15:8],	tap[3][15:8],
							tap[4][15:8],	tap[5][15:8],	tap[6][15:8]};
assign	data_b	= {tap[0][7:0],	tap[1][7:0],	tap[2][7:0],	tap[3][7:0],
							tap[4][7:0],	tap[5][7:0],	tap[6][7:0]};

							
// If data is ready (we have kernel_size rows)
// && is inside the active pixel area
// && image is not done
assign valid = (		 (ready_rows == kernel_size)
						&& (		(row_cnt >= kernel_size - 1)
								&&	row_cnt < row_pipeline_depth)
						&& (img_done == 0)) ? 1:0;

convolution_7x7 r_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_r),
	.o_data(conv_o_r)
);

convolution_7x7 g_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_g),
	.o_data(conv_o_g)
);

convolution_7x7 b_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_b),
	.o_data(conv_o_b)
);


always @(posedge clk) begin
	if (reset) begin
		res_r					<= 8'd0;
		res_g					<= 8'd0;
		res_b					<= 8'd0;
		
		o_valid_pipeline[0]	<= 1'b0;
		o_done_pipeline[0]	<= 1'b0;
	end
	else if (r_iValid) begin
		// Pass the signals
		o_valid_pipeline[0]	<= valid;
		o_done_pipeline[0]	<= img_done;
	
		// Truncation
		if (conv_o_r > 255) begin
			res_r	<= 8'd255;
		end
		else if (conv_o_r < 0) begin
			res_r	<= 8'd0;
		end
		else begin
			res_r	<= conv_o_r[7:0];
		end
		
		if (conv_o_g > 255) begin
			res_g	<= 8'd255;
		end
		else if (conv_o_g < 0) begin
			res_g	<= 8'd0;
		end
		else begin
			res_g	<= conv_o_g[7:0];
		end
		
		if (conv_o_b > 255) begin
			res_b	<= 8'd255;
		end
		else if (conv_o_b < 0) begin
			res_b	<= 8'd0;
		end
		else begin
			res_b	<= conv_o_b[7:0];
		end
	end
end

genvar i;
generate
	// Post processing
	for (i = 1; i < cycles_proc+cycles_post_proc; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else if (r_iValid) begin
				o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
				o_done_pipeline[i]	<= o_done_pipeline[i-1];
			end
		end
	end
endgenerate


assign	oDone		= o_done_pipeline[cycles_proc+cycles_post_proc - 1];
assign	oValid	= (r_iValid == 1) ? o_valid_pipeline[cycles_proc+cycles_post_proc - 1]:0;
assign	oData		= {res_r, res_g, res_b};


endmodule


module filter_fifo_7_sym
(
	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);

parameter	width			= 1920;
parameter	height		= 1080;
parameter	kernel_size	= 7;

localparam	boundary_width			= (kernel_size - 1)/2;
localparam	row_pipeline_depth	= width + 2*boundary_width;
localparam	frontSkipPixels		= row_pipeline_depth * boundary_width;

// For odd x odd kernels, need (kernel_size-1)/2 rows
// of 0's before and after the actual image.
// e.g. 3x3 kernel needs 1 row.


// For odd x odd kernels, need kernel_size-1 cycles
// before a row can be processed.
// e.g. 3x3 kernel needs 2 cycles to get the boundary 0 to
// the 2nd to last stage, and the next cycle performs a valid
// result.
localparam	pixels_needed_before_proc = boundary_width+1;

localparam	cycles_proc	= 10;
// Cycles needed for post processing, (e.g. factor, bias, truncation etc.)
localparam	cycles_post_proc	= 1;


// number of data ready rows, data is valid when ready_rows == kernel_size
reg	[6:0]	ready_rows;
wire			valid;
reg			img_done;

// Row counter
reg	[31:0] row_cnt;

// Regs to detect whether an image is done
// NOTE: this is NOT height
reg	[31:0] rows_done;


// Post processing
//	The output need to be in the range 0 - 255
reg			o_valid_pipeline	[cycles_proc+cycles_post_proc-1 : 0];
reg			o_done_pipeline	[cycles_proc+cycles_post_proc-1 : 0];

wire	signed	[31:0]	conv_o_r;
wire	signed	[31:0]	conv_o_g;
wire	signed	[31:0]	conv_o_b;

reg				[7:0]		res_r;
reg				[7:0]		res_g;
reg				[7:0]		res_b;


wire	unsigned	[23:0]	tap		[6:0];	

wire	unsigned	[55:0]	data_r;
wire	unsigned	[55:0]	data_g;
wire	unsigned	[55:0]	data_b;

reg							r_iValid;
reg	unsigned [23:0]	r_iData;

// "r_iData" is a buffer of input data. iData always gets buffered
// here first, and then depending on what iValid is, we decide
// whether to write it into the FIFO or not.
//
// "r_iValid" is the delayed iValid, it controls the pipeline. i.e.
// when r_iValid is low, the pipeline is stalled, and no invalid
// data can get into the pipeline.
//
// "valid" is used to identify which output data is valid. All data
// inside the pipeline are valid, however, when the pixel being
// processed is outside of the boundary, the result is not valid.
// "valid" is carried outside of the convolution unit.
always @(posedge clk) begin
	if (reset) begin
		r_iValid		<= 0;
		r_iData		<= 'b0;
	end
	else begin
		r_iValid		<= iValid;
		r_iData		<= iData;
	end
end

// Depth is width+boundary_width*2
filter_shift_reg_7tap u0
(
	.clken(r_iValid),
	.clock(clk),
	.shiftin(r_iData),
	.shiftout(),
	.taps0x(tap[0]),
	.taps1x(tap[1]),
	.taps2x(tap[2]),
	.taps3x(tap[3]),
	.taps4x(tap[4]),
	.taps5x(tap[5]),
	.taps6x(tap[6])
);

//filter_shift_reg_7tap_240p u0
//(
//	.clken(r_iValid),
//	.clock(clk),
//	.shiftin(r_iData),
//	.shiftout(),
//	.taps0x(tap[0]),
//	.taps1x(tap[1]),
//	.taps2x(tap[2]),
//	.taps3x(tap[3]),
//	.taps4x(tap[4]),
//	.taps5x(tap[5]),
//	.taps6x(tap[6])
//);


always @(posedge clk) begin
	if (reset) begin
		ready_rows		<= 'b0;
		row_cnt			<= 'b0;
		rows_done		<= 'b0;
		img_done			<= 1'b0;
	end
	else begin
		if (r_iValid) begin
			// The row buffer will be filled with i_data
			// need to put a 0 before the 1st pixel
			//
			// row_cnt range from 0 to row_pipeline_depth - 1
			if (row_cnt < row_pipeline_depth - 1) begin
				// Increment row counter
				row_cnt	<= row_cnt + 1;
			end
			else begin
				// Reset row counter and use the next buffer,
				// which is always available because all the data
				// are perfectly aligned
				row_cnt	<= 0;
				
				rows_done <= rows_done + 1;
				
				if (rows_done < height + 2*boundary_width) begin
					img_done		<= 1'b0;
				end
				else begin
					img_done		<= 1'b1;
					rows_done	<= 'b0;
				end
				
				// Just finished a row, increment ready_rows
				if (ready_rows < kernel_size) begin
					ready_rows	<= ready_rows + 1;
				end
			end
		end
	end
	
end

assign	data_r	= {tap[0][23:16],	tap[1][23:16],	tap[2][23:16], tap[3][23:16],
							tap[4][23:16],	tap[5][23:16],	tap[6][23:16]};
assign	data_g	= {tap[0][15:8],	tap[1][15:8],	tap[2][15:8],	tap[3][15:8],
							tap[4][15:8],	tap[5][15:8],	tap[6][15:8]};
assign	data_b	= {tap[0][7:0],	tap[1][7:0],	tap[2][7:0],	tap[3][7:0],
							tap[4][7:0],	tap[5][7:0],	tap[6][7:0]};

							
// If data is ready (we have kernel_size rows)
// && is inside the active pixel area
// && image is not done
assign valid = (		 (ready_rows == kernel_size)
						&& (		(row_cnt >= kernel_size - 1)
								&&	row_cnt < row_pipeline_depth)
						&& (img_done == 0)) ? 1:0;

convolution_7x7_sym r_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_r),
	.o_data(conv_o_r)
);

convolution_7x7_sym g_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_g),
	.o_data(conv_o_g)
);

convolution_7x7_sym b_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_data(data_b),
	.o_data(conv_o_b)
);


always @(posedge clk) begin
	if (reset) begin
		res_r					<= 8'd0;
		res_g					<= 8'd0;
		res_b					<= 8'd0;
		
		o_valid_pipeline[0]	<= 1'b0;
		o_done_pipeline[0]	<= 1'b0;
	end
	else if (r_iValid) begin
		// Pass the signals
		o_valid_pipeline[0]	<= valid;
		o_done_pipeline[0]	<= img_done;
	
		// Truncation
		if (conv_o_r > 255) begin
			res_r	<= 8'd255;
		end
		else if (conv_o_r < 0) begin
			res_r	<= 8'd0;
		end
		else begin
			res_r	<= conv_o_r[7:0];
		end
		
		if (conv_o_g > 255) begin
			res_g	<= 8'd255;
		end
		else if (conv_o_g < 0) begin
			res_g	<= 8'd0;
		end
		else begin
			res_g	<= conv_o_g[7:0];
		end
		
		if (conv_o_b > 255) begin
			res_b	<= 8'd255;
		end
		else if (conv_o_b < 0) begin
			res_b	<= 8'd0;
		end
		else begin
			res_b	<= conv_o_b[7:0];
		end
	end
end

genvar i;
generate
	// Post processing
	for (i = 1; i < cycles_proc+cycles_post_proc; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else if (r_iValid) begin
				o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
				o_done_pipeline[i]	<= o_done_pipeline[i-1];
			end
		end
	end
endgenerate


assign	oDone		= o_done_pipeline[cycles_proc+cycles_post_proc - 1];
assign	oValid	= (r_iValid == 1) ? o_valid_pipeline[cycles_proc+cycles_post_proc - 1]:0;
assign	oData		= {res_r, res_g, res_b};


endmodule
















module filter_fifo_3
(
	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);

parameter	width			= 320;
parameter	height		= 240;
parameter	kernel_size	= 3;

localparam	boundary_width = (kernel_size - 1)/2;
localparam	row_pipeline_depth = width + 2*boundary_width;

// For odd x odd kernels, need (kernel_size-1)/2 rows
// of 0's before and after the actual image.
// e.g. 3x3 kernel needs 1 row.


// For odd x odd kernels, need kernel_size-1 cycles
// before a row can be processed.
// e.g. 3x3 kernel needs 2 cycles to get the boundary 0 to
// the 2nd to last stage, and the next cycle performs a valid
// result.
localparam	pixels_needed_before_proc = boundary_width+1;

localparam	cycles_proc	= 8;
// Cycles needed for post processing, (e.g. factor, bias, truncation etc.)
localparam	cycles_post_proc	= 1;


// number of data ready rows, data is valid when ready_rows == kernel_size
reg	[6:0]	ready_rows;
wire			valid;
reg			img_done;

// Row counter
reg	[12:0] row_cnt;

// Regs to detect whether an image is done
// NOTE: this is NOT height
reg	[12:0] rows_done;


// Post processing
//	The output need to be in the range 0 - 255
reg			o_valid_pipeline	[cycles_proc+cycles_post_proc-1 : 0];
reg			o_done_pipeline	[cycles_proc+cycles_post_proc-1 : 0];

wire	signed	[34:0]	conv_o_r;
wire	signed	[34:0]	conv_o_g;
wire	signed	[34:0]	conv_o_b;

reg				[7:0]		res_r;
reg				[7:0]		res_g;
reg				[7:0]		res_b;


wire	unsigned	[23:0]	tap		[2:0];	

wire	unsigned	[23:0]	data_r;
wire	unsigned	[23:0]	data_g;
wire	unsigned	[23:0]	data_b;

reg							r_iValid;
reg	unsigned [23:0]	r_iData;

// "r_iData" is a buffer of input data. iData always gets buffered
// here first, and then depending on what iValid is, we decide
// whether to write it into the FIFO or not.
//
// "r_iValid" is the delayed iValid, it controls the pipeline. i.e.
// when r_iValid is low, the pipeline is stalled, and no invalid
// data can get into the pipeline.
//
// "valid" is used to identify which output data is valid. All data
// inside the pipeline are valid, however, when the pixel being
// processed is outside of the boundary, the result is not valid.
// "valid" is carried outside of the convolution unit.
always @(posedge clk) begin
	if (reset) begin
		r_iValid		<= 0;
		r_iData		<= 'b0;
	end
	else begin
		r_iValid		<= iValid;
		r_iData		<= iData;
	end
end

filter_shift_reg u0
(
	.clken(r_iValid),
	.clock(clk),
	.shiftin(r_iData),
	.shiftout(),
	.taps0x(tap[0]),
	.taps1x(tap[1]),
	.taps2x(tap[2])
);


always @(posedge clk) begin
	if (reset) begin
		ready_rows		<= 'b0;
		row_cnt			<= 'b0;
		rows_done		<= 'b0;
		img_done			<= 1'b0;
	end
	else begin
		if (r_iValid) begin
			// The row buffer will be filled with i_data
			// need to put a 0 before the 1st pixel
			//
			// row_cnt range from 0 to row_pipeline_depth - 1
			if (row_cnt < row_pipeline_depth - 1) begin
				// Increment row counter
				row_cnt	<= row_cnt + 1;
			end
			else begin
				// Reset row counter and use the next buffer,
				// which is always available because all the data
				// are perfectly aligned
				row_cnt	<= 0;
				
				rows_done <= rows_done + 1;
				
				if (rows_done < height + 2*boundary_width) begin
					img_done		<= 1'b0;
				end
				else begin
					img_done		<= 1'b1;
					rows_done	<= 'b0;
				end
				
				// Just finished a row, increment ready_rows
				if (ready_rows < kernel_size) begin
					ready_rows	<= ready_rows + 1;
				end
			end
		end
	end
	
end

assign	data_r	= {tap[0][23:16],	tap[1][23:16],	tap[2][23:16]};
assign	data_g	= {tap[0][15:8],		tap[1][15:8],	tap[2][15:8]};
assign	data_b	= {tap[0][7:0],		tap[1][7:0],	tap[2][7:0]};

// If data is ready (we have kernel_size rows)
// && is inside the active pixel area
// && image is not done
assign valid = (		 (ready_rows == kernel_size)
						&& (		(row_cnt >= pixels_needed_before_proc)
								&&	row_cnt < row_pipeline_depth-boundary_width+1)
						&& (img_done == 0)) ? 1:0;


convolution_3x3 r_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_done(img_done),
	.i_data(data_r),
	.o_data(conv_o_r)
);

convolution_3x3 g_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_done(img_done),
	.i_data(data_g),
	.o_data(conv_o_g)
);

convolution_3x3 b_conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(r_iValid),
	.i_done(img_done),
	.i_data(data_b),
	.o_data(conv_o_b)
);


always @(posedge clk) begin
	if (reset) begin
		res_r					<= 8'd0;
		res_g					<= 8'd0;
		res_b					<= 8'd0;
		
		o_valid_pipeline[0]	<= 1'b0;
		o_done_pipeline[0]	<= 1'b0;
	end
	else if (r_iValid) begin
		// Pass the signals
		o_valid_pipeline[0]	<= valid;
		o_done_pipeline[0]	<= img_done;
	
		// Truncation
		if (conv_o_r > 255) begin
			res_r	<= 8'd255;
		end
		else if (conv_o_r < 0) begin
			res_r	<= 8'd0;
		end
		else begin
			res_r	<= conv_o_r[7:0];
		end
		
		if (conv_o_g > 255) begin
			res_g	<= 8'd255;
		end
		else if (conv_o_g < 0) begin
			res_g	<= 8'd0;
		end
		else begin
			res_g	<= conv_o_g[7:0];
		end
		
		if (conv_o_b > 255) begin
			res_b	<= 8'd255;
		end
		else if (conv_o_b < 0) begin
			res_b	<= 8'd0;
		end
		else begin
			res_b	<= conv_o_b[7:0];
		end
	end
end

genvar i;
generate
	// Post processing
	for (i = 1; i < cycles_proc+cycles_post_proc; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else if (r_iValid) begin
				o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
				o_done_pipeline[i]	<= o_done_pipeline[i-1];
			end
		end
	end
endgenerate


assign	oDone		= o_done_pipeline[cycles_proc+cycles_post_proc - 1];
assign	oValid	= (r_iValid == 1) ? o_valid_pipeline[cycles_proc+cycles_post_proc - 1]:0;
assign	oData		= {res_r, res_g, res_b};


endmodule


