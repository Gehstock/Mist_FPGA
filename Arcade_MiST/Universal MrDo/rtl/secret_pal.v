
// PAL16R6 (IC U001)

// no feedback used so a 128 byte lookup table could work too.

module secret_pal
(
	input        clk,
	input        clk_en,
	input  [7:0] din,
	output [7:0] dout
);

wire    [9:2]   i ;
reg     [19:12] r ;

// data bus d7 (msb) is pin 2 so reverse input bit order
assign i =  {din[0],din[1],din[2],din[3],din[4],din[5],din[6],din[7]};  

assign dout = r ;

wire t1 =   i[2] & ~i[3] &  i[4] & ~i[5] & ~i[6] & ~i[8] &  i[9] ;
wire t2 =  ~i[2] & ~i[3] &  i[4] &  i[5] & ~i[6] &  i[8] & ~i[9] ;
wire t3 =   i[2] &  i[3] & ~i[4] & ~i[5] &  i[6] & ~i[8] &  i[9] ;
wire t4 =  ~i[2] &  i[3] &  i[4] & ~i[5] &  i[6] &  i[8] &  i[9] ;


always @(posedge clk) begin

	if (clk_en) begin
    // pal output is registered clocked by pin 1 connected to (TRAM WE) $8800-$8fff
    // pal OE is enabled by reading address $9803 (SECRE)
    
    r[12] <= 0;
    
    //  /rf13 := i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
    r[13] <= ~ ( t1 );
    
    //  /rf14 := /i2 & /i3 & i4 & i5 & /i6 & i8 & /i9 + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
    r[14] <= ~ ( t2 | t1 ); 

    //  /rf15 := i2 & i3 & /i4 & /i5 & i6 & /i8 & i9 + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
    r[15] <= ~ ( t3 | t1 ); 

    //  /rf16 := i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
    r[16] <= ~ ( t1 );
    
    // /rf17 := i2 & i3 & /i4 & /i5 & i6 & /i8 & i9 + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
    r[17] <= ~ ( t3 | t1 ); 
    
    //  /rf18 := /i2 & i3 & i4 & /i5 & i6 & i8 & i9   + i2 & i3 & /i4 & /i5 & i6 & /i8 & i9
    r[18] <= ~ ( t4 | t3 ); 
    
    r[19] <= 0;
    end
end

endmodule
/*

/rf13 := i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
rf13.oe = OE

/rf14 := /i2 & /i3 & i4 & i5 & /i6 & i8 & /i9 + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
rf14.oe = OE

/rf15 := i2 & i3 & /i4 & /i5 & i6 & /i8 & i9  + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
rf15.oe = OE

/rf16 := i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
rf16.oe = OE

/rf17 := i2 & i3 & /i4 & /i5 & i6 & /i8 & i9  + i2 & /i3 & i4 & /i5 & /i6 & /i8 & i9
rf17.oe = OE

/rf18 := /i2 & i3 & i4 & /i5 & i6 & i8 & i9   + i2 & i3 & /i4 & /i5 & i6 & /i8 & i9
rf18.oe = OE

*/