
module bus
(
	input					clk,
	input	[31:0]		iData,
	input					iValid,
	input					reset_n,
	input					read,
	input					write,
	
	input					user_write_buffer,
	input					user_read_buffer,
	
	output				write_ctrl_done,
	output				read_ctrl_done,
	output				write_buffer_full,
	output				user_data_available,
	output	[31:0]	oData
);



reg	[19:0]	read_addr;

wire				read_early_done;
reg	[19:0]	write_addr;


reg	[31:0]	read_count;
reg	[31:0]	write_count;

bus_sys u0 (
        .clk_clk                    (clk),                    //   clk.clk
        .reset_reset_n              (reset_n),              // reset.reset_n
        .read_control_read_base     (read_addr),     //  read.control_read_base
        .read_control_read_length   ('d4),   //      .control_read_length
        .read_control_go            (read),            //      .control_go
        .read_control_done          (read_ctrl_done),          //      .control_done
        .read_control_early_done    (read_early_done),    //      .control_early_done
        .read_user_read_buffer      (user_read_buffer),      //      .user_read_buffer
        .read_user_buffer_data      (oData),      //      .user_buffer_data
        .read_user_data_available   (user_data_available),   //      .user_data_available
		  
		  
        .write_control_write_base   (write_addr),   // write.control_write_base
        .write_control_write_length ('d4), //      .control_write_length
        .write_control_go           (write),           //      .control_go
        .write_control_done         (write_ctrl_done),         //      .control_done
        .write_user_write_buffer    (user_write_buffer),    //      .user_write_buffer
        .write_user_buffer_data     (iData),     //      .user_buffer_data
        .write_user_buffer_full     (write_buffer_full)      //      .user_buffer_full
    );

//assign	user_write_buffer = (~write_buffer_full) & iValid & write_done;	

//assign	user_read_buffer = user_data_available & read_done;


always @(negedge clk) begin
	if (!reset_n) begin
		read_count <= 0;
		write_count <= 0;
	end
	else begin
		if (write) begin
			write_count	<= write_count + 1;
			write_addr	<= write_count;
		end
		if (read) begin
			read_count	<= read_count + 1;
			read_addr	<= read_count;
		end		
		
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
	end
end


	
	
	
	
	
	
	
endmodule
