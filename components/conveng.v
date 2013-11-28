`include "params.v"

module conveng
(
	input					clk,
	input					reset,

	input		[255:0]	iData,
	input					iValid,
	input		[2:0]		mode,
	
	input		[15:0]	iWidth,
	input		[15:0]	iHeight,
	
	output				oReq,
	output				oAddress,
	output	[23:0]	oData,
	output				oValid,
	output				oDone
);
localparam	pipelineDepth	= 9;
localparam	rfwidth			= 64;

localparam signed [49*16-1:0] h = {
	-16'sd1, -16'sd1, -16'sd1, 16'sd0, 16'sd0, 16'sd0, 16'sd0,
	-16'sd1,  16'sd9, -16'sd1, 16'sd0, 16'sd0, 16'sd0, 16'sd0,
	-16'sd1, -16'sd1, -16'sd1, 16'sd0, 16'sd0, 16'sd0, 16'sd0,
	16'sd0,	16'sd0,  16'sd0,	16'sd0, 16'sd0, 16'sd0, 16'sd0,
	16'sd0,  16'sd0,  16'sd0,	16'sd0, 16'sd0, 16'sd0, 16'sd0,
	16'sd0,	16'sd0,  16'sd0,	16'sd0, 16'sd0, 16'sd0, 16'sd0,
	16'sd0,  16'sd0,  16'sd0,	16'sd0, 16'sd0, 16'sd0, 16'sd0
};

reg	[15:0]	width, height;
reg	[3:0]		kernelSize;
reg	[3:0]		boundaryWidth;
reg	[4:0]		totalBoundry;
reg	[31:0]	totalPixels;
reg	[15:0]	totalStripes;
reg	[15:0]	lastStripeWidth;
reg	[15:0]	stripeOffset;
reg	[1:0]		constState;

// Register constants
always @(posedge clk) begin
	if (reset) begin
		constState			<= 'd0;
		width					<= 'b0;
		height				<= 'b0;
		kernelSize			<= 'b0;
		boundaryWidth		<= 'b0;
		totalBoundry		<= 'b0;
		totalPixels			<= 'b0;
		totalStripes		<= 'b0;
		lastStripeWidth	<= 'b0;
		stripeOffset		<= 'b0;
	end
	else begin
		case (constState)
			'd0: begin
				// Init, reset all consts
				width					<= 'b0;
				height				<= 'b0;
				kernelSize			<= 'b0;
				boundaryWidth		<= 'b0;
				totalBoundry		<= 'b0;
				totalPixels			<= 'b0;
				totalStripes		<= 'b0;
				lastStripeWidth	<= 'b0;
				constState			<= 'd1;
			end
			'd1: begin
				// Copy consts
				width			<= iWidth;
				height		<= iHeight;
				
				case (height):
					'd1080: begin
						totalPixels		<= 'd2073600;
					end
					'd240: begin
						totalPixels		<= 'd86400;
					end
					default: begin
						totalPixels		<= 'd0;
					end
				endcase
				
				// stripeOffset	= 64 - 2*boundaryWidth
				// totalStripes	= ceil(width/stripeOffset)
				// Last stripe width = width%stripeOffset (if 0 then stripeOffset)
				case (mode):
					`pattern_3x3: begin
						kernelSize			<= 'd3;
						boundaryWidth		<= 'd1;
						totalBoundry		<= 'd2;
						stripeOffset		<= 'd62;
						totalStripes		<= (height == 1080)? 'd31 :'d6;
						lastStripeWidth	<= (height == 1080)? 'd60 :'d10;
					end
					`pattern_5x5: begin
						kernelSize			<= 'd5;
						boundaryWidth		<= 'd2;
						totalBoundry		<= 'd4;
						stripeOffset		<= 'd60;
						totalStripes		<= (height == 1080)? 'd32 :'d6;
						lastStripeWidth	<= (height == 1080)? 'd0  :'d20;
					end
					`pattern_7x7: begin
						kernelSize			<= 'd7;
						boundaryWidth		<= 'd3;
						totalBoundry		<= 'd6;
						stripeOffset		<= 'd58;
						totalStripes		<= (height == 1080)? 'd34 :'d6;
						lastStripeWidth	<= (height == 1080)? 'd6  :'d30;
					end
					default: begin
						kernelSize		<= 'd0;
						boundaryWidth	<= 'd0;
						totalBoundry	<= 'd0;
						stripeOffset	<= 'd0;
						totalStripes	<= 'd0;
					end
				endcase
				
				constState	<= 'd2;
			end
			'd2: begin
				// Finished copying consts, stay here until reset
			end
			default: begin
				constState			<= 'd0;
				width					<= 'b0;
				height				<= 'b0;
				kernelSize			<= 'b0;
				boundaryWidth		<= 'b0;
				totalBoundry		<= 'd0;
				totalPixels			<= 'b0;
				lastStripeWidth	<= 'b0;
				totalStripes		<= 'b0;
			end
		endcase
	end
end			

reg				colShift;
reg				rowShift;
reg	[255:0]	rf	[6:0];

shift2drf shift2drf
(
	.clk(clk),
	.reset(reset),
	.iData(r_iData),
	.mode(mode),
	.colShift(colShift),
	.rowShift(rowShift),
	
	.rf(rf)
);
reg				r_iValid;
reg	[255:0]	r_iData;
reg	[3:0]		ctrlState;

reg				valid;
reg				img_done;
reg	[15:0]	rowCnt;
reg	[15:0]	colCnt;
reg	[31:0]	pixelCnt;
reg	[15:0]	stripeCnt;
reg	[15:0]	stripeWidth;
reg	[15:0]	stripeStart;
reg	[31:0]	moAddress;
reg				req;
reg				o_valid_pipeline[pipelineDepth-1:0];
reg				o_done_pipeline[pipelineDepth-1:0];

// Control
always @(posedge clk) begin
	if (reset) begin
		ctrlState		<= 'd0;
		req				<= 0;
		colShift			<= 0;
		rowShift			<= 0;
		valid				<= 0;
		rowCnt			<= 'b0;
		colCnt			<= 'b0;
		pixelCnt			<= 'b0;
		stripeCnt		<=	'b0;
		stripeStart		<= 'b0;
		stripeWidth		<= 'b0;
		moAddress		<= 'b0;
		r_iValid			<= 'b0;
		r_iData			<= 'b0;
	end
	else begin
		img_done	<= (pixelCnt == totalPixels) ? 1 : 0;
		
		case (ctrlState):
			'd0: begin
				// Init state
				req			<= 1;
				ctrlState	<= 'd1;
				colShift		<= 0;
				rowShift		<= 0;
				valid			<= 0;
				rowCnt		<= 'b0;
				colCnt		<= 'b0;
				pixelCnt		<= 'b0;
				stripeCnt	<=	'b0;
				stripeStart	<= 'b0;
				stripeWidth	<= 'b0;
				r_iValid		<= 'b0;
				r_iData		<= 'b0;
			end
			'd1: begin
				req			<= 0;
				// Wait for iValid
				if (iValid == 1) begin
					// Cache iData
					r_iData		<= iData;
					ctrlState	<= 'd2;
				end
				else begin
					// Wait
					ctrlState	<= 'd1;
				end
			end
			'd2: begin
				// Row shift into the 2D RF
				rowShift		<= 1;
				
				// Update address to get the next row
				moAddress	<= moAddress + width;
				
				rowCnt		<= rowCnt + 1;
				
				// Check if have enough rows
				if (rowCnt	< kernelSize-1) begin
					// At least need another row, go to
					// state 1 to request another row
					ctrlState	<= 'd1;
					req			<= 1;
				end
				else begin
					// Have enough rows, ready to process
					req			<= 0;
					ctrlState	<= 'd3;
					
					// Set stripeWidth
					if (stripeCnt < totalStripes - 1) begin
						// Not the last stripe
						// stripeOffset valid data
						stripeWidth	<= stripeOffset;
					end
					else begin
						// Last stripe
						// lastStripeWidth valid data
						stripeWidth	<= lastStripeWidth;
					end					
				end
			end
			'd3: begin
				// Start to process
				req			<= 0;
				
				if (colCnt < stripeWidth - 1) begin
					// Shift horizontally to get new data.
					// Only shift stripeWidth - 1 times
					colShift		<= 1;
					colCnt		<= colCnt + 1;
					// Set the valid signal and pass through the
					// delay pipeline
					valid			<= 1;
					
					if (pixelCnt < totalPixels - 1) begin
						// Count how many valid outputs has been processed.
						pixelCnt	<= pixelCnt + 1;
					end
					else begin
						pixelCnt	<= 'b0;
					end
					ctrlState	<= 'd3;
				end
				else begin
					// Shifts to the boundry now, the output is invalid
					valid			<= 0;
					colShift		<= 0;
					
					if (stripeCnt == totalStripes) begin
						// Last stripe, we're done, go to a wait state to
						// wait for reset.
						ctrlState	<= 'd5;
					end
					
					// Update new stripe address info
					stripeStart	<= stripeStart + stripeOffset;
					moAddress	<= stripeStart + stripeOffset;
					
					if (rowCnt	< height) begin
						// Haven't finished the stripe yet, need to do:
						//	(1) Maintain the 2D RF, i.e. shift everything
						// to align at the beginning.
						// (2) Get a new row
						// So go to a mainainance state 
						ctrlState	<= 'd4;
						
						// Set colCnt to kernelSize for the mainainance state 
						colCnt		<= kernelSize;
					end
					else begin
						// Already finished the strip, don't care what's
						// in the 2D RF, start a new stripe.
						req			<= 1;
						ctrlState	<= 'd1;
						colCnt		<= 0;
						stripeCnt	<= stripeCnt + 1;
					end
				end
			end
			'd4: begin
				// Need to shift kernelSize times horizontally to align
				// to the beginning of the row
				if (rowCnt	> 0) begin
					colShift 	<= 1;
					rowCnt		<= rowCnt - 1;
					ctrlState	<= 'd4;
				end
				else begin
					// Mainainance done, request new data, go to state 1
					// to wait and start a new stripe.
					req			<= 1;
					ctrlState	<= 'd1;
				end			
			end
			'd5: begin
				// Stay here until reset
			end
			default: begin
				req			<= 0;
				ctrlState	<= 'd0;
				colShift		<= 0;
				rowShift		<= 0;
				valid			<= 0;
				rowCnt		<= 'b0;
				colCnt		<= 'b0;
				pixelCnt		<= 'b0;
				stripeCnt	<=	'b0;
				stripeStart	<= 'b0;
				stripeWidth	<= 'b0;
				r_iValid		<= 'b0;
				r_iData		<= 'b0;
			end
		endcase
	end
end


// Reduction tree
// Multiplier outputs
wire	signed	[27:0] multRes [14:0];

// Leaf level (level 1)
reg	signed	[27:0] multlvl1 [12:0];

// Level 2
reg	signed	[28:0] multlvl2 [7:0];

// Level 3
reg	signed	[29:0] multlvl3 [3:0];

// Level 4
reg	signed	[30:0] multlvl4 [1:0];
reg	signed	[30:0] pattern_3x3_out_lvl4 [3:0];	

// Level 5
reg	signed	[31:0] out;
reg	signed	[30:0] pattern_3x3_out_lvl5 [3:0];
reg	signed	[30:0] pattern_5x5_out_lvl5 [1:0];


always @(posedge clk) begin
	if (reset) begin
		out	<= 'b0;
	end
	else if (valid) begin
		// Produce valid results
		// Level 5
		out	<= multlvl4[0] + multlvl4[1];
	end
end

reg unsigned	[7:0]		r_multIn	[14:0][3:0];
reg signed		[15:0]	r_coefIn	[14:0][3:0];

genvar i;
genvar j;
generate
	for (i = 0; i < 4; i = i + 1) begin: multIn
		always @(posedge clk) begin
			if (reset) begin
				for (j = 0; j < 15; j = j + 1) begin: multInReset
					multIn[j][i] = 'b0;
				end
			end
			else if (valid) begin
				multIn[0][i] <= rf[255-i*8:248-i*8][0];	//	00-03
				multIn[1][i] <= rf[255-i*8:248-i*8][1];	// 10-13
				multIn[2][i] <= rf[255-i*8:248-i*8][2];	// 20-23
		
				// 7x7: 50-53, otherwise: 01-04
				multIn[3][i] <= (mode==`pattern_7x7)?rf[255-i*8:248-i*8][5]:rf[247-i*8:240-i*8][0];
				// 7x7: 60-63, otherwise: 11-14
				multIn[4][i] <= (mode==`pattern_7x7)?rf[255-i*8:248-i*8][6]:rf[247-i*8:240-i*8][1];
				// 7x7: 63-66, otherwise: 21-24
				multIn[5][i] <= (mode==`pattern_7x7)?rf[231-i*8:224-i*8][6]:rf[247-i*8:240-i*8][2];
			
				// 3x3: 02-05, otherwise: 30-33
				multIn[6][i] <= (mode==`pattern_3x3)?rf[239-i*8:232-i*8][0]:rf[255-i*8:248-i*8][3];
				// 3x3: 12-15, otherwise: 40-43
				multIn[7][i] <= (mode==`pattern_3x3)?rf[239-i*8:232-i*8][1]:rf[255-i*8:248-i*8][4];
				// 3x3: 22-25, otherwise: 04-34
				multIn[8][i] <= (mode==`pattern_3x3)?rf[239-i*8:232-i*8][2]:rf[223:216][i];
			
				// 5x5: 31-34, otherwise: 03-06
				multIn[9][i] <= (mode==`pattern_5x5)?rf[247-i*8:240-i*8][3]:rf[231-i*8:224-i*8][0];
				// 5x5: 41-44, otherwise: 13-16
				multIn[10][i] <= (mode==`pattern_5x5)?rf[247-i*8:240-i*8][4]:rf[231-i*8:224-i*8][1];
				// 5x5: 05-35, otherwise: 23-26
				multIn[11][i] <= (mode==`pattern_5x5)?rf[215:208][i]:rf[231-i*8:224-i*8][2];	
		
				// 5x5: 43-46(only using 44), otherwise: 33-36
				multIn[12][i] <= (mode==`pattern_5x5)?rf[231-i*8:224-i*8][4]:rf[231-i*8:224-i*8][3];
				// 43-46
				multIn[13][i] <= rf[231-i*8:224-i*8][4];
				// 53-56
				multIn[14][i] <= rf[231-i*8:224-i*8][5];
			end
		end
	end
		
	for (i = 0; i < 4; i = i + 1) begin: coefIn
		always @(posedge clk) begin
			if (reset) begin
				for (j = 0; j < 15; j = j + 1) begin: coefInReset
					coefIn[j][i] = 'b0;
				end
			end
			else if (valid) begin
				// h[783:0], each row has 112 bits
				case (mode)
					`pattern_3x3: begin
						// 4 coefficints, the last one is 0 so don't care.
						coefIn[0][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[1][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[2][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						coefIn[3][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[4][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[5][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						coefIn[6][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[7][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[8][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						coefIn[9][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[10][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[11][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						coefIn[12][i] 	<= 'b0;											//	zero
						coefIn[13][i] 	<= 'b0;											// zero
						coefIn[14][i] 	<= 'b0;											// zero
					end
					`pattern_5x5: begin
						coefIn[0][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[1][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[2][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						coefIn[3][i]	<= h[783-i*16:768-i*16];					//	00-03
						coefIn[4][i]	<= h[783-i*16-112:768-i*16-112];			// 10-13
						coefIn[5][i]	<= h[783-i*16-112*2:768-i*16-112*2];	// 20-23
						
						coefIn[6][i]	<= h[783-i*16-112*3:768-i*16-112*3];	//	30-33
						coefIn[7][i]	<= h[783-i*16-112*4:768-i*16-112*4];	// 40-43
						coefIn[8][i]	<= h[719-112*i:704-112*i];					// 04-34
						coefIn[9][i]	<= h[783-i*16-112*3:768-i*16-112*3];	//	30-33
						coefIn[10][i]	<= h[783-i*16-112*4:768-i*16-112*4];	// 40-43
						coefIn[11][i]	<= h[703-112*i:688-112*i];					// 05-35
						
						coefIn[12][0] 	<= 'b0;
						coefIn[12][1] 	<= h[719-112*4:703-112*4];					// 44
						coefIn[12][2] 	<= 'b0;
						coefIn[12][3] 	<= 'b0;
						
						coefIn[13][0] 	<= 'b0;
						coefIn[13][1] 	<= 'b0;
						coefIn[13][2] 	<= h[719-112*4:703-112*4];					// 44
						coefIn[13][3] 	<= 'b0;
						
						coefIn[14][i] 	<= 'b0;											// zero
					end
					`pattern_7x7: begin
						// Set the last coef to 0
						coefIn[0][i]	<= (i != 3)? h[783-i*16:768-i*16] : 'b0;					//	00-03
						coefIn[1][i]	<= (i != 3)? h[783-i*16-112:768-i*16-112] :'b0;			// 10-13
						coefIn[2][i]	<= (i != 3)? h[783-i*16-112*2:768-i*16-112*2] :'b0;	// 20-23
						coefIn[3][i]	<= (i != 3)? h[783-i*16-112*3:768-i*16-112*3] :'b0;	//	30-33
						coefIn[4][i]	<= (i != 3)? h[783-i*16-112*4:768-i*16-112*4] :'b0;	// 40-43
						coefIn[6][i]	<= (i != 3)? h[783-i*16-112*5:768-i*16-112*5] :'b0;	//	50-53
						coefIn[7][i]	<= (i != 3)? h[783-i*16-112*6:768-i*16-112*6] :'b0;	// 60-63
						
						coefIn[8][i]	<= 'b0;																// zero
						
						coefIn[9][i]	<= h[735-i*16:720-i*16];										//	03-06
						coefIn[10][i]	<= h[735-i*16-112*1:720-i*16-112*1];						// 13-16
						coefIn[11][i]	<= h[735-i*16-112*2:720-i*16-112*2];						// 23-26
						coefIn[12][i] 	<= h[735-i*16-112*3:720-i*16-112*3];						//	33-36
						coefIn[13][i] 	<= h[735-i*16-112*4:720-i*16-112*4];						// 43-46
						coefIn[14][i] 	<= h[735-i*16-112*5:720-i*16-112*5];						// 53-56
						coefIn[5][i]	<= h[735-i*16-112*6:720-i*16-112*6];						// 63-66
					end
					default: begin
						coefIn[0][i] 	<= 'b0;
						coefIn[1][i] 	<= 'b0;
						coefIn[2][i] 	<= 'b0;
						coefIn[3][i] 	<= 'b0;
						coefIn[4][i] 	<= 'b0;
						coefIn[5][i] 	<= 'b0;
						coefIn[6][i] 	<= 'b0;
						coefIn[7][i] 	<= 'b0;
						coefIn[8][i] 	<= 'b0;
						coefIn[9][i] 	<= 'b0;
						coefIn[10][i] 	<= 'b0;
						coefIn[11][i] 	<= 'b0;
						coefIn[12][i] 	<= 'b0;
						coefIn[13][i] 	<= 'b0;
						coefIn[14][i] 	<= 'b0;
					end
				endcase;
			end
		end
	end
	
	for (i = 0; i < 15; i = i + 1) begin: mult
		multAdd_4_16x16 mult(
			.chainin(44'b0),
			.clock0(clk),
			.dataa_0(multIn[i][0]),
			.dataa_1(multIn[i][1]),
			.dataa_2(multIn[i][2]),
			.dataa_3(multIn[i][3]),
			.datab_0(coefIn[i][0]),
			.datab_1(coefIn[i][1]),
			.datab_2(coefIn[i][2]),
			.datab_3(coefIn[i][3]),
			.ena0(i_valid),
			.result(multRes[i]));
	end

	// Level 1
	for (i = 0; i < 15; i = i + 1) begin: lvl1
		always @(posedge clk) begin
			if (reset) begin
				multlvl1[i] <= 'b0;
			end
			else if (valid) begin
				multlvl1[i]	<=	multRes[i][27:0];
			end
		end
	end

	// Level 2
	for (i = 0; i < 8; i = i + 1) begin: lvl2
		always @(posedge clk) begin
			if (reset) begin
				multlvl2[i] 	<= 'b0;
			end
			else if (valid) begin
				multlvl2[0]		<= multlvl1[0] + multlvl1[1];
				multlvl2[1]		<= multlvl1[2];
				multlvl2[2]		<= multlvl1[6] + multlvl1[7];
				multlvl2[3]		<= multlvl1[8] + multlvl1[12];
				multlvl2[4]		<= multlvl1[3] + multlvl1[4];
				multlvl2[5]		<= multlvl1[5] + multlvl1[13];
				multlvl2[6]		<= multlvl1[9] + multlvl1[10];
				multlvl2[7]		<= multlvl1[11] + multlvl1[14];
			end
		end
	end
	
	// Level 3
	for (i = 0; i < 4; i = i + 1) begin: lvl3
		always @(posedge clk) begin
			if (reset) begin
				multlvl3[i] 	<= 'b0;
			end
			else if (valid) begin
				multlvl3[i]	<=	multlvl2[i*2]+multlvl2[i*2+1];
			end
		end
	end
	
	// Level 4
	for (i = 0; i < 2; i = i + 1) begin: lvl4
		always @(posedge clk) begin
			if (reset) begin
				multlvl4[i] 	<= 'b0;
			end
			else if (i_valid) begin
				multlvl4[i]	<=	multlvl3[i*2]+multlvl3[i*2+1];
			end
		end
	end
	
	for (i = 0; i < 4; i = i + 1) begin: lvl3
		always @(posedge clk) begin
			if (reset) begin
				pattern_3x3_out_lvl4[i] 	<= 'b0;
				pattern_3x3_out_lvl5[i] 	<= 'b0;
			end
			else if (valid) begin
				pattern_3x3_out_lvl4[i]	<=	multlvl3[i];
				pattern_3x3_out_lvl5[i]	<=	pattern_3x3_out_lvl4[i];
			end
		end
	end
	
	// Level 5
	for (i = 0; i < 2; i = i + 1) begin: lvl4
		always @(posedge clk) begin
			if (reset) begin
				pattern_5x5_out_lvl5[i] <= 'b0;
			end
			else if (i_valid) begin
				pattern_5x5_out_lvl5[i]	<=	multlvl4[i];
			end
		end
	end
	
	for (i = 0; i < pipelineDepth; i = i + 1) begin: valid/done
		always @(posedge clk) begin
			if (reset) begin
				o_valid_pipeline[i]	<= 1'b0;
				o_done_pipeline[i]	<= 1'b0;
			end
			else if (valid) begin
				if (i == 0) begin
					o_valid_pipeline[0]	<= 1'b0;
					o_done_pipeline[0]	<= 1'b0;
				end
				else begin
					o_valid_pipeline[i]	<= o_valid_pipeline[i-1];
					o_done_pipeline[i]	<= o_done_pipeline[i-1];
				end
			end
		end
	end
endgenerate


// Outputs
assign	oReq	= req




endmodule


module shift2drf
(
	input						clk,
	input						reset,
	input			[255:0]	iData,
	input						colShift,
	input						rowShift,
	input			[2:0]		mode,
	
	output reg	[255:0]	rf	[6:0]
);

localparam numCol			= 32;
localparam numRow			= 7;
localparam numBits		= 8;
localparam numBits3x3	= 8*4;

localparam rowSize		= numCol*numBits;

genvar i;
integer j;
generate
	for (i = 0; i < numRow; i = i+1)	begin: a
		always @(posedge clk) begin
			for (j = 0; j < rowSize; j = j+1)	begin: b
				if (reset) begin
					rf[i] <= 'b0;
				end
				else if (colShift) begin
					if (mode == `pattern_3x3) begin
						// 3x3 pattern shifts 4 pixels at a time
						rf[i][(j+numBits_3x3)%rowSize] <= rf[i][j];
					end
					else begin
						rf[i][(j+numBits)%rowSize]	<= rf[i][j];
					end
				end
				else if (rowShift) begin
					if (i < numRow - 1) begin
						rf[i] <= rf[i+1];
					end
					else begin
						rf[i] <= iData;
					end
				end
			end
		end
	end	
endgenerate


endmodule




