module ga21_tb;

reg clk;
reg buf_cs;
reg [10:0] addr;
reg reg_cs;
reg reset;
reg wr;

GA21 ga21( .clk(clk), .ce(1), .reset(reset), .buf_cs(0), .wr(wr), .reg_cs(reg_cs), .addr(addr));

always begin
    clk = 1'b1;
    #1;
    clk = 1'b0;
    #1;
end

initial begin
    reset = 1;
    buf_cs = 0;
    reg_cs = 0;
    wr = 0;
    #5;
    reset = 0;
    #5;

    addr = 'h9008 >> 1;
    reg_cs = 1;
    wr = 1;
    #2;

    reg_cs = 0;
    wr = 0;
    #1000000;
    $stop;
end

endmodule