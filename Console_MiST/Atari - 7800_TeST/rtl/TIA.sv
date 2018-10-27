/* Atari on an FPGA
 Masters of Engineering Project
 Cornell University, 2007
 Daniel Beer
 TIA.v
 Redesign of the Atari TIA chip. Provides the Atari with video generation,
 sound generation and I/O.
 */
 `timescale 1ns / 1ps
 
`include "tia.vh"
module TIA(A, // Address bus input
	   Din, // Data bus input
	   Dout, // Data bus output
	   CS_n, // Active low chip select input
	   CS, // Chip select input
	   R_W_n, // Active low read/write input
	   RDY, // CPU ready output
	   MASTERCLK, // 3.58 Mhz pixel clock input
	   CLK2, // 1.19 Mhz bus clock input
	   idump_in, // Dumped I/O
	   Ilatch, // Latched I/O
	   HSYNC, // Video horizontal sync output
	   HBLANK, // Video horizontal blank output
	   VSYNC, // Video vertical sync output
	   VBLANK, // Video vertical sync output
	   COLOROUT, // Indexed color output
	   RES_n, // Active low reset input
	   AUD0, //audio pin 0
	   AUD1, //audio pin 1
	   audv0, //audio volume for use with external xformer module
	   audv1); //audio volume for use with external xformer module
   input [5:0] A;
   input [7:0] Din;
   output [7:0] Dout;
   input [2:0] 	CS_n;
   input 	CS;
   input 	R_W_n;
   output 	RDY;
   input 	MASTERCLK;
   input 	CLK2;
   input [1:0] 	Ilatch;
   input [3:0] 	idump_in;
   output 	HSYNC, HBLANK;
   output 	VSYNC, VBLANK;
   output [7:0] COLOROUT;
   input 	RES_n;
   output AUD0, AUD1;
   output reg [3:0] audv0, audv1;
   // Data output register
   reg [7:0] 	Dout;
   // Video control signal registers
   wire 	HSYNC;
   reg 		VSYNC, VBLANK;
   // Horizontal pixel counter
   reg [7:0] 	hCount;
   reg [3:0] 	hCountReset;
   reg clk_30;
   reg [7:0] clk_30_count;
   
   wire [3:0] Idump;
   
   // Pixel counter update
   always @(posedge MASTERCLK)
     begin
	// Reset operation
	if (~RES_n) begin
	   hCount <= 8'd0;
	   hCountReset[3:1] <= 3'd0;
	   clk_30 <= 0;
	   clk_30_count <= 0;
	   latchedInputs <= 2'b11;
	end
	else begin
	   if (inputLatchReset)
          latchedInputs <= 2'b11;
       else
          latchedInputs <= latchedInputs & Ilatch;
	
	   if (clk_30_count == 57) begin
          clk_30 <= ~clk_30;
          clk_30_count <= 0;
       end else begin
          clk_30_count <= clk_30_count + 1;
       end
	   // Increment the count and reset if necessary
	   if ((hCountReset[3]) ||(hCount == 8'd227))
	      hCount <= 8'd0;
	   else
	      hCount <= hCount + 8'd1;
	      // Software resets are delayed by three cycles
	      hCountReset[3:1] <= hCountReset[2:0];
	   end
   end
   assign HSYNC = (hCount >= 8'd20) && (hCount < 8'd36);
   assign HBLANK = (hCount < 8'd68);
   // Screen object registers
   // These registers are set by the software and used to generate pixels
   reg [7:0] player0Pos, player1Pos, missile0Pos, missile1Pos, ballPos;
   reg [4:0] player0Size, player1Size;
   reg [7:0] player0Color, player1Color, ballColor, pfColor, bgColor;
   reg [3:0] player0Motion, player1Motion, missile0Motion, missile1Motion,
	     ballMotion;
   reg 	     missile0Enable, missile1Enable, ballEnable, R_ballEnable;
   reg [1:0] ballSize;
   reg [19:0] pfGraphic;
   reg [7:0]  player0Graphic, player1Graphic;
   reg [7:0]  R_player0Graphic, R_player1Graphic;
   reg 	      pfReflect, player0Reflect, player1Reflect;
   reg 	      prioCtrl;
   reg 	      pfColorCtrl;
   reg [14:0] collisionLatch;
   reg 	      missile0Lock, missile1Lock;
   reg 	      player0VertDelay, player1VertDelay, ballVertDelay;
   reg [3:0]  audc0, audc1;
   reg [4:0]  audf0, audf1;
   // Pixel number calculation
   wire [7:0] pixelNum;
   
   
   //audio control
      audio audio_ctrl(.AUDC0(audc0), 
                       .AUDC1(audc1),
                       .AUDF0(audf0), 
                       .AUDF1(audf1),
                       .CLK_30(clk_30), //30khz clock
                       .AUD0(AUD0),
                       .AUD1(AUD1));
   
   assign pixelNum = (hCount >= 8'd68) ? (hCount - 8'd68) : 8'd227;
   
   // Pixel tests. For each pixel and screen object, a test is done based on the
   // screen objects register to determine if the screen object should show on that
   // pixel. The results of all the tests are fed into logic to pick which displayed
   // object has priority and color the pixel the color of that object.
   // Playfield pixel test
   wire [5:0] pfPixelNum;
   wire       pfPixelOn, pfLeftPixelVal, pfRightPixelVal;
   assign pfPixelNum = pixelNum[7:2];
   assign pfLeftPixelVal = pfGraphic[pfPixelNum];
   assign pfRightPixelVal = (pfReflect == 1'b0)? pfGraphic[pfPixelNum - 6'd20]:
			    pfGraphic[6'd39 - pfPixelNum];
   assign pfPixelOn = (pfPixelNum < 6'd20)? pfLeftPixelVal : pfRightPixelVal;
   // Player 0 sprite pixel test
   wire       pl0PixelOn;
   wire [7:0] pl0Mask, pl0MaskDel;
   assign pl0MaskDel = (player0VertDelay)? R_player0Graphic : player0Graphic;
   assign pl0Mask = (!player0Reflect)? pl0MaskDel : {pl0MaskDel[0], pl0MaskDel[1],
						     pl0MaskDel[2], pl0MaskDel[3],
						     pl0MaskDel[4], pl0MaskDel[5],
						     pl0MaskDel[6], pl0MaskDel[7]};
   objPixelOn player0_test(pixelNum, player0Pos, player0Size[2:0], pl0Mask, pl0PixelOn);
   // Player 1 sprite pixel test
   wire       pl1PixelOn;
   wire [7:0] pl1Mask, pl1MaskDel;
   assign pl1MaskDel = (player1VertDelay)? R_player1Graphic : player1Graphic;
   assign pl1Mask = (!player1Reflect)? pl1MaskDel : {pl1MaskDel[0], pl1MaskDel[1],
						     pl1MaskDel[2], pl1MaskDel[3],
						     pl1MaskDel[4], pl1MaskDel[5],
						     pl1MaskDel[6], pl1MaskDel[7]};
   objPixelOn player1_test(pixelNum, player1Pos, player1Size[2:0], pl1Mask, pl1PixelOn);
   // Missile 0 pixel test
   wire       mis0PixelOn, mis0PixelOut;
   wire [7:0] mis0ActualPos;
   reg [7:0]  mis0Mask;
   always @(player0Size)
     begin
	case(player0Size[4:3])
	  2'd0: mis0Mask <= 8'h01;
	  2'd1: mis0Mask <= 8'h03;
	  2'd2: mis0Mask <= 8'h0F;
	  2'd3: mis0Mask <= 8'hFF;
	endcase
     end
   assign mis0ActualPos = (missile0Lock)? player0Pos : missile0Pos;
   objPixelOn missile0_test(pixelNum, mis0ActualPos, player0Size[2:0], mis0Mask, mis0PixelOut);
   assign mis0PixelOn = mis0PixelOut && missile0Enable;
   // Missile 1 pixel test
   wire mis1PixelOn, mis1PixelOut;
   wire [7:0] mis1ActualPos;
   reg [7:0]  mis1Mask;
   always @(player1Size)
     begin
	case(player1Size[4:3])
	  2'd0: mis1Mask <= 8'h01;
	  2'd1: mis1Mask <= 8'h03;
	  2'd2: mis1Mask <= 8'h0F;
	  2'd3: mis1Mask <= 8'hFF;
	endcase
     end
   assign mis1ActualPos = (missile1Lock)? player1Pos : missile1Pos;
   objPixelOn missile1_test(pixelNum, mis1ActualPos, player1Size[2:0], mis1Mask, mis1PixelOut);
   assign mis1PixelOn = mis1PixelOut && missile1Enable;
   // Ball pixel test
   wire ballPixelOut, ballPixelOn, ballEnableDel;
   reg [7:0] ballMask;
   always @(ballSize)
     begin
	case(ballSize)
	  2'd0: ballMask <= 8'h01;
	  2'd1: ballMask <= 8'h03;
	  2'd2: ballMask <= 8'h0F;
	  2'd3: ballMask <= 8'hFF;
	endcase
     end
   objPixelOn ball_test(pixelNum, ballPos, 3'd0, ballMask, ballPixelOut);
   assign ballEnableDel = ((ballVertDelay)? R_ballEnable : ballEnable);
   assign ballPixelOn = ballPixelOut && ballEnableDel;
   // Playfield color selection
   // The programmer can select a unique color for the playfield or have it match
   // the player's sprites colors
   reg [7:0] pfActualColor;
   always @(pfColorCtrl, pfColor, player0Color, player1Color, pfPixelNum)
     begin
	if (pfColorCtrl)
	  begin
	     if (pfPixelNum < 6'd20)
	       pfActualColor <= player0Color;
	     else
	       pfActualColor <= player1Color;
	  end
	else
	  pfActualColor <= pfColor;
     end
   // Final pixel color selection
   reg [7:0] pixelColor;
   assign COLOROUT = (HBLANK)? 8'b0 : pixelColor;
   // This combinational logic uses a priority encoder like structure to select
   // the highest priority screen object and color the pixel.
   always @(prioCtrl, pfPixelOn, pl0PixelOn, pl1PixelOn, mis0PixelOn, mis1PixelOn,
	    ballPixelOn, pfActualColor, player0Color, player1Color, bgColor)
     begin
	// Show the playfield behind the players
	if (!prioCtrl)
	  begin
	     if (pl0PixelOn || mis0PixelOn)
	       pixelColor <= player0Color;
	     else if (pl1PixelOn || mis1PixelOn)
	       pixelColor <= player1Color;
	     else if (pfPixelOn)
	       pixelColor <= pfActualColor;
	     else
	       pixelColor <= bgColor;
	  end
	// Otherwise, show the playfield in front of the players
	else begin
	   if (pfPixelOn)
	     pixelColor <= pfActualColor;
	   else if (pl0PixelOn || mis0PixelOn)
	     pixelColor <= player0Color;
	   else if (pl1PixelOn || mis1PixelOn)
	     pixelColor <= player1Color;
	   else
	     pixelColor <= bgColor;
	end
     end
   // Collision register and latching update
   wire [14:0] collisions;
   reg 	       collisionLatchReset;
   assign collisions = {pl0PixelOn && pl1PixelOn, mis0PixelOn && mis1PixelOn,
			ballPixelOn && pfPixelOn,
			mis1PixelOn && pfPixelOn, mis1PixelOn && ballPixelOn,
			mis0PixelOn && pfPixelOn, mis0PixelOn && ballPixelOn,
			pl1PixelOn && pfPixelOn, pl1PixelOn && ballPixelOn,
			pl0PixelOn && pfPixelOn, pl0PixelOn && ballPixelOn,
			mis1PixelOn && pl0PixelOn, mis1PixelOn && pl1PixelOn,
			mis0PixelOn && pl1PixelOn, mis0PixelOn && pl0PixelOn};
   always @(posedge MASTERCLK, posedge collisionLatchReset)
     begin
	if (collisionLatchReset)
	  collisionLatch <= 15'b000000000000000;
	else
	  collisionLatch <= collisionLatch | collisions;
     end
   // WSYNC logic
   // When a WSYNC is signalled by the programmer, the CPU ready line is lowered
   // until the end of a scanline
   reg wSync, wSyncReset;
   always @(hCount, wSyncReset)
     begin
	if (hCount == 8'd0)
	  wSync <= 1'b0;
	else if (wSyncReset && hCount > 8'd2)
	  wSync <= 1'b1;
     end
   assign RDY = ~wSync;
   // Latched input registers and update
   wire [1:0] latchedInputsValue;
   reg 	      inputLatchEnabled;
   reg inputLatchReset;
   reg [1:0]  latchedInputs;
   
   /*always_ff @(Ilatch, inputLatchReset)
     begin
	if (inputLatchReset)
	  latchedInputs <= 2'b11;
	else
	  latchedInputs <= latchedInputs & Ilatch;
     end*/
     
   assign latchedInputsValue = (inputLatchEnabled)? latchedInputs : Ilatch;
   // Dumped input registers update
   reg inputDumpEnabled;
   assign Idump = (inputDumpEnabled)? 4'b0000 : idump_in;
   // Software operations
   always @(posedge CLK2)
     begin
	// Reset operation
	if (~RES_n) begin
	   inputLatchReset <= 1'b0;
	   collisionLatchReset <= 1'b0;
	   hCountReset[0] <= 1'b0;
	   wSyncReset <= 1'b0;
	   Dout <= 8'b00000000;
	end
	// If the chip is enabled, execute an operation
	else if (CS) begin
	   // Software reset signals
	   inputLatchReset <= ({R_W_n, A[5:0]} == `VBLANK && Din[6] && !inputLatchEnabled);
	   collisionLatchReset <= ({R_W_n, A[5:0]} == `CXCLR);
	   hCountReset[0] <= ({R_W_n, A[5:0]} == `RSYNC);
	   wSyncReset <= ({R_W_n, A[5:0]} == `WSYNC) && !wSync;
	   case({R_W_n, A[5:0]})
	     // Collision latch reads
	     `CXM0P, `CXM0P_7800: Dout <= {collisionLatch[1:0],6'b000000};
	     `CXM1P, `CXM1P_7800: Dout <= {collisionLatch[3:2],6'b000000};
	     `CXP0FB, `CXP0FB_7800: Dout <= {collisionLatch[5:4],6'b000000};
	     `CXP1FB, `CXP1FB_7800: Dout <= {collisionLatch[7:6],6'b000000};
	     `CXM0FB, `CXM0FB_7800: Dout <= {collisionLatch[9:8],6'b000000};
	     `CXM1FB, `CXM1FB_7800: Dout <= {collisionLatch[11:10],6'b000000};
	     `CXBLPF, `CXBLPF_7800: Dout <= {collisionLatch[12],7'b0000000};
	     `CXPPMM, `CXPPMM_7800: Dout <= {collisionLatch[14:13],6'b000000};
	     // I/O reads
	     `INPT0, `INPT0_7800: Dout <= {Idump[0], 7'b0000000};
	     `INPT1, `INPT1_7800: Dout <= {Idump[1], 7'b0000000};
	     `INPT2, `INPT2_7800: Dout <= {Idump[2], 7'b0000000};
	     `INPT3, `INPT3_7800: Dout <= {Idump[3], 7'b0000000};
	     `INPT4, `INPT4_7800: Dout <= {latchedInputsValue[0], 7'b0000000};
	     `INPT5, `INPT5_7800: Dout <= {latchedInputsValue[1], 7'b0000000};
	     // Video signals
	     `VSYNC: VSYNC <= Din[1];
	     `VBLANK: begin
		inputLatchEnabled <= Din[6];
		inputDumpEnabled <= Din[7];
		VBLANK <= Din[1];
	     end
	     `WSYNC:;
	     `RSYNC:;
	     // Screen object register access
	     `NUSIZ0: player0Size <= {Din[5:4],Din[2:0]};
	     `NUSIZ1: player1Size <= {Din[5:4],Din[2:0]};
	     `COLUP0: player0Color <= Din;
	     `COLUP1: player1Color <= Din;
	     `COLUPF: pfColor <= Din;
	     `COLUBK: bgColor <= Din;
	     `CTRLPF: begin
		pfReflect <= Din[0];
		pfColorCtrl <= Din[1];
		prioCtrl <= Din[2];
		ballSize <= Din[5:4];
	     end
	     `REFP0: player0Reflect <= Din[3];
	     `REFP1: player1Reflect <= Din[3];
	     `PF0: pfGraphic[3:0] <= Din[7:4];
	     `PF1: pfGraphic[11:4] <= {Din[0], Din[1], Din[2], Din[3],
				       Din[4], Din[5], Din[6], Din[7]};
	     `PF2: pfGraphic[19:12] <= Din[7:0];
	     `RESP0: player0Pos <= pixelNum;
	     `RESP1: player1Pos <= pixelNum;
	     `RESM0: missile0Pos <= pixelNum;
	     `RESM1: missile1Pos <= pixelNum;
	     `RESBL: ballPos <= pixelNum;
	     // Audio controls 
	     `AUDC0: audc0 <= Din[3:0];
	     `AUDC1: audc1 <= Din[3:0];
	     `AUDF0: audf0 <= Din[4:0];
	     `AUDF1: audf1 <= Din[4:0];
	     `AUDV0: audv0 <= Din[3:0];
	     `AUDV1: audv1 <= Din[3:0];
	     // Screen object register access
	     `GRP0: begin
		player0Graphic <= {Din[0], Din[1], Din[2], Din[3],
				   Din[4], Din[5], Din[6], Din[7]};
		R_player1Graphic <= player1Graphic;
	     end
	     `GRP1: begin
		player1Graphic <= {Din[0], Din[1], Din[2], Din[3],
				   Din[4], Din[5], Din[6], Din[7]};
		R_player0Graphic <= player0Graphic;
		R_ballEnable <= ballEnable;
	     end
	     `ENAM0: missile0Enable <= Din[1];
	     `ENAM1: missile1Enable <= Din[1];
	     `ENABL: ballEnable <= Din[1];
	     `HMP0: player0Motion <= Din[7:4];
	     `HMP1: player1Motion <= Din[7:4];
	     `HMM0: missile0Motion <= Din[7:4];
	     `HMM1: missile1Motion <= Din[7:4];
	     `HMBL: ballMotion <= Din[7:4];
	     `VDELP0: player0VertDelay <= Din[0];
	     `VDELP1: player1VertDelay <= Din[0];
	     `VDELBL: ballVertDelay <= Din[0];
	     `RESMP0: missile0Lock <= Din[1];
	     `RESMP1: missile1Lock <= Din[1];
	     // Strobed line that initiates an object move
	     `HMOVE: begin
		player0Pos <= player0Pos - {{4{player0Motion[3]}},
					    player0Motion[3:0]};
		player1Pos <= player1Pos - {{4{player1Motion[3]}},
					    player1Motion[3:0]};
		missile0Pos <= missile0Pos - {{4{missile0Motion[3]}},
					      missile0Motion[3:0]};
		missile1Pos <= missile1Pos - {{4{missile1Motion[3]}},
					      missile1Motion[3:0]};
		ballPos <= ballPos - {{4{ballMotion[3]}},ballMotion[3:0]};
	     end
	     // Motion register clear
	     `HMCLR: begin
		player0Motion <= Din[7:4];
		player1Motion <= Din[7:4];
		missile0Motion <= Din[7:4];
		missile1Motion <= Din[7:4];
		ballMotion <= Din[7:4];
	     end
	     `CXCLR:;
	     default: Dout <= 8'b00000000;
	   endcase
	end
	// If the chip is not enabled, do nothing
	else begin
	   inputLatchReset <= 1'b0;
	   collisionLatchReset <= 1'b0;
	   hCountReset[0] <= 1'b0;
	   wSyncReset <= 1'b0;
	   Dout <= 8'b00000000;
	end
     end
endmodule
// objPixelOn module
// Checks the pixel number against a stretched and possibly duplicated version of the
// object.
module objPixelOn(pixelNum, objPos, objSize, objMask, pixelOn);
   input [7:0] pixelNum, objPos, objMask;
   input [2:0] objSize;
   output      pixelOn;
   wire [7:0]  objIndex;
   wire [8:0]  objByteIndex;
   wire        objMaskOn, objPosOn;
   reg 	       objSizeOn;
   reg [2:0]   objMaskSel;
   assign objIndex = pixelNum - objPos - 8'd1;
   assign objByteIndex = 9'b1 << (objIndex[7:3]);
   always @(objSize, objByteIndex)
     begin
	case (objSize)
	  3'd0: objSizeOn <= (objByteIndex & 9'b00000001) != 0;
	  3'd1: objSizeOn <= (objByteIndex & 9'b00000101) != 0;
	  3'd2: objSizeOn <= (objByteIndex & 9'b00010001) != 0;
	  3'd3: objSizeOn <= (objByteIndex & 9'b00010101) != 0;
	  3'd4: objSizeOn <= (objByteIndex & 9'b10000001) != 0;
	  3'd5: objSizeOn <= (objByteIndex & 9'b00000011) != 0;
	  3'd6: objSizeOn <= (objByteIndex & 9'b10010001) != 0;
	  3'd7: objSizeOn <= (objByteIndex & 9'b00001111) != 0;
	endcase
     end
   always @(objSize, objIndex)
     begin
	case (objSize)
	  3'd5: objMaskSel <= objIndex[3:1];
	  3'd7: objMaskSel <= objIndex[4:2];
	  default: objMaskSel <= objIndex[2:0];
	endcase
     end
   assign objMaskOn = objMask[objMaskSel];
   assign objPosOn = (pixelNum > objPos) && ({1'b0, pixelNum} <= {1'b0, objPos} + 9'd72);
   assign pixelOn = objSizeOn && objMaskOn && objPosOn;
endmodule 