
module abs_diff
{
	input							clk,
	input	signed	[17:0]	a, b,
	input							iValid,
	
	output						oValid
	output signed	[17:0]	oRes
};

reg signed	[17:0]	a_minus_b, b_minus_a;

reg	mValid;

always @ (posedge clk) begin
	if (reset) begin
		mValid		<= 0;
		oRes			<= 'b0;
		a_minus_b	<= 'b0;
		b_minus_a	<= 'b0;
	end
	else begin
		a_minus_b	<= a - b;
		b_minus_a	<= b - a;
		mValid		<= iValid;
	end
end

assign	oRes = (a_minus_b[17] == 0) ? a_minus_b : b_minus_a;
assign	oValid = mValid;

endmodule


module demosaic_acpi_ginter
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

wire	unsigned	[7:0]	tap	[2:0];
wire	unsigned	[7:0]	selectedTap0;
reg	unsigned	[7:0]	rf	[2:0][2:0];

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
demosaic_acpi_G_interploation_240p g_interploation_buffer(
	.aclr(0),
	.clock(clk),
	.clken(iValid),
	.shiftin(iData),
	.shiftout(),
	.taps0x(tap[0]),
	.taps1x(tap[1]),
	.taps2x(tap[2])
);

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;

// TODO: Figure this out later
// Need to buffer boundaryWidth-1 empty and 2 full rows before intrapolation
localparam	totalCycles	= width*(height+2+boundaryWidth-1);


// Pixel counter
reg	[31:0]	cnt, x, y;

assign	xCnt			= x;
assign	yCnt			= y;
assign	demosaicCnt = cnt;

// Last row, set all pixel values to 0
assign	selectedTap0 = //(cnt <= width*(height+boundaryWidth)) ? tap0 : 'b0;

// 3x3 Register file
genvar i, j;
generate
	for (i = 0; i < 3; i = i + 1) begin: a
		always @(posedge clk) begin
			for (j = 0; j < 3; j = j + 1) begin: b
				if (reset) begin
					rf[i][j]	<= 'b0;
				end
				else if (iValid) begin
					rf[i][0] <= tap[i];
				end
			end
		end
	end
endgenerate

always@ (posedge clk)
begin
	if(reset)
	begin
		moR		<=	'b0;
		moG		<=	'b0;
		moB		<=	'b0;
		moValid	<=	0;
		moDone	<=	0;
		cnt		<= 'b0;
		x			<= 'b0;
		y			<= 'b0;
	end
	else if (iValid) begin
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
			2'b00, 2'b11: begin
				// G at center, no need to interpolate
				moR	<=	'b0;
				moG	<=	rf[1][1];
				moB	<=	'b0;
			end
			2'b01: begin
				//	R	G	R
				//	G	B	G
				//	R	G	R
				moR	<=	'b0;
				moG	<=	 >> 1;
				moB	<=	rf[1][1];
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






module demosaic_acpi
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

demosaic_acpi_ginter
(
	.clk(clk),
	.iData(iData),
	.reset(reset),
	.iValid(iValid),
	
	.oR(oR),
	.oG(oG),
	.oB(oB),
	.xCnt(xCnt),
	.yCnt(yCnt),
	.demosaicCnt(demosaicCnt),
	.oValid(oValid),
	.oDone(oDone)
);


endmodule


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

//demosaic_neighbor_shift_reg_240p buffer(
//	.clock(clk),
//	.clken(iValid),
//	.shiftin(iData),
//	.shiftout(),
//	.taps0x(),
//	.taps1x(),
//	.taps2x(tap0),
//	.taps3x(tap1)
//);

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;

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
