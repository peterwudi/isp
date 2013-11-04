`timescale 1ns/1ns

localparam	width				= 320;
localparam	height			= 240;
localparam	totalInBytes	= (width + 2) * (height + 2);

// TODO: add pading bytes if need be, not necessary for 240p
localparam	totalOutBytes	= width * height;

module tb();

logic					d5m_clk;
logic					ctrl_clk;
logic					dvi_clk;
logic					reset_n;

logic		[31:0]	iData;
logic					iValid;
	
logic					read_init;
logic		[31:0]	oData;
//logic					oValid;

logic					read_empty_rdfifo;
logic					write_full_wrfifo;
logic		[8:0]		write_fifo_wrusedw;
logic		[8:0]		write_fifo_rdusedw;
logic		[8:0]		read_fifo_wrusedw;
logic		[8:0]		read_fifo_rdusedw;

bus dut ( .* );

initial	d5m_clk = '1;
initial	ctrl_clk = '1;
initial	dvi_clk = '1;
always begin
	#10		d5m_clk = ~d5m_clk;  	// 50MHz d5m clock
end
always begin
	#4		ctrl_clk = ~ctrl_clk;		// 125MHz ctrl clock
end
always begin
	#10		dvi_clk = ~dvi_clk;		// 50MHz dvi clock
end


initial begin
	iData = 'd0;
	read_init = 1'b0;
	iValid = 0;
	
	@(negedge d5m_clk);
	reset_n = 1'b0;
	@(negedge d5m_clk);

	reset_n = 1'b1;
	for (int i = 1; i < 17; i++) begin
		@(negedge d5m_clk);
	end

	iValid = 1'b1;
	for (int i = 1; i < 641; i++) begin
		iData = i;
		
		if (i >= 100) begin
			read_init <= 1;
		end
		@(negedge d5m_clk);
	end
	
	iValid = 0;
	@(negedge d5m_clk);
	
	
	for (int i = 0; i < 200; i++) begin
		read_init = 1'b1;
		@(negedge dvi_clk);
	end
	read_init = 0;
	
	@(negedge d5m_clk);
	reset_n = 1'b1;

	$stop(0);
end




endmodule
