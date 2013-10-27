`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();

logic 						clk;
logic unsigned [31:0]	iData;
logic							iValid;
logic							reset_n;
logic							read;
logic							write;

logic							user_write_buffer;
logic							user_read_buffer;
	
logic							write_ctrl_done;
logic							read_ctrl_done;
logic							write_buffer_full;
logic							user_data_available;
logic							oValid;
logic unsigned	[31:0]	oData;

bus dut ( .* );

initial clk = '1;
always #2.5 clk = ~clk;  // 200 MHz clock

initial begin
	iData = 'd0;
	read = 1'b0;
	iValid = 1'b0;
	write	= 1'b0;
	user_write_buffer = 1'b0;
	user_read_buffer = 1'b0;
	
	@(negedge clk);
	reset_n = 1'b0;
	@(negedge clk);
	
	reset_n = 1'b1;
	@(negedge clk);
	
	for (int i = 0; i < 5; i++) begin
		iValid = 1'b1;
		iData = i;
		write = 1'b1;
		user_write_buffer = 1'b0;
		@(negedge clk);
		
		write = 1'b0;
		// Wait for write_ctrl_done
		while(!write_ctrl_done || write_buffer_full) begin
			@(negedge clk);
		end
		
		// Keep iValid high for a cycle
		@(negedge clk);
		user_write_buffer = 1'b1;
		
		//$display("in1 = %d, data[%d] = %d", in1, i, i_r_data_arr[i]);
	end
	
	iValid = 1'b0;
	write = 1'b0;
	user_write_buffer = 1'b0;
	@(negedge clk);
	
	for (int i = 0; i < 5; i++) begin
		read = 1'b1;
		user_read_buffer = 1'b0;
		@(negedge clk);
		oValid = 1'b0;
		read = 1'b0;
		
		// Wait for read_ctrl_done
		while(!read_ctrl_done) begin
			@(negedge clk);
		end
		
		// Read
		@(negedge clk);
		user_read_buffer = 1'b1;
		@(negedge clk);
		oValid = 1'b1;
	end
	@(negedge clk);
	reset_n = 1'b1;

	$stop(0);
end




endmodule
