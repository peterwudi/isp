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

logic					reset_n;

logic		[31:0]	iData;
logic					sCCD_DVAL;
	
logic		[31:0]	Read_DATA;

logic 				vpg_pclk;
logic 				vpg_de;
logic					vpg_hs;
logic					vpg_vs;
logic		[23:0]	vpg_data;

logic					read_empty_rdfifo;
logic					write_full_wrfifo;
logic		[8:0]		write_fifo_wrusedw;
logic		[8:0]		write_fifo_rdusedw;
logic		[8:0]		read_fifo_wrusedw;
logic		[8:0]		read_fifo_rdusedw;

bus dut ( .* );

initial	GPIO1_PIXLCLK = '1;
initial	ctrl_clk = '1;
initial	OSC2_50 = '1;
always begin
	#20		GPIO1_PIXLCLK = ~GPIO1_PIXLCLK;  	// 25MHz d5m clock
end
always begin
	#5		ctrl_clk = ~ctrl_clk;		// 100MHz ctrl clock
end
always begin
	#10		OSC2_50 = ~OSC2_50;		// 50MHz ref clock
end


initial begin
	iData = 'd0;
	sCCD_DVAL = 0;
	
	@(negedge GPIO1_PIXLCLK);
	reset_n = 1'b0;
	@(negedge GPIO1_PIXLCLK);

	reset_n = 1'b1;
	for (int i = 1; i < 17; i++) begin
		@(negedge GPIO1_PIXLCLK);
	end

	sCCD_DVAL = 1'b1;
	for (int i = 1; i < 641; i++) begin
		iData = i;
		@(negedge GPIO1_PIXLCLK);
	end
	
	sCCD_DVAL = 0;
	@(negedge GPIO1_PIXLCLK);
	
	for (int i = 0; i < 600; i++) begin
		@(negedge vpg_pclk);
	end
	
	@(negedge GPIO1_PIXLCLK);
	reset_n = 1'b1;

	$stop(0);
end



endmodule
