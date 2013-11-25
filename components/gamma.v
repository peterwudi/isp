module gamma
{
	input					clk,
	input		[17:0]	iY, iCb, iCr,
	input					iValid,
	
	output	[17:0]	oY, oCb, oCr
}
reg	[17:0]	mY, mCb, mCr;


// Range of each components:
// Y: 0 - 255, Cb: -127.5 - 127.5, Cr: -127.5 - 127.5

// TODO: Store delta of things, don't store the entire value.
ycclut ycclut(
	.address(iY[16:5]),
	.clock(clk),
	.data(),
	.rden(iValid),
	.wren(0),
	.q());



endmodule
