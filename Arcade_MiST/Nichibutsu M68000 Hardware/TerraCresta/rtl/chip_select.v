//

module chip_select
(
    input  [2:0] pcb,

    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_uds_n,
    input        m68k_lds_n,

    input [15:0] z80_addr,
    input        RFSH_n,
    input        MREQ_n,
    input        IORQ_n,

    // M68K selects
    output reg   prog_rom_cs,
    output reg   m68k_ram_cs,
    output reg   bg_ram_cs,
    output reg   m68k_ram1_cs,
    output reg   fg_ram_cs,
    output reg   flip_cs,

    output reg   input_p1_cs,
    output reg   input_p2_cs,
    output reg   input_system_cs,
    output reg   input_dsw_cs,

    output reg   scroll_x_cs,
    output reg   scroll_y_cs,

    output reg   sound_latch_cs,

    output reg   prot_chip_data_cs,
    output reg   prot_chip_cmd_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,

    output reg   z80_sound0_cs,
    output reg   z80_sound1_cs,
    output reg   z80_dac1_cs,
    output reg   z80_dac2_cs,
    output reg   z80_latch_clr_cs,
    output reg   z80_latch_r_cs

    // other params
//    output reg [15:0] scroll_x,
//    output reg [15:0] scroll_y,
//    output reg [7:0]  sound_latch
);

`include "defs.v"

function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( m68k_a[23:0] >= start_address && m68k_a[23:0] <= end_address) & !m68k_as_n & !(m68k_uds_n & m68k_lds_n);
end
endfunction

function z80_mem_cs;
        input [15:0] start_address;
        input [15:0] end_address;
begin
    z80_mem_cs = ( z80_addr >= start_address && z80_addr <= end_address ) & !MREQ_n & RFSH_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction


always @ (*) begin
    // Memory mapping based on PCB type

    prot_chip_data_cs = 0;
    prot_chip_cmd_cs  = 0;

    if ( pcb == pcb_terra_cresta ) begin
        prog_rom_cs       = m68k_cs( 24'h000000, 24'h01ffff );
        m68k_ram_cs       = m68k_cs( 24'h020000, 24'h021fff );
        bg_ram_cs         = m68k_cs( 24'h022000, 24'h022fff );
        m68k_ram1_cs      = m68k_cs( 24'h023000, 24'h023fff );

        input_p1_cs       = m68k_cs( 24'h024000, 24'h024001 );
        input_p2_cs       = m68k_cs( 24'h024002, 24'h024003 );
        input_system_cs   = m68k_cs( 24'h024004, 24'h024005 );
        input_dsw_cs      = m68k_cs( 24'h024006, 24'h024007 );

        flip_cs           = m68k_cs( 24'h026000, 24'h026001 );
        scroll_x_cs       = m68k_cs( 24'h026002, 24'h026003 );
        scroll_y_cs       = m68k_cs( 24'h026004, 24'h026005 );

        sound_latch_cs    = m68k_cs( 24'h02600c, 24'h02600d );
        fg_ram_cs         = m68k_cs( 24'h028000, 24'h0287ff );
    end else begin
        prog_rom_cs       = m68k_cs( 24'h000000, 24'h01ffff );
        m68k_ram_cs       = m68k_cs( 24'h040000, 24'h040fff );
        bg_ram_cs         = m68k_cs( 24'h042000, 24'h042fff );
        m68k_ram1_cs      = 0;

        input_p1_cs       = m68k_cs( 24'h044000, 24'h044001 );
        input_p2_cs       = m68k_cs( 24'h044002, 24'h044003 );
        input_system_cs   = m68k_cs( 24'h044004, 24'h044005 );
        input_dsw_cs      = m68k_cs( 24'h044006, 24'h044007 );

        flip_cs           = m68k_cs( 24'h046000, 24'h046001 );
        scroll_x_cs       = m68k_cs( 24'h046002, 24'h046003 );
        scroll_y_cs       = m68k_cs( 24'h046004, 24'h046004 );

        sound_latch_cs    = m68k_cs( 24'h04600c, 24'h04600d );

        fg_ram_cs         = m68k_cs( 24'h050000, 24'h050fff );


        prog_rom_cs       = m68k_cs( 24'h000000, 24'h01ffff );
        m68k_ram_cs       = m68k_cs( 24'h040000, 24'h040fff );
        bg_ram_cs         = m68k_cs( 24'h042000, 24'h042fff );
        m68k_ram1_cs      = 0;

        if ( pcb == pcb_horekid ) begin
            input_p1_cs       = m68k_cs( 24'h044006, 24'h044007 );
            input_p2_cs       = m68k_cs( 24'h044004, 24'h044005 );
            input_system_cs   = m68k_cs( 24'h044002, 24'h044003 );
            input_dsw_cs      = m68k_cs( 24'h044000, 24'h044001 );
        end else begin
            input_p1_cs       = m68k_cs( 24'h044000, 24'h044001 );
            input_p2_cs       = m68k_cs( 24'h044002, 24'h044003 );
            input_system_cs   = m68k_cs( 24'h044004, 24'h044005 );
            input_dsw_cs      = m68k_cs( 24'h044006, 24'h044007 );
        end

        scroll_x_cs       = m68k_cs( 24'h046002, 24'h046003 );
        scroll_y_cs       = m68k_cs( 24'h046004, 24'h046004 );

        sound_latch_cs    = m68k_cs( 24'h04600c, 24'h04600d );

        fg_ram_cs         = m68k_cs( 24'h050000, 24'h050fff );
    end

    if ( pcb == pcb_amazon || pcb == pcb_amazont || pcb == pcb_horekid ) begin
        prot_chip_data_cs = m68k_cs( 24'h070000, 24'h070001 );
        prot_chip_cmd_cs  = m68k_cs( 24'h070002, 24'h070003 );
    end

    z80_rom_cs        = z80_mem_cs( 16'h0000, 16'hbfff ) ;
    z80_ram_cs        = z80_mem_cs( 16'hc000, 16'hcfff ) ;

    z80_sound0_cs     = z80_io_cs(  8'h00 );
    z80_sound1_cs     = z80_io_cs(  8'h01 );
    z80_dac1_cs       = z80_io_cs(  8'h02 );
    z80_dac2_cs       = z80_io_cs(  8'h03 );
    z80_latch_clr_cs  = z80_io_cs(  8'h04 );
    z80_latch_r_cs    = z80_io_cs(  8'h06 );

end
endmodule
