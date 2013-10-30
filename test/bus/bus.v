
module bus(
	input					d5m_clk,
	input					ctrl_clk,
	input					dvi_clk,
	
	input					reset_n,
	
	// Write side
	input		[31:0]	iData,
	input					iValid,
	//input		[18:0]	write_addr,	// multiple of 4
	
	input					read_init,
	//input		[18:0]	read_addr,	// multiple of 4
	output	[31:0]	oData,
	output				oValid,
	
	output				read_empty_rdfifo,
	output				write_full_wrfifo
	
);


reg				read;
reg	[31:0]	read_addr;
wire				read_waitrequest;
//reg				moValid;
reg	[1:0]		read_state;
wire	[31:0]	ram_oData;
reg				ram_oValid;


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
wire				read_fifo_rdreq;
wire	[31:0]	read_fifo_q;

assign	read_empty_rdfifo = read_init & read_fifo_rdempty;
assign	write_full_wrfifo = iValid & write_fifo_wrfull;


bus_sys u0 (
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
	.wrusedw(),
	
	// Read (to DRAM)
	.rdclk(ctrl_clk),
	.rdreq(write_fifo_rdreq),
	
	.q(write_fifo_q),
	.rdempty(write_fifo_rdempty),
	.rdusedw()
);


ddr2_fifo read_fifo(
	.aclr(!reset_n),
	.data(ram_oData),
	
	// Write (from DRAM)
	.wrclk(ctrl_clk),
	.wrreq(ram_oValid),
	.wrfull(read_fifo_wrfull),
	.wrusedw(),
	
	// Read (to DVI)
	.rdclk(dvi_clk),
	.rdreq(read_init),	// Say we can always read...
	
	.q(oData),
	.rdempty(read_fifo_rdempty),
	.rdusedw()
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
				if (write_fifo_rdempty == 1) begin
					// Read from the write fifo
					write_state			<= 2'b01;
					write					<= 0;
					write_fifo_rdreq	<= 1;
				end
				else begin
					// Keep waiting
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
					write_addr			<= write_addr + 4;
					
					if (write_fifo_rdempty != 0) begin
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

// Write side of the read fifo, read from DRAM
always @(posedge ctrl_clk) begin
	if (!reset_n) begin
		read_state	<= 0;
		read			<= 0;
		read_addr	<= 'd0;
		ram_oValid	<= 0;
	end
	else begin
		case (read_state)
			1'b0: begin
				if (read_fifo_wrfull == 0) begin
					// Can write into DRAM
					read_state	<= 1'b1;
					read			<= 1;
				end
				else begin
					// Keep waiting
					read_state	<= 1'b0;
					read			<= 0;
				end
				ram_oValid <= 0;
			end
			1'b1: begin
				if (read_waitrequest == 1) begin
					read_state	<= 1'b1;
					read			<= 1;
					ram_oValid	<= 0;					
				end
				else begin
					// Read done, ready for the next read
					
					// TODO: See if we can check if the fifo is full here,
					// then do the same thing as in state 0 to determine
					// where to go to.
					read_state	<= 1'b0;
					read			<= 0;
					ram_oValid	<= 1;
					read_addr	<= read_addr + 4;
				end
			end
		endcase
	end
end


// Write state machine
// Streaming, no back pressure
/*
always @(posedge ctrl_clk) begin
	if (!reset_n) begin
		write_state	<= 0;
		write			<= 0;
		write_addr	<= 'd0;
	end
	else begin
		case (write_state)
			1'b0: begin
				if (iValid == 1) begin
					// Start writing
					write_state	<= 1'b1;
					write			<= 1;
				end
				else begin
					// Keep waiting
					write_state	<= 1'b0;
					write			<= 0;
				end
			end
			1'b1: begin
				if (write_waitrequest == 1) begin
					// Keep waiting
					write_state	<= 1'b1;
					write			<= 1;
				end
				else begin
					// Write done
					write_state	<= 1'b0;
					write			<= 0;
					write_addr	<= write_addr + 4;
				end
			end
		endcase
	end
end





// Read state machine
always @(posedge ctrl_clk) begin
	if (!reset_n) begin
		read_state	<= 0;
		read			<= 0;
		read_addr	<= 'd0;
	end
	else begin
		case (read_state)
			1'b0: begin
				if (read_init == 1) begin
					read_state	<= 1'b1;
					read			<= 1;
				end
				else begin
					read_state	<= 1'b0;
					read			<= 0;
				end
				moValid		<= 0;
			end
			1'b1: begin
				if (read_waitrequest == 1) begin
					read_state	<= 1'b1;
					read			<= 1;
					moValid		<= 0;					
				end
				else begin
					// Read done, ready for the next read
					read_state	<= 1'b0;
					read			<= 0;
					moValid		<= 1;
					read_addr	<= read_addr + 4;
				end
			end
		endcase
	end
end
*/

	
	
	
endmodule
