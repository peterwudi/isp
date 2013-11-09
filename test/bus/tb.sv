`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();

logic					OSC2_50;
logic					GPIO1_PIXLCLK;
logic					ctrl_clk;
//logic					dvi_clk;

logic					reset_n;
logic					wr_new_frame;
logic					rd_new_frame;

logic		[31:0]	iData;
logic					sCCD_DVAL;
	
logic		[31:0]	Read_DATA;
logic					read_init;

logic 				vpg_pclk;
logic 				vpg_de;
logic					vpg_hs;
logic					vpg_vs;
logic		[23:0]	vpg_data;

logic					read_empty_rdfifo;
logic					write_full_rdfifo;
logic					read_empty_wrfifo;
logic					write_full_wrfifo;

logic		[8:0]		write_fifo_wrusedw;
logic		[8:0]		write_fifo_rdusedw;
logic		[8:0]		read_fifo_wrusedw;
logic		[8:0]		read_fifo_rdusedw;

bus dut ( .* );

initial	GPIO1_PIXLCLK = '1;
initial	ctrl_clk = '1;
initial	OSC2_50 = '1;
//initial	dvi_clk = '1;

always begin
	#20		GPIO1_PIXLCLK = ~GPIO1_PIXLCLK;  	// 25MHz d5m clock
end
//always begin
//	#10		dvi_clk = ~dvi_clk;  	// 25MHz d5m clock
//end

always begin
	#5		ctrl_clk = ~ctrl_clk;		// 100MHz ctrl clock
end
always begin
	#10		OSC2_50 = ~OSC2_50;		// 50MHz ref clock
end

// Write
initial begin
	iData = 'd0;
	sCCD_DVAL = 0;
	wr_new_frame = 0;
	
	@(negedge OSC2_50);
	reset_n = 1'b0;
	@(negedge OSC2_50);

	reset_n = 1'b1;
	
//	for (int i = 1; i < 17; i++) begin
//		@(negedge GPIO1_PIXLCLK);
//	end
	
	sCCD_DVAL = 1'b1;
	wr_new_frame = 1;
	for (int i = 1; i < 641; i++) begin
		iData = i;
		@(negedge GPIO1_PIXLCLK);
		wr_new_frame = 0;
	end
	
	sCCD_DVAL = 0;
	@(negedge GPIO1_PIXLCLK);

end

// Read
initial begin
	read_init = 0;
	rd_new_frame = 0;
	@(negedge OSC2_50);
	@(negedge OSC2_50);
	
	
	// Use this to wait until gen_clk is locked.
	// In reallity there's no read_init, use vga_de,
	// which should be high after it's locked and skipped
	// the first several rows.
	for (int i = 0; i < 1255; i++) begin
		@(negedge OSC2_50);
	end
	
	rd_new_frame = 1;
	read_init = 1;
	// Need 1 cycles for a valid data to be read
	@(negedge vpg_pclk);
	rd_new_frame = 0;
					
	for (int j = 0; j < 20; j++) begin
		for (int i = 0; i < 32; i++) begin
			read_init = 1;
			@(negedge vpg_pclk);
			rd_new_frame = 0;
		end
		
		// Wait for say 10 cycles of front/back porch etc.
		for (int i = 0; i < 32; i++) begin
			read_init = 0;
			@(negedge vpg_pclk);
		end
	end
	
	for (int i = 0; i < 16; i++) begin
		@(negedge vpg_pclk);
	end
	
	$stop(0);
end
	




endmodule
