
module bus(
	input					OSC2_50,
	input					GPIO1_PIXLCLK,
	input					ctrl_clk,
	
	//input					dvi_clk,
	
	input					reset_n,
	input					new_frame,
	
	// Write side
	input		[31:0]	iData,
	input					sCCD_DVAL,
		
	output	[31:0]	Read_DATA,
	
	//TEST
	input					read_init,
	
	// vpg
	output 				vpg_pclk,
	output 				vpg_de,
	output				vpg_hs,
	output				vpg_vs,
	output	[23:0]	vpg_data,

	output				read_empty_rdfifo,
	output				write_full_rdfifo,
	output				read_empty_wrfifo,
	output				write_full_wrfifo,
	
	output	[8:0]		write_fifo_wrusedw,
	output	[8:0]		write_fifo_rdusedw,
	output	[8:0]		read_fifo_wrusedw,
	output	[8:0]		read_fifo_rdusedw
);

`include "../../vpg_source/vpg.h" 


//	Prevent from read at starting because of none data in the ddr2
reg	[15:0]write_cnt;
always@(posedge ~GPIO1_PIXLCLK)
	if (~reset_n)
		write_cnt <= 0;
	else if ( (sCCD_DVAL) & (write_cnt != 65536) )
		write_cnt <= write_cnt + 1;
			                  
reg	read_rstn;
always@(posedge ~GPIO1_PIXLCLK)
	begin
		if (~reset_n)
			read_rstn <= 0;
		else if (write_cnt == 512)
			read_rstn <= 1;
end	

ddr2_buffer u8(
	.d5m_clk(~GPIO1_PIXLCLK),
	.ctrl_clk(ctrl_clk),//use pixclk for now, should use a faster one
	.dvi_clk(vpg_pclk),
	
	.reset_n(reset_n),
	.new_frame(new_frame),
	
	
	// Write side
	//.iData({2'b0,sCCD_R[11:2], sCCD_G[11:2], sCCD_B[11:2]}),
	.iData(iData),
	.iValid(sCCD_DVAL),
		
	//.read_init(vpg_de),
	.read_init(read_init),
	.read_rstn(read_rstn),
	.oData(Read_DATA),
	
	// Debug
	.read_empty_rdfifo(read_empty_rdfifo),
	.write_full_rdfifo(write_full_rdfifo),
	.read_empty_wrfifo(read_empty_wrfifo),
	.write_full_wrfifo(write_full_wrfifo),
	
	.write_fifo_wrusedw(write_fifo_wrusedw),
	.write_fifo_rdusedw(write_fifo_rdusedw),
	.read_fifo_wrusedw(read_fifo_wrusedw),
	.read_fifo_rdusedw(read_fifo_rdusedw)
);

//	DVI
wire 				reset_n_dvi;
wire 				pll_100M;
wire 				pll_100K;

//	System  generate
sys_pll sys_pll_inst(
	.areset(1'b0),
	.inclk0(OSC2_50),
	.c0(pll_100M),
	.c1(pll_100K),
	.c2(GPIO1_XCLKIN),//25M 
	.locked(reset_n_dvi)
	);

//---------------------------------------------------//
//				DVI Mode Change Button Monitor 			 //
//---------------------------------------------------//
wire		[3:0]	vpg_mode;	
/*`ifdef SXGA_1280x1024p60
	assign vpg_mode = `MODE_1280x1024;
`else
*/
    assign vpg_mode = `VGA_640x480p60;
//`endif


//	DDR2
wire				ip_init_done;
wire				wrt_full_port0;
wire				wrt_full_port1;


wire 				gen_sck;
wire				gen_i2s;
wire				gen_ws;

// Note: only for DVI testing purpose
//----------------------------------------------//
// 			 Video Pattern Generator	  	   	//
//----------------------------------------------//
wire [3:0]	vpg_disp_mode;
wire [1:0]	vpg_disp_color;

vpg	vpg_inst(
	.clk_100(pll_100M),
	.reset_n(read_rstn & reset_n_dvi),//
	//.reset_n(reset_n_dvi),
	.mode(vpg_mode),
	.mode_change(1'b0),
	.disp_color(`COLOR_RGB444),       
	.vpg_pclk(vpg_pclk),
	.vpg_de(vpg_de),
	.vpg_hs(vpg_hs),
	.vpg_vs(vpg_vs),
	.vpg_r(vpg_data[23:16]), //
	.vpg_g(vpg_data[15:8]), //
	.vpg_b(vpg_data[7:0]) //
);









endmodule
