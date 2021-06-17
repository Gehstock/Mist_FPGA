`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Scott R. Gravenhorst
//           music.maker@gte.net
// Create Date:    09/10/2007
// Design Name:    SVF
// Module Name:    SVF
// Project Name:   State Variable Filter
// Description:    SVF with shared multiplier.
// 
// maximum Q = 23.464375  (q = 18'sb000001010111010010)
// maximum input amplitude = +/- 2047 (12 bits)
//
// Execution time = 4 clocks
//
//////////////////////////////////////////////////////////////////////////////////

module SVF( 
  clk,                          // system clock
  ena,                          // Tell the filter to go
  f,                            // f (not Hz, but usable to control frequency)
  q,                            // q (1/Q)
  DataIn,
  DataOut
  );

  input clk;  
  input ena;
  input signed [17:0] f;
  input signed [17:0] q;
  input signed [17:0] DataIn;    // Data input for one calculation cycle.
  output signed [17:0] DataOut;  // Data output from this calculation cycle.

  wire clk;
  wire ena;
  wire signed [17:0] f;
  wire signed [17:0] q;
  wire signed [17:0] DataIn;
  wire signed [17:0] DataOut;
  
  reg signed [35:0] z1 = 36'sd0;                // feedback #1
  reg signed [35:0] z2 = 36'sd0;                // feedback #2

  reg signed [17:0] mA = 18'd0;
  reg signed [17:0] mB = 18'd0;
  wire signed [35:0] mP;

  assign DataOut = z2 >>> 18;

// SVF state machine, shares a multiplier
  reg run = 1'b0;
  reg [2:0] state = 3'b0;

  always @ ( posedge clk )
    begin
    if ( ena == 1'b1 ) 
      begin
      run <= 1'b1;
      state <= 3'd0;
      mA <= z1 >>> 17;
      mB <= q;
      end
    else
      begin
      if ( run == 1'b1 )
        begin
        state <= state + 1;

        case ( state )
          
          3'd0:
            begin
            mA <= f;
            mB <= ((DataIn << 18) - mP - z2) >>> 17;  
            end
          
          3'd1:
            begin
            mA <= f;
            mB <= z1 >>> 17;

            z1 <= mP + z1;
            end

          3'd2:
            begin
            z2 <= mP + z2;

            run <= 1'b0;
            end


        endcase

        end
      end
    end
              
  MULT18X18SIO #(
    .AREG(0), // Enable the input registers on the A port (1=on, 0=off)
    .BREG(0), // Enable the input registers on the B port (1=on, 0=off)
    .B_INPUT("DIRECT"), // B cascade input "DIRECT" or "CASCADE"
    .PREG(0)  // Enable the input registers on the P port (1=on, 0=off)
    ) MULT0 (
    .BCOUT(), // 18-bit cascade output
    .P( mP ), // 36-bit multiplier output
    .A( mA ), // 18-bit multiplier input
    .B( mB ), // 18-bit multiplier input
    .BCIN(18'h00000),
    .CEA(1'b0), .CEB(1'b0), .CEP(1'b0), .CLK(1'b0), .RSTA(1'b0), .RSTB(1'b0), .RSTP(1'b0)
    );

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
// C source for working floating point SVF:

/*
while ( fgets( buf, BUFSIZE, stdin ) != NULL )
  {
  input = atof( buf );
    
  multq = fb1 * q;
      
  sum1 = input + (-multq) + (-output);        
  mult1 = f * sum1;

  sum2 = mult1 + fb1;      
  mult2 = f * fb1;

  sum3 = mult2 + fb2;
                  
  fb1 = sum2;
  fb2 = sum3;
                      
  output = sum3;
  printf( "%20.18lf\n", output );
  }
*/

endmodule
