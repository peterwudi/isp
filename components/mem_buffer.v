
module mem_write_buffer (
	input				clk;						//	Write fifo clock (Pixel clk)
	input				reset;					//Write register load & fifo clear
	input				wr_req;					//	Write Request
	input	[11:0]	data;						//	Data input

	
	
	output							WR1_FULL;				//Write fifo full
	output	[8:0]					WR1_USE;				//Write fifo usedw
);

ddr2_fifo u0(
	.aclr(reset),
	.data(data),
	.rdclk(~clk),
	.rdreq(wr_req),
	wrclk,
	.wrreq(wr_req),
	q,
	//rdempty,
	//rdusedw,
	//wrfull,
	//wrusedw
);

endmodule



// Master write component
module mem_write_buffer_avalon_interface
(
	input			clk,
	input			reset,
	input			writedata,
	input			write,
	//input			read,
	//input		chipselect,
	
	//output		readdata
	//output		q
);

mem_write_buffer u0(
	.clk(clk),
	.reset(reset),
	.wr_req(write),
	.data(writedata),
	
	.readdata(readdata),
);

endmodule

