
module bus(
	input					GPIO1_PIXLCLK,
	input					ctrl_clk,
	input					vpg_pclk,
	
	input					reset_n,
	
	// Write side
	input		[31:0]	iData,
	input					sCCD_DVAL,
		
	input					read_init,
	output	[31:0]	Read_DATA,

	output				read_empty_rdfifo,
	output				write_full_wrfifo,
	
	output	[8:0]		write_fifo_wrusedw,
	output	[8:0]		write_fifo_rdusedw,
	output	[8:0]		read_fifo_wrusedw,
	output	[8:0]		read_fifo_rdusedw
);

//	Prevent from read at starting because of none data in the ddr2
reg	[15:0]write_cnt;
always@(posedge ~GPIO1_PIXLCLK)
	if (~reset_n)
		write_cnt <= 0;
	else if ( (sCCD_DVAL) & (write_cnt != 65536) )
		write_cnt <= write_cnt + 1;
			                  
reg	read_rstn;
always@(posedge ~GPIO1_PIXLCLK)
	begin
		if (~reset_n)
			read_rstn <= 0;
		else if (write_cnt == 512)
			read_rstn <= 1;
end	

ddr2_buffer u8(
	.d5m_clk(~GPIO1_PIXLCLK),
	.ctrl_clk(~GPIO1_PIXLCLK),//use pixclk for now, should use a faster one
	.dvi_clk(vpg_pclk),
	
	.reset_n(reset_n),
	.read_rstn(read_rstn),
	
	// Write side
	//.iData({2'b0,sCCD_R[11:2], sCCD_G[11:2], sCCD_B[11:2]}),
	.iData(iData),
	.iValid(sCCD_DVAL),
		
	//.read_init(vpg_de),
	.read_init(read_init),
	.oData(Read_DATA),
	// seems like this is not used, we have to generate data fast enough,
	// and only put valid data here.
	
	// Debug
	.read_empty_rdfifo(read_empty_rdfifo),
	.write_full_wrfifo(write_full_wrfifo),
	
	.write_fifo_wrusedw(write_fifo_wrusedw),
	.write_fifo_rdusedw(write_fifo_rdusedw),
	.read_fifo_wrusedw(read_fifo_wrusedw),
	.read_fifo_rdusedw(read_fifo_rdusedw)
);
	
endmodule
