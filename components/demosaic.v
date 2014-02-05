
module abs_diff
(
	input							clk,
	input							reset,
	input	signed	[17:0]	a, b,
	input							iValid,
	
	output						oValid,
	output signed	[17:0]	oRes
);
// At least a 2 stage stage pipeline

// Delay must be at least one
parameter	delay = 1;

reg signed	[17:0]	a_minus_b, b_minus_a;
reg signed	[17:0]	res		[delay-1:0];

reg						r_iValid;
reg						moValid	[delay:0];

genvar i;
generate
	for (i = 0; i < delay; i = i + 1) begin: absdiff
		always @(posedge clk) begin
			if (reset) begin
				res[i]		<= 'b0;
				moValid[i]	<= 0;
			end
			else if (iValid) begin
				if (i > 0) begin
					res[i]		<= res[i-1];
					moValid[i]	<= moValid[i-1];
				end
				else begin
					res[i]		<= (a_minus_b[17] == 0) ? a_minus_b : b_minus_a;
					moValid[i]	<= r_iValid;
				end
			end
		end
	end
endgenerate

always @ (posedge clk) begin
	if (reset) begin
		a_minus_b	<= 'b0;
		b_minus_a	<= 'b0;
		r_iValid		<= 0;
	end
	else if (iValid) begin
		a_minus_b	<= a - b;
		b_minus_a	<= b - a;
		r_iValid		<= iValid;
	end
end

assign	oRes		= res[delay-1];
assign	oValid	= moValid[delay-1];

endmodule


module demosaic_acpi_ginter
(
	input					clk,
	input		[7:0]		iData,
	input					reset,
	input					iValid,
	
	output	[7:0]		oR, oG, oB,
	output	[31:0]	xCnt, yCnt, demosaicCnt,
	output	[31:0]	oF,
	output				oValid,
	output				oDone
);

wire	unsigned	[7:0]	tap	[2:0];
reg	unsigned	[7:0]	rf	[2:0][2:0];

reg	unsigned	[8:0]	moR;
reg	unsigned	[8:0]	moG;
reg	unsigned	[8:0]	moB;
reg						moValid;
reg						moDone;

// Delayed signals
reg				r_moValid	[5:0];
reg				r_moDone		[5:0];

// Pixel counter
reg	[31:0]	cnt, x, y;

// Delayed x and y for the RF
reg	[31:0]	r_x			[5:0];
reg	[31:0]	r_y			[5:0];
reg	[31:0]	r_cnt			[5:0];

assign	xCnt			= r_x[5];
assign	yCnt			= r_y[5];
assign	demosaicCnt = r_cnt[5];

// Cached center pixel data
reg	[7:0]		r_rf_center	[3:0];

// Calculate grey level difference to get threshold T
reg	[31:0]	f;
reg	[8:0]		greyDiff;

assign	oR			=	moR[7:0];
assign	oG			=	moG[7:0];
assign	oB			=	moB[7:0];
assign	oF			=	f;
assign	oValid	=	r_moValid[5] & iValid;
assign	oDone		=	r_moDone[5] & iValid;

// 2 extra buffer rows
// Depth is width
demosaic_acpi_G_interploation_240p g_interploation_buffer(
	.clock(clk),
	.clken(iValid),
	.shiftin(iData),
	.shiftout(),
	.taps0x(),
	.taps1x(),
	.taps2x(tap[0]),
	.taps3x(tap[1]),
	.taps4x(tap[2])
);

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;

// TODO: Figure this out later
// Need to buffer boundaryWidth-1 empty and 2 full rows before intrapolation
localparam	totalCycles	= width*(height+2+boundaryWidth-1);


// Gradients
wire	[7:0]		h, v;

// Result selection
reg	[8:0]		gV		[2:0];
reg	[8:0]		gH		[2:0];
reg	[8:0]		gHV;
reg	[7:0]		gRes;

reg	[7:0]		hDiff_a, hDiff_b;
reg	[7:0]		vDiff_a, vDiff_b;

always @(posedge clk) begin
	if (reset) begin
		hDiff_a	<= 'b0;
		hDiff_b	<= 'b0;
		vDiff_a	<= 'b0;
		vDiff_b	<= 'b0;
	end
	else if (iValid) begin
		hDiff_a	<= (r_x[1] == 0) ? 0 : rf[1][2];
		hDiff_b	<= (r_x[1] == width - 1) ? 0 : rf[1][0];
		vDiff_a	<= (r_y[1] == 0) ? 0 : rf[2][1];
		vDiff_b	<= (r_y[1] == height - 1) ? 0 : rf[0][1];
	end
end

abs_diff #(.delay(1))
h_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, hDiff_a}),
	.b({10'b0, hDiff_b}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(h)
);

abs_diff #(.delay(1))
v_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, vDiff_a}),
	.b({10'b0, vDiff_b}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(v)
);

genvar i;
integer j;
generate
	// 3x3 Register file
	for (i = 0; i < 3; i = i + 1) begin: rf_a
		always @(posedge clk) begin
			for (j = 0; j < 3; j = j + 1) begin: rf_b
				if (reset) begin
					rf[i][j]	<= 'b0;
				end
				else if (iValid) begin
					if (j > 0) begin
						rf[i][j]	<= rf[i][j-1];
					end
					else begin
						rf[i][0] <= tap[i];
					end
				end
			end
		end
	end
	
	// Delay line of pixel counters and signals
	// It takes 2 cycles for a pixel to get to the
	// center of the RF.
	// After that, it takes another 4 cycles to calculate
	// the green interpolation results.
	for (i = 0; i < 6; i = i + 1) begin: delayLine
		always @(posedge clk) begin
			if (reset) begin
				r_x[i]			<= 'b0;
				r_y[i]			<= 'b0;
				r_cnt[i]			<= 'b0;
				r_moValid[i]	<= 'b0;
				r_moDone[i]		<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					r_x[i]			<= r_x[i-1];
					r_y[i]			<= r_y[i-1];
					r_cnt[i]			<=	r_cnt[i-1];
					r_moValid[i]	<= r_moValid[i-1];
					r_moDone[i]		<= r_moDone[i-1];
				end
				else begin
					r_x[i]			<= x;
					r_y[i]			<= y;
					r_cnt[i]			<= cnt;
					r_moValid[i]	<= moValid;
					r_moDone[i]		<= moDone;
				end
			end
		end
	end
	
	// Cached center pixel data
	for (i = 0; i < 4; i = i + 1) begin: rfcenter
		always @(posedge clk) begin
			if (reset) begin
				r_rf_center[i]	<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					r_rf_center[i]	<= r_rf_center[i-1];
				end
				else begin
					r_rf_center[i]	<= rf[1][1];
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
		gV[0]		<= 'b0;
		gV[1]		<= 'b0;
		gV[2]		<= 'b0;
		gH[0]		<= 'b0;
		gH[1]		<= 'b0;
		gH[2]		<= 'b0;
		gHV		<= 'b0;
		gRes		<= 'b0;
		f			<= 'b0;
		greyDiff	<= 'b0;
	end
	else if (iValid) begin
		if (cnt <= totalCycles) begin
			cnt	<= cnt + 1;
		end
		else begin
			cnt	<= 0;
		end
		
		moDone	<= (cnt == totalCycles - 1) ? 1'b1 : 1'b0;
		
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
			
			if (cnt < totalCycles) begin	
				// Outputs valid
				moValid	<= 1;
			end
			else begin
				moValid	<= 0;
			end
		end
		else begin
			// Haven't filled the fifo yet
			moValid	<= 0;
		end

		// Cycle 1
		if (r_y[1] == 0) begin
			// First row
			gV[0] <= rf[0][1];
		end
		else if (r_y[1] == height - 1) begin
			// Last row
			gV[0]	<= rf[2][1];
		end
		else begin
			gV[0]	<= (rf[0][1] + rf[2][1]) >> 1;
		end
		
		if (r_x[1] == 0) begin
			// First column
			gH[0]	<= rf[1][0];
		end
		else if (r_x[1] == width - 1) begin
			// Last column
			gH[0]	<= rf[1][2];
		end
		else begin
			gH[0]	<= (rf[1][0] + rf[1][2]) >> 1;
		end
		
		// Cycle 2
		gH[1]	<= gH[0];
		gH[2]	<= gH[1];
		gV[1]	<= gV[0];
		gV[2]	<= gV[1];
		
		// Cycle 3
		gHV	<= (gH[1] + gV[1]) >> 1;
		
		// Cycle 4
		if (h > v) begin
			gRes	<= gV[2][7:0];
		end
		else if (h < v) begin
			gRes	<= gH[2][7:0];
		end
		else begin
			gRes	<= gHV[7:0];
		end
		
		greyDiff	<= h + v;
		
		// Calculate f
		case ({r_y[4][0], r_x[4][0]})
			2'b01, 2'b10: begin
				f	<= f + greyDiff;
			end
			default:	begin
			end
		endcase
		
		case ({r_y[5][0], r_x[5][0]})
			2'b00, 2'b11: begin
				// G at center, no need to interpolate
				moR	<=	'b0;
				moG	<=	r_rf_center[3];
				moB	<=	'b0;
			end
			2'b01: begin
				//	R	G	R
				//	G	B	G
				//	R	G	R
				moR	<=	'b0;
				moG	<=	gRes;
				moB	<=	r_rf_center[3];
			end
			2'b10: begin
				//	B	G	B
				//	G	R	G
				//	B	G	B
				moR	<=	r_rf_center[3];
				moG	<=	gRes;
				moB	<=	'b0;
			end
		endcase
	end
end

endmodule


module demosaic_acpi_RBinter
(
	input					clk,
	input		[23:0]	iData,
	input					reset,
	input					iValid,
	input					gInteriValid,
	input		[7:0]		T,
	
	output	[7:0]		oR, oG, oB,
	output	[31:0]	xCnt, yCnt, demosaicCnt,
	output				oValid,
	output				oDone
);

localparam	pipelineDepth = 6;

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;


// TODO: up to this point, only 2 Bytes are meaningful,
// 		one is green and the other is either red or blue.
//			Could use 16 bits and save some area
//	{8'b R, 8'b G, 8'b B}
wire	unsigned	[23:0]	tap	[2:0];
reg	unsigned	[23:0]	rf		[2:0][2:0];

reg	unsigned	[8:0]		moR;
reg	unsigned	[8:0]		moG;
reg	unsigned	[8:0]		moB;
reg							moValid;
reg							moDone;

// Delayed signals
reg				r_moValid	[5:0];
reg				r_moDone		[5:0];

// Pixel counter
reg	[31:0]	cnt, x, y;

// Delayed x and y for the RF
reg	[31:0]	r_x			[5:0];
reg	[31:0]	r_y			[5:0];
reg	[31:0]	r_cnt			[5:0];

assign	xCnt			= r_x[5];
assign	yCnt			= r_y[5];
assign	demosaicCnt = r_cnt[5];

assign	oR			=	moR[7:0];
assign	oG			=	moG[7:0];
assign	oB			=	moB[7:0];
assign	oValid	=	r_moValid[5] & iValid;
assign	oDone		=	r_moDone[5] & iValid;

// Depth is width
demosaic_acpi_RB_interploation_240p rb_interploation_buffer(
	.aclr(reset)
	.clock(clk),
	.clken(iValid),
	.shiftin(iData),
	.shiftout(),
	.taps0x(),
	.taps1x(),
	.taps2x(tap[0]),
	.taps3x(tap[1]),
	.taps4x(tap[2])
);


// TODO: Figure this out later
// Need to buffer boundaryWidth-1 empty and 2 full rows before intrapolation
localparam	totalCycles	= width*(height+2+boundaryWidth-1);

// Gradients
wire	[7:0]		n, p;

// Edge detection
reg	[7:0]		g_h;
reg	[7:0]		g_v;
reg	[7:0]		g_d19;
reg	[7:0]		g_d37;

// Cached pixel data
reg	unsigned	[23:0]	r_rf [2:0][2:0];

always @(posedge clk) begin
	if (reset) begin
		r_rf[0][0]	<= 'b0;
		r_rf[0][1]	<= 'b0;
		r_rf[0][2]	<= 'b0;
		r_rf[1][0]	<= 'b0;
		r_rf[1][1]	<= 'b0;
		r_rf[1][2]	<= 'b0;
		r_rf[2][0]	<= 'b0;
		r_rf[2][1]	<= 'b0;
		r_rf[2][2]	<= 'b0;
	end
	else if (iValid) begin		
		if (r_x[1] == 0) begin
			// First column
			if (r_y[1] == 0) begin
				// First row
				r_rf[0][0]	<= rf[0][0];
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= 'b0;
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= 'b0;
				r_rf[2][0]	<= 'b0;
				r_rf[2][1]	<= 'b0;
				r_rf[2][2]	<= 'b0;
			end
			else if (r_y[1] == height - 1) begin
				// Last row
				r_rf[0][0]	<= 'b0;
				r_rf[0][1]	<= 'b0;
				r_rf[0][2]	<= 'b0;
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= 'b0;
				r_rf[2][0]	<= rf[2][0];
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= 'b0;
			end
			else begin
				r_rf[0][0]	<= rf[0][0];
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= 'b0;
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= 'b0;
				r_rf[2][0]	<= rf[2][0];
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= 'b0;
			end
		else if (r_x[1] == width - 1) begin
			// Last column
			if (r_y[1] == 0) begin
				// First row
				r_rf[0][0]	<= 'b0;
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= rf[0][2];
				r_rf[1][0]	<= 'b0;
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= 'b0;
				r_rf[2][1]	<= 'b0;
				r_rf[2][2]	<= 'b0;
			end
			else if (r_y[1] == height - 1) begin
				// Last row
				r_rf[0][0]	<= 'b0;
				r_rf[0][1]	<= 'b0;
				r_rf[0][2]	<= 'b0;
				r_rf[1][0]	<= 'b0;
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= 'b0;
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= rf[2][2];
			end
			else begin
				r_rf[0][0]	<= 'b0;
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= rf[0][2];
				r_rf[1][0]	<= 'b0;
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= 'b0;
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= rf[2][2];
			end
		else begin
			if (r_y[1] == 0) begin
				// First row
				r_rf[0][0]	<= rf[0][0];
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= rf[0][2];
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= 'b0;
				r_rf[2][1]	<= 'b0;
				r_rf[2][2]	<= 'b0;
			end
			else if (r_y[1] == height - 1) begin
				// Last row
				r_rf[0][0]	<= 'b0;
				r_rf[0][1]	<= 'b0;
				r_rf[0][2]	<= 'b0;
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= rf[2][0];
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= rf[2][2];
			end
			else begin
				r_rf[0][0]	<= rf[0][0];
				r_rf[0][1]	<= rf[0][1];
				r_rf[0][2]	<= rf[0][2];
				r_rf[1][0]	<= rf[1][0];
				r_rf[1][1]	<= rf[1][1];
				r_rf[1][2]	<= rf[1][2];
				r_rf[2][0]	<= rf[2][0];
				r_rf[2][1]	<= rf[2][1];
				r_rf[2][2]	<= rf[2][2];
			end
		end
	end
end

abs_diff #(.delay(1))
h_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, r_rf[1][0][15:8]}),
	.b({10'b0, r_rf[1][2][15:8]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(g_h)
);

abs_diff #(.delay(1))
v_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, r_rf[0][1][15:8]}),
	.b({10'b0, r_rf[2][1][15:8]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(g_v)
);

abs_diff #(.delay(1))
d19_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, r_rf[0][0][15:8]}),
	.b({10'b0, r_rf[2][2][15:8]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(g_d19)
);

abs_diff #(.delay(1))
d37_diff
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, r_rf[0][2][15:8]}),
	.b({10'b0, r_rf[2][0][15:8]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(g_d37)
);

reg	edgeRes [4:0];

always @(posedge clk) begin
	if (reset) begin
		edgeRes	<= 'b0;
	end
	else if (iValid) begin
		edgeRes	<= {(g_h > T), (g_v > T), (g_d19 > T), (g_d37 > T), (g_d19 > g_d37)}
	end
end

// Add and right shift by 1. Calculate R, G and B
reg	[23:0]	rgb28rs1;
reg	[23:0]	rgb46rs1;
reg	[23:0]	rgb19rs1;
reg	[23:0]	rgb37rs1;

genvar i;
integer j;
generate
	// 3x3 Register file
	for (i = 0; i < 3; i = i + 1) begin: rf_a
		always @(posedge clk) begin
			for (j = 0; j < 3; j = j + 1) begin: rf_b
				if (reset) begin
					rf[i][j]	<= 'b0;
				end
				else if (iValid) begin
					if (j > 0) begin
						rf[i][j]	<= rf[i][j-1];
					end
					else begin
						rf[i][0] <= tap[i];
					end
				end
			end
		end
	end
	
	// Calculate bilinear in all directions
	for (i = 0; i < 3; i = i + 1) begin: sum_a
		always @(posedge clk) begin
			if (reset) begin
				rgb28rs1		<= 'b0;
				rgb46rs1		<= 'b0;
				rgb19rs1		<= 'b0;
				rgb37rs1		<= 'b0;
			end
			else if (iValid) begin
				rgb28rs1[i*8+7:i*8]	<= (r_rf[0][1][i*8+7:i*8] + r_rf[2][1][i*8+7:i*8]) >> 1;
				rgb46rs1[i*8+7:i*8]	<= (r_rf[1][0][i*8+7:i*8] + r_rf[1][2][i*8+7:i*8]) >> 1;
				rgb19rs1[i*8+7:i*8]	<= (r_rf[0][0][i*8+7:i*8] + r_rf[2][2][i*8+7:i*8]) >> 1;
				rgb37rs1[i*8+7:i*8]	<= (r_rf[2][0][i*8+7:i*8] + r_rf[0][2][i*8+7:i*8]) >> 1;
			end
		end
	end
	
	// Delay line of pixel counters and signals
	// It takes 2 cycles for a pixel to get to the
	// center of the RF.
	// After that, it takes another 4 cycles to calculate
	// the green interpolation results.
	for (i = 0; i < 6; i = i + 1) begin: delayLine
		always @(posedge clk) begin
			if (reset) begin
				r_x[i]			<= 'b0;
				r_y[i]			<= 'b0;
				r_cnt[i]			<= 'b0;
				r_moValid[i]	<= 'b0;
				r_moDone[i]		<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					r_x[i]			<= r_x[i-1];
					r_y[i]			<= r_y[i-1];
					r_cnt[i]			<=	r_cnt[i-1];
					r_moValid[i]	<= r_moValid[i-1];
					r_moDone[i]		<= r_moDone[i-1];
				end
				else begin
					r_x[i]			<= x;
					r_y[i]			<= y;
					r_cnt[i]			<= cnt;
					r_moValid[i]	<= moValid;
					r_moDone[i]		<= moDone;
				end
			end
		end
	end
	
	// Cached center pixel data
	for (i = 0; i < 4; i = i + 1) begin: rfcenter
		always @(posedge clk) begin
			if (reset) begin
				r_rf_center[i]	<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					r_rf_center[i]	<= r_rf_center[i-1];
				end
				else begin
					r_rf_center[i]	<= rf[1][1];
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
		gV[0]		<= 'b0;
		gV[1]		<= 'b0;
		gV[2]		<= 'b0;
		gH[0]		<= 'b0;
		gH[1]		<= 'b0;
		gH[2]		<= 'b0;
		gHV		<= 'b0;
		gRes		<= 'b0;
		f			<= 'b0;
		greyDiff	<= 'b0;
	end
	else if (iValid) begin
		if (cnt <= totalCycles) begin
			cnt	<= cnt + 1;
		end
		else begin
			cnt	<= 0;
		end
		
		moDone	<= (cnt == totalCycles - 1) ? 1'b1 : 1'b0;
		
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
			
			if (cnt < totalCycles) begin	
				// Outputs valid
				moValid	<= 1;
			end
			else begin
				moValid	<= 0;
			end
		end
		else begin
			// Haven't filled the fifo yet
			moValid	<= 0;
		end

		// Cycle 1
		if (r_y[1] == 0) begin
			// First row
			gV[0] <= rf[0][1];
		end
		else if (r_y[1] == height - 1) begin
			// Last row
			gV[0]	<= rf[2][1];
		end
		else begin
			gV[0]	<= (rf[0][1] + rf[2][1]) >> 1;
		end
		
		if (r_x[1] == 0) begin
			// First column
			gH[0]	<= rf[1][0];
		end
		else if (r_x[1] == width - 1) begin
			// Last column
			gH[0]	<= rf[1][2];
		end
		else begin
			gH[0]	<= (rf[1][0] + rf[1][2]) >> 1;
		end
		
		// Cycle 2
		gH[1]	<= gH[0];
		gH[2]	<= gH[1];
		gV[1]	<= gV[0];
		gV[2]	<= gV[1];
		
		// Cycle 3
		gHV	<= (gH[1] + gV[1]) >> 1;
		
		// Cycle 4
		if (h > v) begin
			gRes	<= gV[2][7:0];
		end
		else if (h < v) begin
			gRes	<= gH[2][7:0];
		end
		else begin
			gRes	<= gHV[7:0];
		end
		
		greyDiff	<= h + v;
		
		// Calculate f
		case ({r_y[4][0], r_x[4][0]})
			2'b01, 2'b10: begin
				f	<= f + greyDiff;
			end
			default:	begin
			end
		endcase
		
		case ({r_y[5][0], r_x[5][0]})
			2'b00, 2'b11: begin
				// G at center, no need to interpolate
				moR	<=	'b0;
				moG	<=	r_rf_center[3];
				moB	<=	'b0;
			end
			2'b01: begin
				//	R	G	R
				//	G	B	G
				//	R	G	R
				moR	<=	'b0;
				moG	<=	gRes;
				moB	<=	r_rf_center[3];
			end
			2'b10: begin
				//	B	G	B
				//	G	R	G
				//	B	G	B
				moR	<=	r_rf_center[3];
				moG	<=	gRes;
				moB	<=	'b0;
			end
		endcase
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
	output	[7:0]		oT,
	output				oValid,
	output				oDone
);

parameter	width				= 1920;
parameter	height			= 1080;
parameter	kernelSize		= 7;
localparam	boundaryWidth	= (kernelSize-1)/2;

wire	[31:0]	f;
reg	[7:0]		T;
wire				oGinterDone;

demosaic_acpi_ginter #(.width(width), .height(height), .kernelSize(kernelSize))
ginter
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
	.oF(f),
	.oValid(oValid),
	.oDone(oGinterDone)
);

always @(posedge clk) begin
	if (reset) begin
		T		<= 'b0;
	end
	else begin
		if (oGinterDone) begin
			if (f < 73242) begin
				T	<= 'd50;
			end
			else if (f < 102539) begin
				T	<= 'd40;
			end
			else if (f < 146484) begin
				T	<= 'd20;
			end
			else if (f < 292965) begin
				T	<= 'd15;
			end
			else begin
				T	<= 'd8;
			end
		end
	end
end

assign oT = T;

reg	moDone;

always @(posedge clk) begin
	if (reset) begin
		moDone	<= 0;
	end
	else begin
		moDone	<= oGinterDone;
	end
end	

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
