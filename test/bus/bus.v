
module bus
(
	input					clk,
	input					reset_n,
	input		[31:0]	iData,
	//input					iValid,
	
	input					read,
	input		[18:0]	read_addr,
	output				read_done,
	output				oValid,
	output	[31:0]	oData,
	
	input					write,
	input		[18:0]	write_addr,
	output				write_done
	
);

//reg	[31:0]	read_count;
//reg	[31:0]	write_count;

bus_sys u0 (
        .clk_clk                    (clk),                    //   clk.clk
        .reset_reset_n              (reset_n),              // reset.reset_n
        
		  .write_write_addr (write_addr), // write.write_addr
        .write_iData      (iData),      //      .iData
        .write_write      (write),      //      .write
        .write_write_done (write_done), //      .write_done
        
		  
		  .read_read_addr   (read_addr),   //  read.read_addr
        .read_read        (read),        //      .read
        .read_oValid      (oValid),      //      .oValid
        .read_oData       (oData),       //      .oData
        .read_read_done   (read_done)    //      .wait_read
    );

//assign	user_write_buffer = (~write_buffer_full) & iValid & write_done;	

//assign	user_read_buffer = user_data_available & read_done;


//always @(negedge clk) begin
//	if (!reset_n) begin
//		read_count <= 0;
//		write_count <= 0;
//	end		
//		if (write) begin
//			write_count	<= write_count + 1;
//			write_addr	<= write_count;
//		end
//		if (read) begin
//			read_count	<= read_count + 1;
//			read_addr	<= read_count;
//		end		
//		
		// Pingpong read/write
//		if (count < 307200) begin
//			write_addr	<= count;
//			read_addr	<= count + 'd307200;
//		end
//		else if (count < 307200*2) begin
//			write_addr	<= count;
//			read_addr	<= count - 'd307200;
//		end
//		else begin
//			count			<= 0;
//			read_addr	<= 'd307200;
//			write_addr	<= 'd0;
//		end
//	end
//end


	
	
	
	
	
	
	
endmodule
