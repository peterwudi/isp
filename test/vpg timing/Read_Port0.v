// Read_Port0.v

// This file was auto-generated as part of a SOPC Builder generate operation.
// If you edit it your changes will probably be lost.
`include "vpg.h" //added by Peli 2010-07-19 for resolution selection

module Read_Port0 (
		output wire [31:0]  oADDRESS,      // avalon_master.address
		output wire         oCS,           //              .chipselect
		output wire         oREAD,         //              .read
		input  wire [255:0] iREAD_DATA,    //              .readdata
		input  wire         iREAD_VALID,   //              .readdatavalid
		output wire [7:0]   oBURST_COUNT,  //              .burstcount
		input  wire         iWAIT_REQ,     //              .waitrequest
		input  wire         iCLK,          //    clock_sink.clk
		input  wire         iRST_n,        //              .reset_n
		input  wire         iRST_n_F,      //   conduit_end.export
		input  wire         iCLK_F,        //              .export
		input  wire         iREAD_ACK_F,   //              .export
		output wire [31:0]  oREAD_DATA_F,  //              .export
		output wire         oEMPTY_F,      //              .export
		output wire         oPORT_READY_F, //              .export
		input  wire         iIP_INIT_DONE, //              .export
		output wire [3:0]   c_state,       //              .export
		output wire         error          //              .export
	);

	DDR2_SODIMM_Read_Port #(
		.DATA_WIDTH_BITS  (32),
		.STARTING_ADDRESS (0),
`ifdef SXGA_1280x1024p60 
		.PORT_SIZE_BYTES  (5242880),
`else
        .PORT_SIZE_BYTES  (1228800),
`endif
		.BURST_COUNT      (8)
	) read_port0 (
		.oADDRESS      (oADDRESS),      // avalon_master.address
		.oCS           (oCS),           //              .chipselect
		.oREAD         (oREAD),         //              .read
		.iREAD_DATA    (iREAD_DATA),    //              .readdata
		.iREAD_VALID   (iREAD_VALID),   //              .readdatavalid
		.oBURST_COUNT  (oBURST_COUNT),  //              .burstcount
		.iWAIT_REQ     (iWAIT_REQ),     //              .waitrequest
		.iCLK          (iCLK),          //    clock_sink.clk
		.iRST_n        (iRST_n),        //              .reset_n
		.iRST_n_F      (iRST_n_F),      //   conduit_end.export
		.iCLK_F        (iCLK_F),        //              .export
		.iREAD_ACK_F   (iREAD_ACK_F),   //              .export
		.oREAD_DATA_F  (oREAD_DATA_F),  //              .export
		.oEMPTY_F      (oEMPTY_F),      //              .export
		.oPORT_READY_F (oPORT_READY_F), //              .export
		.iIP_INIT_DONE (iIP_INIT_DONE), //              .export
		.c_state       (c_state),       //              .export
		.error         (error)          //              .export
	);

endmodule
