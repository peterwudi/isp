
// No iValid
module demosaic_neighbor
(
	input				clk,
	input		[7:0]	iData,
	input				reset,
	
	output	[7:0]	oR,
	output	[7:0]	oG,
	output	[7:0]	oB,
	output			oValid				
);

wire	[7:0]	tap0;
wire	[7:0]	tap1;
reg	[7:0]	r_tap0;
reg	[7:0]	r_tap1;
reg	[7:0]	moR;
reg	[7:0]	moG;
reg	[7:0]	moB;
reg			moValid;

assign	oR			=	moR[7:0];
assign	oG			=	moG[7:0];
assign	oB			=	moB[7:0];
assign	oValid	=	moValid;
/*
Line_Buffer u0
(
	.clken(iDVAL),
	.clock(iCLK),
	.shiftin(iDATA),
	.taps0x(mDATA_1),
	.taps1x(mDATA_0)
);
*/

demosaic_neighbor_shift_reg buffer(
	.clock(clk),
	.shiftin(iData),
	.shiftout(),
	.taps0x(tap0),
	.taps1x(tap1)
);

parameter	width		= 320;
parameter	height	= 240;	

// Need to buffer 2 full rows before intrapolation
localparam	totalCycles	= width*(height+2);

// Pixel counter
reg	[31:0]	cnt;

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
		
		cnt		<= 'b0;
	end
	else
	begin
		r_tap0	<=	tap0;
		r_tap1	<=	tap1;
		
		if (cnt	< )
		
		
		
		if (cnt < width * 2) begin
			
		
		
		moValid	<=	{iY_Cont[0]|iX_Cont[0]}	?	1'b0	:	iDVAL;
		if({iY_Cont[0],iX_Cont[0]}==2'b10)
		begin
			mCCD_R	<=	mDATA_0;
			mCCD_G	<=	mDATAd_0+mDATA_1;
			mCCD_B	<=	mDATAd_1;
		end	
		else if({iY_Cont[0],iX_Cont[0]}==2'b11)
		begin
			mCCD_R	<=	mDATAd_0;
			mCCD_G	<=	mDATA_0+mDATAd_1;
			mCCD_B	<=	mDATA_1;
		end
		else if({iY_Cont[0],iX_Cont[0]}==2'b00)
		begin
			mCCD_R	<=	mDATA_1;
			mCCD_G	<=	mDATA_0+mDATAd_1;
			mCCD_B	<=	mDATAd_0;
		end
		else if({iY_Cont[0],iX_Cont[0]}==2'b01)
		begin
			mCCD_R	<=	mDATAd_1;
			mCCD_G	<=	mDATAd_0+mDATA_1;
			mCCD_B	<=	mDATA_0;
		end
	end
end

endmodule
