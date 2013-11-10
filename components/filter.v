module filter_fifo
(
	input 	clk,
	input 	reset,
	input		iValid,
	output	oValid,
	output	oDone,
	
	input		unsigned [23:0]	iData,
	output	unsigned	[23:0]	oData
);

parameter	img_width	= 320;
parameter	img_height	= 240;

parameter	row_pipeline_depth = img_width + 2;
parameter	kernel_size	= 3;

// For odd x odd kernels, need (kernel_size-1)/2 rows
// of 0's before and after the actual image.
// e.g. 3x3 kernel needs 1 row.
localparam	rows_needed_before_proc = (kernel_size - 1)/2;

// For odd x odd kernels, need kernel_size-1 cycles
// before a row can be processed.
// e.g. 3x3 kernel needs 2 cycles to get the boundary 0 to
// the 2nd to last stage, and the next cycle performs a valid
// result.
localparam	pixels_needed_before_proc = kernel_size - 1;

// Cycles needed for post processing, (e.g. factor, bias, truncation etc.)
localparam	cycles_post_proc	= 1;


// number of data ready rows, data is valid when ready_rows == kernel_size
reg	[6:0]	ready_rows;
reg			valid;
reg			img_done;

// Row counter
reg	[12:0] row_cnt;

// Regs to detect whether an image is done
// NOTE: this is NOT img_height
reg	[12:0] rows_done;


// Post processing
//	The output need to be in the range 0 - 255
wire			conv_o_valid;

wire			conv_o_done;
reg			o_valid_pipeline	[cycles_post_proc - 1 : 0];
reg			o_done_pipeline	[cycles_post_proc - 1 : 0];


wire	signed	[34:0]	conv_o_r;
wire	signed	[34:0]	conv_o_g;
wire	signed	[34:0]	conv_o_b;

reg				[7:0]		res_r;
reg				[7:0]		res_g;
reg				[7:0]		res_b;


wire				[34:0]


filter_shift_reg u0
(
	.clken(iValid),
	.clock(clk),
	.shiftin(iData),
	.shiftout(),
	.taps0x(),
	taps1x,
	taps2x);





always @(posedge clk) begin
	if (reset) begin
		valid				<= 1'b0;
		ready_rows		<= 'b0;
		row_cnt			<= 'b0;
		rows_done		<= 'b0;
		img_done			<= 1'b0;
	end
	else if (pipeline_rotate) begin
		// pipeline[bufferID][0] will be filled with i_data
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
			
			if (rows_done < img_height + 2*rows_needed_before_proc) begin
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
			
			// The pipeline that just got filled shouldn't be
			// written to, enable the next pipeline.
			//
			//	At the end of the pipelines, there's a crossbar
			// that feeds the filter.
			// TODO: Could use generate, make sure quartus
			// knows this is a mux...
			case (bufferID)
				2'b00: begin
					pipeline_wren	<= 4'b0010;
				end
				2'b01: begin
					pipeline_wren	<= 4'b0100;
				end
				2'b10: begin
					pipeline_wren	<= 4'b1000;
				end
				2'b11: begin
					pipeline_wren	<= 4'b0001;
				end
				default: begin
					pipeline_wren	<= 4'b0001;
				end
			endcase

			bufferID	<= bufferID + 1;
		end
		
		// Pipeline is moving
		// if data is ready (we have kernel_size rows)
		// && has waited for at least pixels_needed_before_proc cycles
		// (need to set valid high 1 cycle before the valid output)
		// && image is not done
		if (	 (ready_rows == kernel_size)
			 && (		row_cnt >= pixels_needed_before_proc - 1
					&&	row_cnt != row_pipeline_depth - 1)
			 && (img_done == 0))
		begin
			valid <= 1'b1;
		end
		else begin
			valid <= 1'b0;
		end	
		
		// The crossbar depends on the currently active pipelines
		case (bufferID)
			2'b00: begin
				data_vec[0]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[2][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[3][row_pipeline_depth-1];
			end
			2'b01: begin
				data_vec[0]		<= pipeline[2][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[3][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[0][row_pipeline_depth-1];
			end
			2'b10: begin
				data_vec[0]		<= pipeline[3][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[1][row_pipeline_depth-1];
			end
			2'b11: begin
				data_vec[0]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[2][row_pipeline_depth-1];
			end
			default: begin
				data_vec[0]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[2][row_pipeline_depth-1];
			end
		endcase	
	end
	else begin
		// Input not valid, stall the pipeline
		valid <= 1'b0;
	end
end

genvar i;
genvar j;
generate
	// The input of the pipelines
	for (i = 0; i < 4; i = i + 1) begin: a
		always @(posedge clk) begin
			if (reset) begin
				pipeline[i][0] <= 8'b0;
			end
			else if (pipeline_rotate) begin
				if (pipeline_wren[i]) begin
					// Write data into the buffer pipeline
					// (i.e. the only enabled pipeline)
					pipeline[i][0]	<= i_data;
				end
				else begin
					// Circular pipeline
					pipeline[i][0]	<= pipeline[i][row_pipeline_depth-1];
				end
			//else stall the pipeline, do nothing
			end
		end
	end
	
	// Pipeline
	for (i = 0; i < 4; i = i + 1) begin: b
		for (j = 1; j < row_pipeline_depth; j = j + 1) begin: c
			always @(posedge clk) begin
				if (reset) begin
					pipeline[i][j] <= 8'b0;
				end
				else if (pipeline_rotate) begin
					pipeline[i][j]	<= pipeline[i][j-1];
				end
				// else stall the pipeline, do nothing
			end
		end
	end

endgenerate

convolution conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(valid),
	.i_done(img_done),
	
	.i_data(data_vec),
	
	.o_valid(conv_o_valid),
	.o_img_done(conv_o_done),
	.o_data(conv_o_data)
);

always @(posedge clk) begin
	if (reset) begin
		result					<= 8'd0;
		o_valid_pipeline[0]	<= 1'b0;
		o_done_pipeline[0]	<= 1'b0;
	end
	else begin
		// Pass the signals
		o_valid_pipeline[0]	<= conv_o_valid;
		o_done_pipeline[0]	<= conv_o_done;
	
		// Truncation
		if (conv_o_data > 255) begin
			result	<= 8'd255;
		end
		else if (conv_o_data < 0) begin
			result	<= 8'd0;
		end
		else begin
			result	<= conv_o_data;
		end
	end
end

generate
	// Post processing
	for (i = 1; i < cycles_post_proc; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else begin
				o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
				o_done_pipeline[i]	<= o_done_pipeline[i-1];
			end
		end
	end
endgenerate


assign	o_done	= o_done_pipeline[cycles_post_proc - 1];
assign	o_valid	= o_valid_pipeline[cycles_post_proc - 1];
assign	o_data	= result;


endmodule
















module filter_le
(
	input 	clk,
	input 	reset,
	input		pipeline_rotate,
	output	o_valid,
	output	o_done,
	
	input		unsigned [7:0]	i_data,
	output	unsigned	[7:0]	o_data
);

parameter	img_width	= 320;
parameter	img_height	= 240;

parameter	row_pipeline_depth = img_width + 2;
parameter	kernel_size	= 3;

// For odd x odd kernels, need (kernel_size-1)/2 rows
// of 0's before and after the actual image.
// e.g. 3x3 kernel needs 1 row.
localparam	rows_needed_before_proc = (kernel_size - 1)/2;

// For odd x odd kernels, need kernel_size-1 cycles
// before a row can be processed.
// e.g. 3x3 kernel needs 2 cycles to get the boundary 0 to
// the 2nd to last stage, and the next cycle performs a valid
// result.
localparam	pixels_needed_before_proc = kernel_size - 1;

// Cycles needed for post processing, (e.g. factor, bias, truncation etc.)
localparam	cycles_post_proc	= 1;


// number of data ready rows, data is valid when ready_rows == kernel_size
reg	[6:0]	ready_rows;
reg			valid;
reg			img_done;

reg	unsigned	[7:0]	data_vec	[kernel_size - 1 : 0];

// Pipeline registers
// 4 circular pipeline for 3x3 kernels
// Each pipeline should contain a entire row + a '0'
// at the beginning
reg	[7:0]	pipeline	[3:0]	[row_pipeline_depth - 1 : 0];
reg	[3:0]	pipeline_wren;



// Row counter
reg	[12:0] row_cnt;

// Regs to detect whether an image is done
// NOTE: this is NOT img_height
reg	[12:0] rows_done;

// The ID of the "idle" pipeline that's used
// as current data buffer. The upper level module
// determines if the output is valid
reg	[1:0]	bufferID;


// Post processing
//	The output need to be in the range 0 - 255
wire			conv_o_valid;

wire			conv_o_done;
reg			o_valid_pipeline	[cycles_post_proc - 1 : 0];
reg			o_done_pipeline	[cycles_post_proc - 1 : 0];


wire	signed	[34:0]	conv_o_data;
reg				[7:0]		result;


always @(posedge clk) begin
	if (reset) begin
		valid				<= 1'b0;
		ready_rows		<= 'b0;
		bufferID			<= 1'b0;
		row_cnt			<= 'b0;
		pipeline_wren	<= 4'b0001;
		rows_done		<= 'b0;
		img_done			<= 1'b0;
	end
	else if (pipeline_rotate) begin
		// pipeline[bufferID][0] will be filled with i_data
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
			
			if (rows_done < img_height + 2*rows_needed_before_proc) begin
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
			
			// The pipeline that just got filled shouldn't be
			// written to, enable the next pipeline.
			//
			//	At the end of the pipelines, there's a crossbar
			// that feeds the filter.
			// TODO: Could use generate, make sure quartus
			// knows this is a mux...
			case (bufferID)
				2'b00: begin
					pipeline_wren	<= 4'b0010;
				end
				2'b01: begin
					pipeline_wren	<= 4'b0100;
				end
				2'b10: begin
					pipeline_wren	<= 4'b1000;
				end
				2'b11: begin
					pipeline_wren	<= 4'b0001;
				end
				default: begin
					pipeline_wren	<= 4'b0001;
				end
			endcase

			bufferID	<= bufferID + 1;
		end
		
		// Pipeline is moving
		// if data is ready (we have kernel_size rows)
		// && has waited for at least pixels_needed_before_proc cycles
		// (need to set valid high 1 cycle before the valid output)
		// && image is not done
		if (	 (ready_rows == kernel_size)
			 && (		row_cnt >= pixels_needed_before_proc - 1
					&&	row_cnt != row_pipeline_depth - 1)
			 && (img_done == 0))
		begin
			valid <= 1'b1;
		end
		else begin
			valid <= 1'b0;
		end	
		
		// The crossbar depends on the currently active pipelines
		case (bufferID)
			2'b00: begin
				data_vec[0]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[2][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[3][row_pipeline_depth-1];
			end
			2'b01: begin
				data_vec[0]		<= pipeline[2][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[3][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[0][row_pipeline_depth-1];
			end
			2'b10: begin
				data_vec[0]		<= pipeline[3][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[1][row_pipeline_depth-1];
			end
			2'b11: begin
				data_vec[0]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[2][row_pipeline_depth-1];
			end
			default: begin
				data_vec[0]		<= pipeline[0][row_pipeline_depth-1];
				data_vec[1]		<= pipeline[1][row_pipeline_depth-1];
				data_vec[2]		<= pipeline[2][row_pipeline_depth-1];
			end
		endcase	
	end
	else begin
		// Input not valid, stall the pipeline
		valid <= 1'b0;
	end
end

genvar i;
genvar j;
generate
	// The input of the pipelines
	for (i = 0; i < 4; i = i + 1) begin: a
		always @(posedge clk) begin
			if (reset) begin
				pipeline[i][0] <= 8'b0;
			end
			else if (pipeline_rotate) begin
				if (pipeline_wren[i]) begin
					// Write data into the buffer pipeline
					// (i.e. the only enabled pipeline)
					pipeline[i][0]	<= i_data;
				end
				else begin
					// Circular pipeline
					pipeline[i][0]	<= pipeline[i][row_pipeline_depth-1];
				end
			//else stall the pipeline, do nothing
			end
		end
	end
	
	// Pipeline
	for (i = 0; i < 4; i = i + 1) begin: b
		for (j = 1; j < row_pipeline_depth; j = j + 1) begin: c
			always @(posedge clk) begin
				if (reset) begin
					pipeline[i][j] <= 8'b0;
				end
				else if (pipeline_rotate) begin
					pipeline[i][j]	<= pipeline[i][j-1];
				end
				// else stall the pipeline, do nothing
			end
		end
	end

endgenerate

convolution conv
(
	.clk(clk),
	.reset(reset),
	.i_valid(valid),
	.i_done(img_done),
	
	.i_data(data_vec),
	
	.o_valid(conv_o_valid),
	.o_img_done(conv_o_done),
	.o_data(conv_o_data)
);

always @(posedge clk) begin
	if (reset) begin
		result					<= 8'd0;
		o_valid_pipeline[0]	<= 1'b0;
		o_done_pipeline[0]	<= 1'b0;
	end
	else begin
		// Pass the signals
		o_valid_pipeline[0]	<= conv_o_valid;
		o_done_pipeline[0]	<= conv_o_done;
	
		// Truncation
		if (conv_o_data > 255) begin
			result	<= 8'd255;
		end
		else if (conv_o_data < 0) begin
			result	<= 8'd0;
		end
		else begin
			result	<= conv_o_data;
		end
	end
end

generate
	// Post processing
	for (i = 1; i < cycles_post_proc; i = i + 1) begin: d
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else begin
				o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
				o_done_pipeline[i]	<= o_done_pipeline[i-1];
			end
		end
	end
endgenerate


assign	o_done	= o_done_pipeline[cycles_post_proc - 1];
assign	o_valid	= o_valid_pipeline[cycles_post_proc - 1];
assign	o_data	= result;


endmodule
