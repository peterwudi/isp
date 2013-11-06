`timescale 1ns/1ns

module tb();

//////////// CLOCK //////////
logic		          		GCLKIN;
logic		          		GCLKOUT_FPGA;
logic		          		OSC_50_BANK2;
logic		          		OSC_50_BANK3;
logic		          		OSC_50_BANK4;
logic		          		OSC_50_BANK5;
logic		          		OSC_50_BANK6;
logic		          		OSC_50_BANK7;
logic		          		PLL_CLKIN_p;

//////////// External PLL //////////
//logic		     [4:0]		MAX_CONF_D;
logic		          		MAX_I2C_SCLK;
logic		          		MAX_I2C_SDAT;

//////////// SMA //////////
logic		          		SMA_CLKIN_p;
logic		          		SMA_CLKOUT_p;
//logic		          		SMA_GXBCLK_p;

//////////// LED x 8 //////////
logic		     [7:0]		LED;

//////////// BUTTON x 4, EXT_IO and CPU_RESET_n //////////
logic		     [3:0]		BUTTON;
logic		          		CPU_RESET_n;
logic		          		EXT_IO;

//////////// DIP SWITCH x 8 //////////
logic		     [7:0]		SW;

//////////// SLIDE SWITCH x 4 //////////
logic		     [3:0]		SLIDE_SW;

//////////// SEG7 //////////
logic		     [6:0]		SEG0_D;
logic		          		SEG0_DP;
logic		     [6:0]		SEG1_D;
logic		          		SEG1_DP;



//////////// GPIO_0 //////////
logic		    [11:0]		D5M_D;
logic		          		D5M_ESETn;
logic		          		D5M_FVAL;
logic		          		D5M_LVAL;
logic		          		D5M_PIXLCLK;
logic		          		D5M_SCLK;
logic		          		D5M_SDATA;
logic		          		D5M_STROBE;
logic		          		D5M_TRIGGER;
logic		          		D5M_XCLKIN;

//////////// HSMC-A //////////
logic		          		DVI_EDID_WP;
logic		          		DVI_RX_CLK;
logic		     [3:1]		DVI_RX_CTL;
logic		    [23:0]		DVI_RX_D;
logic		          		DVI_RX_DDCSCL;
logic		          		DVI_RX_DDCSDA;
logic		          		DVI_RX_DE;
logic		          		DVI_RX_HS;
logic		          		DVI_RX_SCDT;
logic		          		DVI_RX_VS;
logic		          		DVI_TX_CLK;
logic		     [3:1]		DVI_TX_CTL; //no
logic		    [23:0]		DVI_TX_D;
logic		          		DVI_TX_DDCSCL; //no
logic		          		DVI_TX_DDCSDA; //no
logic		          		DVI_TX_DE;
logic		          		DVI_TX_DKEN;   //no
logic		          		DVI_TX_HS;
logic		          		DVI_TX_HTPLG;
logic		          		DVI_TX_ISEL;
logic		          		DVI_TX_MSEN;   //no
logic		          		DVI_TX_PD_N;   //no
logic		          		DVI_TX_SCL;
logic		          		DVI_TX_SDA;
logic		          		DVI_TX_VS;

//////////// HSMC I2C //////////
logic		          		HSMC_SCL;
logic		          		HSMC_SDA;
logic unsigned [7:0]		i_data;
logic unsigned	[7:0]		o_data;

DE4_230_D5M_DVI dut ( .* );

initial	OSC_50_BANK2 = '1;
always begin
	#10		OSC_50_BANK2 = ~OSC_50_BANK2;
end


initial begin
	BUTTON[0] = 0;
	
	for (int i = 1; i < 17; i++) begin
		@(negedge OSC_50_BANK2);
	end

	BUTTON[0] = 1;
	
end



endmodule
