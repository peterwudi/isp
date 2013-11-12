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

logic					rCCD_FVAL;
//logic					read_init;

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

always begin
	#20		GPIO1_PIXLCLK = ~GPIO1_PIXLCLK;  	// 25MHz d5m clock
end

always begin
	#5		ctrl_clk = ~ctrl_clk;		// 100MHz ctrl clock
end
always begin
	#10		OSC2_50 = ~OSC2_50;		// 50MHz ref clock
end

parameter	width = 640;
parameter	height = 480;

// Write
initial begin
	iData = 'd0;
	sCCD_DVAL = 0;
	rCCD_FVAL = 0;
	
	@(negedge OSC2_50);
	reset_n = 1'b0;
	@(negedge OSC2_50);

	reset_n = 1'b1;
	
	// give it some time, otherwise pre_rCCD_FVAL is always 1
	for (int j = 0; j < 10; j++) begin
		@(negedge GPIO1_PIXLCLK);
	end
	rCCD_FVAL = 1;
	
	// FVAL is high for say 32 cycles before DVAL
	for (int j = 0; j < 32; j++) begin
		@(negedge GPIO1_PIXLCLK);
	end
	
	for (int j = 0; j < height; j++) begin
		sCCD_DVAL = 1'b1;
		for (int i = 1; i < width+1; i++) begin
			iData = iData+1;
			@(negedge GPIO1_PIXLCLK);
		end
	
		sCCD_DVAL = 0;
		for (int i = 1; i < 40; i++) begin
			@(negedge GPIO1_PIXLCLK);
		end
		
		break;
	end
	
	sCCD_DVAL = 0;
	@(negedge GPIO1_PIXLCLK);

end

logic hs;


// Read
initial begin
	//read_init = 0;
	hs = 0;
	vpg_de = 0;
	
	// Use this to wait until gen_clk is locked.
	// In reallity there's no read_init, use vga_de,
	// which should be high after it's locked and skipped
	// the first several rows.
	for (int i = 0; i < 1550; i++) begin
		@(negedge OSC2_50);
	end
	
	// Do 1 row first
	hs = 1;
	while (1) begin
		//if (vpg_hs == 1) begin
		if (hs == 1) begin
			// vpg_de is high 48 cycles after vpg_hs
			for (int i = 0; i < 48; i++) begin
				@(negedge vpg_pclk);
			end
			vpg_de = 1;
			break;
		end
	end

	for (int i = 0; i < 640; i++) begin
		// vpg_de high for 640 cycles
		@(negedge vpg_pclk);
	end
	vpg_de = 0;
					
//	for (int j = 0; j < height; j++) begin
//		for (int i = 0; i < width; i++) begin
//			read_init = 1;
//			@(negedge vpg_pclk);
//		end
//		
//		// Wait for say 32 cycles of front/back porch etc.
//		for (int i = 0; i < 32; i++) begin
//			read_init = 0;
//			@(negedge vpg_pclk);
//		end
//	end
	
	for (int i = 0; i < 16; i++) begin
		@(negedge vpg_pclk);
	end
	
	$stop(0);
end
	




endmodule
