

// 6502 BUS CONTROLLER

module CPU16(
  input             reset,
  input             clk,
  input             cen,
  input             SYNC,
  input             VB,
  input             RW,
  input      [15:0] ABI,     // from CPU
  output reg [15:0] ABO,     // to PCB
  input       [7:0] CPU_DBI, // from CPU
  output reg  [7:0] CPU_DBO, // to CPU
  input       [7:0] DBI,     // from PCB
  output      [7:0] DBO      // to PCB
);

reg read_io0;
reg read_io1;
reg read_dat;
reg [7:0] din;

reg [15:0] PAB;
wire [15:0] ABN = PAB + 16'd2;

assign DBO = CPU_DBI;

wire [7:0] RAM_Q;

wire ram_en = ABI[15:9] < 2'd3;
ram #(11,8) RAM(
  .clk  ( clk          ),
  .addr ( ABI[10:0]    ),
  .din  ( CPU_DBI      ),
  .q    ( RAM_Q        ),
  .rd_n ( 1'b0         ),
  .wr_n ( RW | ~ram_en ),
  .ce_n ( ~ram_en )
);

always @* begin
  ABO = ABI;

  // decode vector addresses
  if (ABI[15:4] == 12'hfff) begin

    ABO[15:4] = ABI[15:4];
    ABO[3:0] = ABI[3:0] ^ 4'hd;

  end

end

always @(posedge cen) begin
  if (cen) begin

    CPU_DBO <= DBI | RAM_Q;


    if (DBI[0] & DBI[1] & SYNC) begin // illegal

      PAB <= ABI;

      if (DBI == 8'b0110_0111) begin
        CPU_DBO <= 8'hA9; // send lda
        read_io0 <= 1'b1;
      end

      else if (DBI == 8'b0100_1011) begin // 4b
        CPU_DBO <= 8'hA9; // send lda
        read_io1 <= 1'b1;
      end

      else if (DBI == 8'b1000_1111) begin
        // ???? write "din" to IO
      end

      else begin
        CPU_DBO <= 8'hEA; // send nop
        read_dat <= 1'b1;
      end

    end

    else if (read_io0) begin
      CPU_DBO <= 8'd0; // ???
      read_io0 <= 1'b0;
    end

    else if (read_io1) begin
      CPU_DBO <= { 6'd0, VB, 1'b0 };
      read_io1 <= 1'b0;
    end

    if (read_dat) begin
      read_dat <= 1'b0;
      din <= DBI;
    end


  end
end


endmodule
