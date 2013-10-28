
// Master write component
module mem_write_buffer_avalon_interface (
	input					clk,
	input					reset,
	
	// Control inputs and outputs
	input		[19:0]	write_addr,
	input		[31:0]	iData,
	input					write,
	output				write_done,
	
	// Avalon-MM master signals
	output	[19:0]	master_address,
	output				master_write,
	output	[3:0] 	master_byteenable,
	output	[31:0] 	master_writedata,
	input					master_waitrequest
);
	parameter DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 30;		// 1GB
//	parameter FIFODEPTH = 32;
//	parameter FIFODEPTH_LOG2 = 5;
//	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead
	
	// controlled signals going to the master/control ports
	assign	master_address = write_addr;
	assign	master_byteenable = 4'b1111;
	assign	master_write = write;
	assign	master_writedata = iData;
	assign	write_done = (master_waitrequest == 0);
	
endmodule

