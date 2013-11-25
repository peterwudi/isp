
module demosaic_neighbor
(
	input					clk,
	input		[7:0]		iData,
	input					reset,
	input					iValid,
	
	output	[7:0]		oR, oG, oB,
	output	[31:0]	xCnt, yCnt, demosaicCnt,
	output				oValid,
	output				oDone
);

wire	unsigned	[7:0]	tap0;
wire	unsigned	[7:0]	selectedTap0;
wire	unsigned	[7:0]	tap1;
reg	unsigned	[8:0]	r_tap0;
reg	unsigned	[8:0]	r_tap1;
reg	unsigned	[8:0]	moR;
reg	unsigned	[8:0]	moG;
reg	unsigned	[8:0]	moB;
reg						moValid;
reg						moDone;

assign	oR			=	moR[7:0];
assign	oG			=	moG[7:0];
assign	oB			=	moB[7:0];
assign	oValid	=	moValid;
assign	oDone		=	moDone;

// 2 extra buffer rows
// Depth is width
demosaic_neighbor_shift_reg buffer(
	.clock(clk),
	.clken(iValid),
	.shiftin(iData),
	.shiftout(),
	.taps0x(),
	.taps1x(),
	.taps2x(tap0),
	.taps3x(tap1)
);

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
parameter	boundaryWidth	= (kernelSize-1)/2;

// Need to buffer boundaryWidth-1 empty and 2 full rows before intrapolation
localparam	totalCycles	= width*(height+2+boundaryWidth-1);

// Pixel counter
reg	[31:0]	cnt, x, y;

assign	xCnt			= x;
assign	yCnt			= y;
assign	demosaicCnt = cnt;

// Last row, set all pixel values to 0
assign	selectedTap0 = (cnt <= width*(height+boundaryWidth)) ? tap0 : 'b0;

always@	(posedge clk)
begin
	if(reset)
	begin
		moR		<=	0;
		moG		<=	0;
		moB		<=	0;
		r_tap0	<=	0;
		r_tap1	<=	0;
		moValid	<=	0;
		moDone	<=	0;
		cnt		<= 'b0;
		x			<= 0;
		y			<= 0;
	end
	else if (iValid) begin
		r_tap0	<=	{1'b0, selectedTap0};
		r_tap1	<=	{1'b0, tap1};
		
		if (cnt <= totalCycles) begin
			cnt	<= cnt + 1;
		end
		else begin
			cnt	<= 0;
		end
		
		moDone	<= (cnt == totalCycles - 1) ? 1:0;
		
		if (cnt >= width * (2+boundaryWidth-1)) begin
			// Only start counter after the first 4 empty rows
			if (x < width - 1) begin
				x	<= x + 1;
			end
			else begin
				x	<= 0;
				if (y < height - 1) begin
					y	<= y + 1;
				end
				else begin
					y	<= 0;
				end
			end
		end
		
		if (cnt < width*(2+boundaryWidth-1)) begin
			// Haven't filled the fifo yet
			moValid	<= 0;
		end
		else if (cnt < totalCycles) begin	
			// Outputs valid
			moValid	<= 1;
		end
		else begin
			moValid	<= 0;
		end

		case ({y[0], x[0]})
			2'b00: begin
				moR	<=	selectedTap0[7:0];
				moG	<=	(r_tap0 + tap1) >> 1;
				moB	<=	r_tap1[7:0];
			end
			2'b01: begin
				moR	<=	r_tap0[7:0];
				moG	<=	(selectedTap0 + r_tap1) >> 1;
				moB	<=	tap1[7:0];
			end
			2'b10: begin
				moR	<=	tap1[7:0];
				moG	<=	(r_tap1 + selectedTap0) >> 1;
				moB	<=	r_tap0[7:0];
			end
			2'b11: begin
				moR	<=	r_tap1[7:0];
				moG	<=	(tap1 + r_tap0) >> 1;
				moB	<=	selectedTap0[7:0];
			end
		endcase
	end
	else begin
		moValid <= 0;
	end
end

endmodule
