
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
	input		[7:0]		T,
	
	output	[7:0]		oR, oG, oB,
	output	[31:0]	xCnt, yCnt, demosaicCnt,
	output				oValid,
	output				oDone
);
// Starting from x and y, i.e. the depth of r_x and r_y
localparam	pipelineDepth	= 10;

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

reg	unsigned	[7:0]		moR;
reg	unsigned	[7:0]		moG;
reg	unsigned	[7:0]		moB;
reg							moValid;
reg							moDone;

// Delayed signals
reg				r_moValid	[pipelineDepth-1:0];
reg				r_moDone		[pipelineDepth-1:0];

// Pixel counter
reg	[31:0]	cnt, x, y;

// Delayed x and y for the RF
reg	[31:0]	r_x			[pipelineDepth-1:0];
reg	[31:0]	r_y			[pipelineDepth-1:0];
reg	[31:0]	r_cnt			[pipelineDepth-1:0];

assign	xCnt			= r_x[pipelineDepth-1];
assign	yCnt			= r_y[pipelineDepth-1];
assign	demosaicCnt = r_cnt[pipelineDepth-1];

assign	oR			=	moR;
assign	oG			=	moG;
assign	oB			=	moB;
assign	oValid	=	r_moValid[pipelineDepth-1] & iValid;
assign	oDone		=	r_moDone[pipelineDepth-1] & iValid;

// Depth is width
demosaic_acpi_RB_interploation_240p rb_interploation_buffer(
	.aclr(reset),
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

// Edge detection
reg	[7:0]		g_h;
reg	[7:0]		g_v;
reg	[7:0]		g_d19;
reg	[7:0]		g_d37;

// Registered pixel data (for inserting 0's at the boundary)
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

// Edge detection result
reg	[4:0]		edgeSel;
reg				isEdge	[pipelineDepth - 9:0];

always @(posedge clk) begin
	if (reset) begin
		edgeSel	<= 'b0;
	end
	else if (iValid) begin
		// Use the last bit to select the diagnal
		edgeSel	<= {(g_h > T), (g_v > T), (g_d19 > T), (g_d37 > T), (g_d19 > g_d37)};
	end
end

// Gradients
reg	[7:0]		n1_a, n1_b, p1_a, p1_b;
wire	[7:0]		n1, p1;
wire	[8:0]		n2, p2;
reg	[9:0]		n, p;

// Select R or B
always @(posedge clk) begin
	if (reset) begin
		n1_a	<= 'b0;
		n1_b	<= 'b0;
		p1_a	<= 'b0;
		p1_b	<= 'b0;
	end
	else if (iValid) begin
		case ({r_y[2][0], r_x[2][0]})
			2'b00, 2'b11: begin
				// G at center, don't need n/p
				n1_a	<= 'b0;
				n1_b	<= 'b0;
				p1_a	<= 'b0;
				p1_b	<= 'b0;
			end
			2'b01: begin
				//	R	G	R
				//	G	B	G
				//	R	G	R
				n1_a	<= r_rf[0][0][23:16];
				n1_b	<= r_rf[2][2][23:16];
				p1_a	<= r_rf[0][2][23:16];
				p1_b	<= r_rf[2][0][23:16];
			end
			2'b10: begin
				//	B	G	B
				//	G	R	G
				//	B	G	B
				n1_a	<= r_rf[0][0][7:0];
				n1_b	<= r_rf[2][2][7:0];
				p1_a	<= r_rf[0][2][7:0];
				p1_b	<= r_rf[2][0][7:0];
			end
		endcase
	end
end

abs_diff #(.delay(1))
n_diff_1
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, n1_a}),
	.b({10'b0, n1_b}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(n1)
);

abs_diff #(.delay(1))
p_diff_1
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, p1_a}),
	.b({10'b0, p1_b}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(p1)
);

abs_diff #(.delay(1))
n_diff_2
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, g5ls1}),
	.b({10'b0, rgb19[17:9]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(n2)
);

abs_diff #(.delay(1))
p_diff_b_2
(
	.clk(clk),
	.reset(reset),
	.a({10'b0, g5ls1}),
	.b({10'b0, rgb37[17:9]}),
	.iValid(iValid),
	
	.oValid(),
	.oRes(p2)
);

// Add. Calculate R, G and B
reg	[26:0]	rgb28;
reg	[26:0]	rgb46;
reg	[26:0]	rgb19;
reg	[26:0]	rgb37;
reg	[8:0]		g5ls1;

reg	[26:0]	r_rgb28	[1:0];
reg	[26:0]	r_rgb46	[1:0];
reg	[26:0]	r_rgb19	[1:0];
reg	[26:0]	r_rgb37	[1:0];

reg	[7:0]		case1_1r, case2_1r, case3_1r, case4_1r;
reg	[7:0]		case1_1b, case2_1b, case3_1b, case4_1b;
reg	[7:0]		case1_2, case2_2, case3_2, case4_2;

// Truncate
reg	[7:0]		case1r	[1:0];
reg	[7:0]		case2r	[1:0];
reg	[7:0]		case3r	[1:0];
reg	[7:0]		case4r	[1:0];
reg	[7:0]		case1b	[1:0];
reg	[7:0]		case2b	[1:0];
reg	[7:0]		case3b	[1:0];
reg	[7:0]		case4b	[1:0];

reg	[7:0]		case5r, case5b;

reg	[7:0]		caseRes	[4:0];

// smoothRes[0]	-- R, smoothRes[1]	-- B
reg	[7:0]		smoothRes [1:0][pipelineDepth - 9:0];

// edgeRes[0]	-- R, edgeRes[1]	-- B
reg	[7:0]		edgeRes [1:0];

// Cached center pixel data
reg	[23:0]	r_rf_center [pipelineDepth - 4:0];

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
	
	// isEdge
	for (i = 0; i < pipelineDepth - 8; i = i + 1) begin: isEdgeDelay
		always @(posedge clk) begin
			if (reset) begin
				isEdge[i]		<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					isEdge[i]	<= isEdge[i-1];
				end
				else begin
					isEdge[i]	<= (edgeSel[0] | edgeSel[1] | edgeSel[2] | edgeSel[3]);
				end
			end
		end
	end
	
	
	// Cycle 1, calculate bilinear in all directions, and g5 * 2
	for (i = 0; i < 3; i = i + 1) begin: sum_cycle1
		always @(posedge clk) begin
			if (reset) begin
				rgb28		<= 'b0;
				rgb46		<= 'b0;
				rgb19		<= 'b0;
				rgb37		<= 'b0;
				g5ls1		<= 'b0;
			end
			else if (iValid) begin
				rgb28[i*9+8:i*9]	<= (r_rf[0][1][i*8+7:i*8] + r_rf[2][1][i*8+7:i*8]);
				rgb46[i*9+8:i*9]	<= (r_rf[1][0][i*8+7:i*8] + r_rf[1][2][i*8+7:i*8]);
				rgb19[i*9+8:i*9]	<= (r_rf[0][0][i*8+7:i*8] + r_rf[2][2][i*8+7:i*8]);
				rgb37[i*9+8:i*9]	<= (r_rf[2][0][i*8+7:i*8] + r_rf[0][2][i*8+7:i*8]);
				g5ls1					<= r_rf[1][1] << 1;
			end
		end
	end
	
	// Cycle 2, start to calculate 5 laplacian cases
	always @(posedge clk) begin
		if (reset) begin
			case1_1r		<= 'b0;
			case2_1r		<= 'b0;
			case3_1r		<= 'b0;
			case4_1r		<= 'b0;
			case1_1b		<= 'b0;
			case2_1b		<= 'b0;
			case3_1b		<= 'b0;
			case4_1b		<= 'b0;
			case1_2		<= 'b0;
			case2_2		<= 'b0;
			case3_2		<= 'b0;
			case4_2		<= 'b0;
		end
		else if (iValid) begin
			case1_1r		<= rgb46[26:19];
			case2_1r		<= rgb28[26:19];
			case3_1r		<= rgb19[26:19];
			case4_1r		<= rgb37[26:19];
			
			case1_1b		<= rgb46[8:1];
			case2_1b		<= rgb28[8:1];
			case3_1b		<= rgb19[8:1];
			case4_1b		<= rgb37[8:1];
		
			case1_2		<= (g5ls1 - rgb46[17:9]) >> 1;
			case2_2		<= (g5ls1 - rgb28[17:9]) >> 1;
			case3_2		<= (g5ls1 - rgb19[17:9]) >> 1;
			case4_2		<= (g5ls1 - rgb37[17:9]) >> 1;
		end
	end
	
	// Cycle 3, get laplacian results except for the last case
	always @(posedge clk) begin
		if (reset) begin
			case1r[0]	<= 'b0;
			case2r[0]	<= 'b0;
			case3r[0]	<= 'b0;
			case4r[0]	<= 'b0;
			case1b[0]	<= 'b0;
			case2b[0]	<= 'b0;
			case3b[0]	<= 'b0;
			case4b[0]	<= 'b0;
		end
		else if (iValid) begin
			case1r[0]	<= case1_1r + case1_2;
			case2r[0]	<= case2_1r + case2_2;
			case3r[0]	<= case3_1r + case3_2;
			case4r[0]	<= case4_1r + case4_2;
			
			case1b[0]	<= case1_1b + case1_2;
			case2b[0]	<= case2_1b + case2_2;
			case3b[0]	<= case3_1b + case3_2;
			case4b[0]	<= case4_1b + case4_2;
		end
	end
	
	// Cycle 4, get case 5rb
	always @(posedge clk) begin
		if (reset) begin
			case1r[1]	<= 'b0;
			case2r[1]	<= 'b0;
			case3r[1]	<= 'b0;
			case4r[1]	<= 'b0;
			case1b[1]	<= 'b0;
			case2b[1]	<= 'b0;
			case3b[1]	<= 'b0;
			case4b[1]	<= 'b0;
			case5r		<= 'b0;
			case5b		<= 'b0;
		end
		else if (iValid) begin
			case1r[1]	<= case1r[0];
			case2r[1]	<= case2r[0];
			case3r[1]	<= case3r[0];
			case4r[1]	<= case4r[0];
			
			case1b[1]	<= case1b[0];
			case2b[1]	<= case2b[0];
			case3b[1]	<= case3b[0];
			case4b[1]	<= case4b[0];
			
			case5r		<= (case3r[0] + case4r[0]) >> 1;
			case5b		<= (case3b[0] + case4b[0]) >> 1;
		end
	end
	
	// Cycle 5, select R or B for case 1-5
	for (i = 0; i < 5; i = i + 1) begin: caseRes1_5
		always @(posedge clk) begin
			if (reset) begin
				caseRes[i]	<= 'b0;
			end
			else if (iValid) begin
				// Select R or B
				case ({r_y[6][0], r_x[6][0]})
					2'b00: begin
						//	G	R	G
						//	B	G	B
						//	G	R	G
						caseRes[0]	<= case1b[1];
						caseRes[1]	<= case2r[1];
						caseRes[2]	<=	'b0;
						caseRes[3]	<= 'b0;
						caseRes[4]	<= 'b0;
					end
					2'b01: begin
						//	R	G	R
						//	G	B	G
						//	R	G	R
						caseRes[0]	<= 'b0;
						caseRes[1]	<= 'b0;
						caseRes[2]	<=	case3r[1];
						caseRes[3]	<= case4r[1];
						caseRes[4]	<= case5r[1];
					end
					2'b10: begin
						//	B	G	B
						//	G	R	G
						//	B	G	B
						caseRes[0]	<= 'b0;
						caseRes[1]	<= 'b0;
						caseRes[2]	<=	case3b[1];
						caseRes[3]	<= case4b[1];
						caseRes[4]	<= case5b[1];
					end
					2'b11: begin
						//	G	B	G
						//	R	G	R
						//	G	B	G
						caseRes[0]	<= case1r[1];
						caseRes[1]	<= case2b[1];
						caseRes[2]	<=	'b0;
						caseRes[3]	<= 'b0;
						caseRes[4]	<= 'b0;
					end
				endcase
			end
		end
	end
	
	// rgb delay
	for (i = 0; i < 2; i = i + 1) begin: rgbDealy
		always @(posedge clk) begin
			if (reset) begin
				r_rgb28[i]	<=	'b0;
				r_rgb46[i]	<=	'b0;
				r_rgb19[i]	<=	'b0;
				r_rgb37[i]	<=	'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					r_rgb28[i]	<=	r_rgb28[i-1];
					r_rgb46[i]	<=	r_rgb46[i-1];
					r_rgb19[i]	<=	r_rgb19[i-1];
					r_rgb37[i]	<=	r_rgb37[i-1];
				end
				else begin
					r_rgb28[i]	<=	rgb28;
					r_rgb46[i]	<=	rgb46;
					r_rgb19[i]	<=	rgb19;
					r_rgb37[i]	<=	rgb37;
				end
			end
		end
	end
	
	// Determine smooth area
	for (i = 0; i < pipelineDepth - 8; i = i + 1) begin: smoothDealy
		always @(posedge clk) begin
			if (reset) begin
				smoothRes[0][i]	<= 'b0;
				smoothRes[1][i]	<= 'b0;
			end
			else if (iValid) begin
				if (i > 0) begin
					smoothRes[0][i]	<= smoothRes[0][i-1];
					smoothRes[1][i]	<= smoothRes[1][i-1];
				end
				else begin
					case ({r_y[6][0], r_x[6][0]})
						2'b00: begin
							//	G	R	G
							//	B	G	B
							//	G	R	G
							smoothRes[0][i]	<= r_rgb28[1][26:19];
							smoothRes[1][i]	<= r_rgb46[1][8:1];
						end
						2'b01: begin
							//	R	G	R
							//	G	B	G
							//	R	G	R
							smoothRes[0][i]	<= (edgeSel[0] == 0) ? r_rgb19[1][26:19] : r_rgb37[1][26:19];
							smoothRes[1][i]	<= r_rf_center[3][7:0];
						end
						2'b10: begin
							//	B	G	B
							//	G	R	G
							//	B	G	B
							smoothRes[0][i]	<= r_rf_center[3][23:16];
							smoothRes[1][i]	<= (edgeSel[0] == 0) ? r_rgb19[1][8:1] : r_rgb37[1][8:1];
						end
						2'b11: begin
							//	G	B	G
							//	R	G	R
							//	G	B	G
							smoothRes[0][i]	<= r_rgb46[1][26:19];
							smoothRes[1][i]	<= r_rgb28[1][8:1];
						end
					endcase
				end
			end
		end
	end
	
	// Selection based on n and p
	always @(posedge clk) begin
		if (reset) begin
			n			<= 'b0;
			p			<= 'b0;
		end
		else if (iValid) begin
			n			<= n1 + n2;
			p			<= p1 + p2;
			
			case ({r_y[7][0], r_x[7][0]})
				2'b00: begin
					//	G	R	G
					//	B	G	B
					//	G	R	G
					edgeRes[0]	<= caseRes[1];
					edgeRes[1]	<= caseRes[0];
				end
				2'b01: begin
					//	R	G	R
					//	G	B	G
					//	R	G	R
					if (n < p) begin
						edgeRes[0]	<= caseRes[2];
					end
					else if (n < p) begin
						edgeRes[0]	<= caseRes[3];
					end
					else begin
						edgeRes[0]	<= caseRes[4];
					end
					edgeRes[1]	<= 'b0;
				end
				2'b10: begin
					//	B	G	B
					//	G	R	G
					//	B	G	B
					if (n < p) begin
						edgeRes[1]	<= caseRes[2];
					end
					else if (n < p) begin
						edgeRes[1]	<= caseRes[3];
					end
					else begin
						edgeRes[1]	<= caseRes[4];
					end
					edgeRes[0]	<= 'b0;
				end
				2'b11: begin
					//	G	B	G
					//	R	G	R
					//	G	B	G
					edgeRes[0]	<= caseRes[0];
					edgeRes[1]	<= caseRes[1];
				end
			endcase
		end
	end
	
	// Delay line of pixel counters and signals
	// It takes 2 cycles for a pixel to get to the
	// center of the RF.
	// After that, it takes another 4 cycles to calculate
	// the green interpolation results.
	for (i = 0; i < pipelineDepth; i = i + 1) begin: delayLine
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
	for (i = 0; i < pipelineDepth - 3; i = i + 1) begin: rfcenter
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

always@ (posedge clk) begin
	if(reset) begin
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
		
		moR	<= (isEdge[pipelineDepth-9] == 1) ? edgeRes[0] : smoothRes[0][pipelineDepth-9];
		moG	<= r_rf_center[pipelineDepth-4][15:8];
		moB	<= (isEdge[pipelineDepth-9] == 1) ? edgeRes[1] : smoothRes[1][pipelineDepth-9];
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
wire	[7:0]		oGinterR, oGinterG, oGinterB;

demosaic_acpi_ginter #(.width(width), .height(height), .kernelSize(kernelSize))
ginter
(
	.clk(clk),
	.iData(iData),
	.reset(reset),
	.iValid(iValid),
	
	.oR(oGinterR),
	.oG(oGinterG),
	.oB(oGinterB),
	.xCnt(),
	.yCnt(),
	.demosaicCnt(),
	.oF(f),
	.oValid(),
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

demosaic_acpi_RBinter #(.width(width), .height(height), .kernelSize(kernelSize))
RBinter
(
	.clk(clk),
	.iData({oGinterR, oGinterG, oGinterB}),
	.reset(reset),
	.iValid(iValid),
	.T(T),
	
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
