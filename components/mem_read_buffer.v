
// Master read component
module mem_read_buffer_avalon_interface
(
	input				clk,
	input				reset,
	
	// Control inputs and outputs
	input	[ADDRESSWIDTH-1:0]	control_read_base,
	input	[ADDRESSWIDTH-1:0]	control_read_length,
	input								control_go,
	output							control_done,
	output							control_early_done,
	
	// user logic inputs and outputs
	input								user_read_buffer,
	input	[DATAWIDTH-1:0]		user_buffer_data,
	output							user_data_available,
	
	// Avalon-MM master signals
	output	[ADDRESSWIDTH-1:0]		master_address,
	output									master_read,
	output	[BYTEENABLEWIDTH-1:0] 	master_byteenable,
	input		[DATAWIDTH-1:0] 			master_readdata,
	input										master_readdatavalid,
	input										master_waitrequest
);

	parameter DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 30;
	parameter FIFODEPTH = 32;
	parameter FIFODEPTH_LOG2 = 5;
	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead
	
	// internal control signals
	wire								fifo_empty;
	reg	[ADDRESSWIDTH-1:0]	address;
	reg	[ADDRESSWIDTH-1:0]	length;
	reg	[FIFODEPTH_LOG2-1:0]	reads_pending;
	wire								increment_address;
	wire								too_many_pending_reads;
	reg								too_many_pending_reads_d1;
	wire	[FIFODEPTH_LOG2-1:0]	fifo_used;


	// master address logic 
	assign master_address = address;
	assign master_byteenable = -1;  // all ones, always performing word size accesses
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			address <= 0;
		end
		else
		begin
			if(control_go == 1)
			begin
				address <= control_read_base;
			end
			else if(increment_address == 1)
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
			if(control_go == 1)
			begin
				length <= control_read_length;
			end
			else if(increment_address == 1)
			begin
				length <= length - BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end	
	
	
	// control logic
	assign too_many_pending_reads = (fifo_used + reads_pending) >= (FIFODEPTH - 4);
	assign master_read = (length != 0) & (too_many_pending_reads_d1 == 0);
	assign increment_address = (length != 0) & (too_many_pending_reads_d1 == 0) & (master_waitrequest == 0);
	assign control_done = (reads_pending == 0) & (length == 0);  // master done posting reads and all reads have returned
	assign control_early_done = (length == 0);  // if you need all the pending reads to return then use 'control_done' instead of this signal

	
	always @ (posedge clk)
	begin
		if (reset == 1)
		begin
			too_many_pending_reads_d1 <= 0;
		end
		else
		begin
			too_many_pending_reads_d1 <= too_many_pending_reads;
		end
	end


	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			reads_pending <= 0;
		end
		else
		begin
			if(increment_address == 1)
			begin
				if(master_readdatavalid == 0)
				begin
					reads_pending <= reads_pending + 1;
				end
				else
				begin
					reads_pending <= reads_pending;  // a read was posted, but another returned
				end			
			end
			else
			begin
				if(master_readdatavalid == 0)
				begin
					reads_pending <= reads_pending;  // read was not posted and no read returned
				end
				else
				begin
					reads_pending <= reads_pending - 1;  // read was not posted but a read returned
				end				
			end
		end
	end

	
	// read data feeding user logic	
	assign user_data_available = !fifo_empty;
	scfifo the_master_to_user_fifo (
		.aclr (reset),
		.clock (clk),
		.data (master_readdata),
		.empty (fifo_empty),
		.q (user_buffer_data),
		.rdreq (user_read_buffer),
		.usedw (fifo_used),
		.wrreq (master_readdatavalid)
	);
	defparam the_master_to_user_fifo.lpm_width = DATAWIDTH;
	defparam the_master_to_user_fifo.lpm_numwords = FIFODEPTH;
	defparam the_master_to_user_fifo.lpm_showahead = "ON";
	defparam the_master_to_user_fifo.use_eab = (FIFOUSEMEMORY == 1)? "ON" : "OFF";
	defparam the_master_to_user_fifo.add_ram_output_register = "OFF";
	defparam the_master_to_user_fifo.underflow_checking = "OFF";
	defparam the_master_to_user_fifo.overflow_checking = "OFF";

endmodule

