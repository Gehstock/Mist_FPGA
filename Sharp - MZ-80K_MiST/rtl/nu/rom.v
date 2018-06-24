module rom(clk, addr, data);
        input clk;
        input [10:0] addr;
        output [7:0] data;
        reg [7:0] data;
        always @(posedge clk) begin
                case (addr)
                        11'h000: data = 8'h21;
                        11'h001: data = 8'h00;
                        11'h002: data = 8'hd0;
                        11'h003: data = 8'h3e;
                        11'h004: data = 8'h00;
                        11'h005: data = 8'h77;
                        11'h006: data = 8'h23;
                        11'h007: data = 8'h3c;
                        11'h008: data = 8'h18;
                        11'h009: data = 8'hfb;
                        default: data = 8'hXX;
                endcase
        end
endmodule