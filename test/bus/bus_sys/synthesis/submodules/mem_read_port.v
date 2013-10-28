
// Master read component
module mem_read_buffer_avalon_interface
(
	input					clk,
	input					reset,
	
	// Control inputs and outputs
	input		[19:0]	read_addr,
	input					read,
	output	[31:0]	oData,
	output				waitrequest,
	
	// Avalon-MM master signals
	output	[19:0]	master_address,
	output				master_read,
	output	[3:0] 	master_byteenable,
	input		[31:0] 	master_readdata,
	input					master_waitrequest
);

	parameter DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 30;
//	parameter FIFODEPTH = 32;
//	parameter FIFODEPTH_LOG2 = 5;
//	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead

	// master address logic 
	assign	master_address = read_addr;
	assign	master_byteenable = 4'b1111;
	assign	master_read = read;
	
	assign	waitrequest = master_waitrequest;
	assign	oData	=	master_readdata;
	
endmodule

