
// Master write component
module mem_write_buffer_avalon_interface (
	input				clk,
	input				reset,
	
	// Control inputs and outputs
	input	[29:0]	control_write_base,
	input	[29:0]	control_write_length,
	input								control_go,
	output							control_done,
	
	// user logic inputs and outputs
	input								user_write_buffer,
	input	[31:0]		user_buffer_data,
	output							user_buffer_full,
	
	// Avalon-MM master signals
	output	[29:0]		master_address,
	output									master_write,
	output	[3:0] 	master_byteenable,
	output	[31:0] 			master_writedata,
	input										master_waitrequest
);

	parameter DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 30;		// 1GB
	parameter FIFODEPTH = 32;
	parameter FIFODEPTH_LOG2 = 5;
	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead
	
	// internal control signals
	reg	[ADDRESSWIDTH-1:0]	address;  // this increments for each word
	reg	[ADDRESSWIDTH-1:0]	length;
	
	// this increments the 'address' register when write is asserted and waitrequest is de-asserted
	wire 								increment_address;
	wire								read_fifo;
	wire								user_buffer_empty;

	
	// master word increment counter
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			address <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				address <= control_write_base;
			end
			else if (increment_address == 1)
			begin
				address <= address + BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end


	// master length logic
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			length <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				length <= control_write_length;
			end
			else if (increment_address == 1)
			begin
				length <= length - BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end



	// controlled signals going to the master/control ports
	assign master_address = address;
	assign master_byteenable = -1;  // all ones, always performing word size accesses
	assign control_done = (length == 0);
	assign master_write = (user_buffer_empty == 0) & (control_done == 0);

	assign increment_address = (user_buffer_empty == 0) & (master_waitrequest == 0) & (control_done == 0);
	assign read_fifo = increment_address;

	// write data feed by user logic
	scfifo the_user_to_master_fifo (
		.aclr (reset),
		.clock (clk),
		.data (user_buffer_data),
		.full (user_buffer_full),
		.empty (user_buffer_empty),
		.q (master_writedata),
		.rdreq (read_fifo),
		.wrreq (user_write_buffer)
	);
	defparam the_user_to_master_fifo.lpm_width = DATAWIDTH;
	defparam the_user_to_master_fifo.lpm_numwords = FIFODEPTH;
	defparam the_user_to_master_fifo.lpm_showahead = "ON";
	defparam the_user_to_master_fifo.use_eab = (FIFOUSEMEMORY == 1)? "ON" : "OFF";
	defparam the_user_to_master_fifo.add_ram_output_register = "OFF";
	defparam the_user_to_master_fifo.underflow_checking = "OFF";
	defparam the_user_to_master_fifo.overflow_checking = "OFF";

endmodule

