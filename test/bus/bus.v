
module bus(
	//input					d5m_clk,
	input					ctrl_clk,
	//input					dvi_clk,
	
	input					reset_n,
	
	// Write side
	//input		[31:0]	iData,
	//input					iValid,
	//input		[18:0]	write_addr,	// multiple of 4
	
	input					read_init,
	//input		[18:0]	read_addr,	// multiple of 4
	output	[31:0]	oData,
	output				oValid
	
);


reg				read;
reg	[31:0]	read_addr;
wire				read_waitrequest;
reg				moValid;
reg				read_state;

reg				write;
wire				write_waitrequest;
reg	[31:0]	write_addr;	
reg				write_state;


// Test only
reg				iValid;


bus_sys u0 (
        .clk_clk                    (ctrl_clk),                    //   clk.clk
        .reset_reset_n              (reset_n),              // reset.reset_n
        
		  .write_write_addr (write_addr), // write.write_addr
        //.write_iData      (iData),      //      .iData
		  // This is testing!!!
		  .write_iData      (write_addr),
        .write_write      (write),      //      .write
        .write_waitrequest (write_waitrequest), //      .write_done
        
		  
		  .read_read_addr   (read_addr),   //  read.read_addr
        .read_read        (read),        //      .read
        .read_oData       (oData),       //      .oData
        .read_waitrequest   (read_waitrequest)    //      .wait_read
    );
	 
	 
assign oValid = moValid;

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

// Write state machine
// Streaming, no back pressure

always @(posedge ctrl_clk) begin
	if (!reset_n) begin
		write_state	<= 0;
		write			<= 0;
		write_addr	<= 'd0;
	end
	else begin
		// Test only
		iValid <= (write_addr <= 20);
	
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

	
	
	
endmodule
