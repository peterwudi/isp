
module ddr2_buffer(
	input					d5m_clk,
	input					ctrl_clk,
	input					dvi_clk,
	
	input					reset_n,
	input					wr_new_frame,
	input					rd_new_frame,
	
	// Write side
	input		[31:0]	iData,
	input					iValid,
		
	input					read_init,
	input					read_rstn,
	output	[31:0]	oData,
	output				frame_read_done,
	
	output				read_empty_rdfifo,
	output				write_full_rdfifo,
	output				read_empty_wrfifo,
	output				write_full_wrfifo,
	
	
	output	[8:0]		write_fifo_wrusedw,
	output	[8:0]		write_fifo_rdusedw,
	output	[8:0]		read_fifo_wrusedw,
	output	[8:0]		read_fifo_rdusedw
);


reg				read;
reg	[31:0]	read_addr;
wire				read_waitrequest;
reg	[1:0]		read_state;
wire	[31:0]	ram_oData;

reg				moValid;
reg	[31:0]	moData;

reg				write;
wire				write_waitrequest;
reg	[31:0]	write_addr;	
reg	[1:0]		write_state;


wire				write_fifo_wrfull;
wire				write_fifo_rdempty;
reg				write_fifo_rdreq;
wire	[31:0]	write_fifo_q;

wire				read_fifo_wrfull;
wire				read_fifo_rdempty;
reg				read_fifo_rdreq;
reg				read_fifo_wrreq;
wire	[31:0]	read_fifo_q;
reg	[31:0]	read_fifo_wrdata;

assign	read_empty_rdfifo = read_fifo_rdreq & read_fifo_rdempty;
assign	write_full_rdfifo = read_fifo_wrreq & read_fifo_wrfull;

assign	read_empty_wrfifo = write_fifo_rdreq & write_fifo_rdempty;
assign	write_full_wrfifo = iValid & write_fifo_wrfull;


parameter frameSize = 640; //640*480;

// Delay for the write side of the read FIFO, 64 is a random number...
parameter readDelay = 64;

ddr2_sys u0 (
        .clk_clk                    (ctrl_clk),                    //   clk.clk
        .reset_reset_n              (reset_n),              // reset.reset_n
        
		  .write_write_addr (write_addr), // write.write_addr
        .write_iData      (write_fifo_q),      //      .iData
		  .write_write      (write),      //      .write
        .write_waitrequest (write_waitrequest), //      .write_done
        
		  
		  .read_read_addr   (read_addr),   //  read.read_addr
        .read_read        (read),        //      .read
        .read_oData       (ram_oData),       //      .oData
        .read_waitrequest   (read_waitrequest)    //      .wait_read
);

ddr2_fifo write_fifo(
	.aclr(!reset_n),
	.data(iData),
	
	// Write (from D5M)
	.wrclk(d5m_clk),
	.wrreq(iValid),		// No back pressure
	.wrfull(write_fifo_wrfull),
	.wrusedw(write_fifo_wrusedw),
	
	// Read (to DRAM)
	.rdclk(ctrl_clk),
	.rdreq(write_fifo_rdreq),
	
	.q(write_fifo_q),
	.rdempty(write_fifo_rdempty),
	.rdusedw(write_fifo_rdusedw)
);

// Delay the read to avoid initially empty data being read out
reg [15:0]	delayCnt;
reg			wr_to_rd_delay_done;

always @(posedge ctrl_clk) begin
	if ((~reset_n) | (wr_new_frame)) begin
		delayCnt			<= 0;
		wr_to_rd_delay_done	<= 0;
	end
	else begin
		if (delayCnt < readDelay)begin
			delayCnt <= delayCnt + 1;
		end
		else begin
			wr_to_rd_delay_done <= 1;
		end
	end
end	


always @(posedge dvi_clk) begin
	// Q data available 1 dvi_clk cycle after rdreq
	moValid		<= read_fifo_rdreq;
	if (moValid == 1) begin
		moData	<= read_fifo_q;
	end
	else begin
		moData	<= 'd0;
	end
end

assign oData = moData;

ddr2_fifo read_fifo(
	.aclr(!reset_n),
	.data(read_fifo_wrdata),
	
	// Write (from DRAM)
	.wrclk(ctrl_clk),
	.wrreq(read_fifo_wrreq),
	.wrfull(read_fifo_wrfull),
	.wrusedw(read_fifo_wrusedw),
	
	// Read (to DVI)
	.rdclk(dvi_clk),
	.rdreq(read_fifo_rdreq),
	
	.q(read_fifo_q),
	.rdempty(read_fifo_rdempty),
	.rdusedw(read_fifo_rdusedw)
);

// Read side of the write fifo, write into DRAM
always @(posedge ctrl_clk) begin
	if (!reset_n) begin
		write_state			<= 0;
		write					<= 0;
		write_addr			<= 'd0;
		write_fifo_rdreq	<= 0;
	end
	else begin
		case (write_state)
			2'b00: begin
				if (write_fifo_rdempty == 0) begin
					// Something is in the FIFO, read
					write_state			<= 2'b01;
					write					<= 0;
					write_fifo_rdreq	<= 1;
				end
				else begin
					// Nothing is in the FIFO, keep waiting
					write_state			<= 2'b00;
					write					<= 0;
					write_fifo_rdreq	<= 0;
				end
			end
			2'b01: begin
				// Start to write to DRAM
				write_state			<= 2'b10;
				write					<= 1;
				write_fifo_rdreq	<= 0;
			end
			2'b10: begin
				if (write_waitrequest == 1) begin
					// Keep waiting
					write_state			<= 2'b10;
					write					<= 1;
					write_fifo_rdreq	<= 0;
				end
				else begin
					// Write done
					if (write_addr < (frameSize-1)*4) begin
						write_addr	<= write_addr + 4;
					end
					else begin
						write_addr	<= 0;
					end
					if (write_fifo_rdempty == 0) begin
						// Can read the next data in the fifo
						write_state			<= 2'b01;
						write					<= 0;
						write_fifo_rdreq	<= 1;
					end
					else begin
						// Wait for some data in the fifo
						write_state			<= 2'b00;
						write					<= 0;
						write_fifo_rdreq	<= 0;
					end
				end
			end
			default: begin
				write_state			<= 0;
				write					<= 0;
				write_addr			<= 'd0;
				write_fifo_rdreq	<= 0;
			end
		endcase
	end
end

// Don't read when the read FIFO is empty, or when read_rstn is low
reg		frame_done;
assign	frame_read_done = frame_done;

// Write side of the read fifo, read from DRAM
always @(posedge ctrl_clk) begin
	if (		(!reset_n)
			||	(!read_rstn)) begin
		read_state	<= 0;
		read			<= 0;
		read_addr	<= 'd0;
		frame_done	<= 0;
		read_fifo_wrreq	<= 0;
		read_fifo_rdreq	<= 0;
		read_fifo_wrdata	<= 'b0;
	end
	else begin
		read_fifo_rdreq	<= (~read_fifo_rdempty) & read_init;

		if (rd_new_frame == 1) begin
			read_state	<= 0;
			read			<= 0;
			
			// Don't reset read_addr
			// Don't reset read_fifo_rdreq because this only
			// concerns the write side of the read FIFO
			frame_done	<= 0;
			read_fifo_wrreq	<= 0;
		end
		else begin
			case (read_state)
				2'b00: begin
					read_fifo_wrreq	<= 0;
					if (		(read_fifo_wrfull == 0)
							&& (frame_done == 0)
							&& (wr_to_rd_delay_done == 1)) begin
						// Read FIFO has space.
						// Can write into FIFO
						read_state	<= 2'b01;
						read			<= 1;
					end
					else begin
						// Keep waiting
						read_state	<= 2'b00;
						read			<= 0;
					end
				end
				2'b01: begin
					if (frame_done == 1) begin
						read_state	<= 2'b00;
					
						// don't care what read is
					end
					else begin
						if (read_waitrequest == 1) begin
							read_state	<= 2'b01;
							read			<= 1;
							read_fifo_wrreq	<= 0;
						end
						else begin
							// Register the data
							read_fifo_wrdata	<= ram_oData;
							if (read_fifo_wrfull == 1) begin
								// FIFO is full, the data just read cannot
								// be written to the read FIFO, go back to
								// initial state to wait, don't increment
								// read addr
								//
								// NOTE: This could lead to a warning saying
								// read is chaged when waitrequest is high, but
								// it's OK because the data is discarded
								read_state	<= 2'b00;
								read			<= 0;
								read_fifo_wrreq	<= 0;
							end
							else begin
								// Have space in the read FIFO, write
								read_state	<= 2'b10;
								read			<= 0;
								read_fifo_wrreq	<= 1;
							end
						end
					end
				end
				2'b10: begin
					read_fifo_wrreq	<= 0;
					
					// Get addr for the next read
					if (read_addr < (frameSize-1)*4) begin	
						read_addr	<= read_addr + 4;
					end
					else begin
						read_addr	<= 0;
						frame_done	<= 1;
					end					
					
					if (read_fifo_wrfull == 0) begin
						// Can read DRAM again
						read_state	<= 2'b01;
						read			<= 1;
					end
					else begin
						read_state	<= 2'b00;
						read			<= 0;
					end
				end
			endcase
		end
	end
end
	
	
	
endmodule
