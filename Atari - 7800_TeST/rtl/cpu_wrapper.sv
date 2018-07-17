`timescale 1ns / 1ps


module cpu_wrapper( clk, sysclk, reset, AB, DB_IN, DB_OUT, RD, IRQ, NMI, RDY, halt_b, pc_temp, core_latch_data);

input clk;              // CPU clock              
input sysclk;           // MARIA Clock                                                      
input reset;            // reset signal                                                                 
output [15:0] AB;       // address bus                                                                  
input  [7:0] DB_IN;     // data in,                                                                     
output [7:0] DB_OUT;    // data_out,                                                                    
output RD;              // read enable                                                                  
input IRQ;              // interrupt request                                                            
input NMI;              // non-maskable interrupt request                                               
input RDY;              // Ready signal. Pauses CPU when RDY=0                                          
input halt_b;
input core_latch_data;

output [15:0] pc_temp;

logic res;
logic rdy_in;
logic WE_OUT;
logic WE, holding;
logic [7:0] DB_hold, DB_into_cpu;

cpu core(.clk(clk), .reset(reset),.AB(AB),.DI(DB_hold),.DO(DB_OUT),.WE(WE_OUT),.IRQ(IRQ),.NMI(NMI),.RDY(rdy_in), .pc_temp(pc_temp), .res(res));

assign RD = ~(WE & ~res & ~reset);
assign WE = WE_OUT & rdy_in; //& ~core_latch_data;
//assign rdy_in = RDY & halt_b;
assign DB_hold = (holding) ? DB_hold : DB_IN;

//assign DB_into_cpu = (core_latch_data) ? DB_IN : DB_hold;
//assign DB_into_cpu = DB_hold;


/*always_ff @(posedge sysclk) begin
   if (core_latch_data & rdy_in) begin
      DB_hold <= DB_IN;
   end
end*/

/*always_ff @(posedge clk) begin
  if (rdy_in)
     DB_hold <= DB_IN;
end*/

/*always_ff @(posedge clk, posedge reset)
    if (reset)
        holding <= 1'b0;
    else
        holding <= ~rdy_in;*/
        
assign holding = ~rdy_in;

always_ff @(negedge clk, posedge reset)
    if (reset)
       rdy_in <= 1'b1;
    else if (halt_b & RDY)
        rdy_in <= 1'b1;
    else
        rdy_in <= 1'b0;
        
endmodule: cpu_wrapper