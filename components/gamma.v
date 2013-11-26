module gamma
(
	input					clk,
	input					reset,
	input		[17:0]	iY, iCb, iCr,
	input					iValid,
	
	output	[17:0]	oY, oCb, oCr,
	output				oValid
);
reg	[17:0]	r_Y, r_Cb, r_Cr, mY, mCb, mCr;
reg				r_iValid, moValid;
wire	[11:0]	ycclutOut;

// Range of each components:
// Y: 0 - 255, Cb: -127.5 - 127.5, Cr: -127.5 - 127.5

ycclut ycclut(
	.address(iY[16:5]),
	.clock(clk),
	.data(),
	.rden(iValid),
	.wren(0),
	.q(ycclutOut)
);

always @(posedge clk) begin
	if (reset) begin
		r_Y		<= 'b0;
		r_Cb		<= 'b0;
		r_Cr		<= 'b0;
		mY			<= 'b0;
		mCb		<= 'b0;
		mCr		<= 'b0;
		r_iValid	<=	0;
		moValid	<= 0;
	end
	else begin
		r_Y		<= iY;
		r_Cb		<= iCb;
		r_Cr		<= iCr;
		r_iValid	<= iValid;
		
		mY			<= r_Y;
		mCb		<= r_Cb;
		mCr		<= r_Cr;
		moValid	<= r_iValid;
	end	
end

assign	oY			= {mY[17], ycclutOut, mY[4:0]};
assign	oCb		= mCb;
assign	oCr		= mCr;
assign	oValid	= moValid;

endmodule
