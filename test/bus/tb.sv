`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();

logic					clk;
logic					reset_n;
logic		[31:0]	iData;
//logic					iValid;
	
logic					read;
logic		[18:0]	read_addr;
logic					oValid;
logic		[31:0]	oData;
logic					read_done;
	
logic					write;
logic		[18:0]	write_addr;
logic					write_done;

bus dut ( .* );

initial clk = '1;
always #2.5 clk = ~clk;  // 200 MHz clock

initial begin
	iData = 'd0;
	read = 1'b0;
	write	= 1'b0;
	
	@(negedge clk);
	reset_n = 1'b0;
	@(negedge clk);
	
	reset_n = 1'b1;
	@(negedge clk);
	
	for (int i = 4; i < 5; i++) begin
		iData = i;
		write = 1'b1;
		write_addr = i;
		
		// Waiting until write is done
		while(!write_done) begin
			@(negedge clk);
		end
		
		@(negedge clk);
		write = 1'b0;
		@(negedge clk);
		//$display("in1 = %d, data[%d] = %d", in1, i, i_r_data_arr[i]);
	end
	
	write = 1'b0;
	@(negedge clk);
	
	for (int i = 4; i < 5; i++) begin
		read = 1'b1;
		read_addr = i;
		@(negedge clk);
		
		// Wait for valid data
		while(!oValid) begin
			@(negedge clk);
		end
		
		@(negedge clk);
		read = 1'b0;
		@(negedge clk);
	end
	
	@(negedge clk);
	reset_n = 1'b1;

	$stop(0);
end




endmodule
