`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();

logic					GPIO1_PIXLCLK;
logic					ctrl_clk;
logic					vpg_pclk;
logic					reset_n;

logic		[31:0]	iData;
logic					sCCD_DVAL;
	
logic					read_init;
logic		[31:0]	Read_DATA;
//logic					oValid;

logic					read_empty_rdfifo;
logic					write_full_wrfifo;
logic		[8:0]		write_fifo_wrusedw;
logic		[8:0]		write_fifo_rdusedw;
logic		[8:0]		read_fifo_wrusedw;
logic		[8:0]		read_fifo_rdusedw;

bus dut ( .* );

initial	GPIO1_PIXLCLK = '1;
initial	ctrl_clk = '1;
initial	vpg_pclk = '1;
always begin
	#10		GPIO1_PIXLCLK = ~GPIO1_PIXLCLK;  	// 50MHz d5m clock
end
always begin
	#4		ctrl_clk = ~ctrl_clk;		// 125MHz ctrl clock
end
always begin
	#20		vpg_pclk = ~vpg_pclk;		// 25MHz dvi clock
end


initial begin
	iData = 'd0;
	read_init = 1'b0;
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
		
		if (i >= 100) begin
			read_init <= 1;
		end
		@(negedge GPIO1_PIXLCLK);
	end
	
	sCCD_DVAL = 0;
	@(negedge GPIO1_PIXLCLK);
	
	
	for (int i = 0; i < 200; i++) begin
		read_init = 1'b1;
		@(negedge vpg_pclk);
	end
	read_init = 0;
	
	@(negedge GPIO1_PIXLCLK);
	reset_n = 1'b1;

	$stop(0);
end




endmodule
