//

module chip_select
(
    input  [3:0] pcb,

    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_rw,
    input        m68k_uds_n,
    input        m68k_lds_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,
    input        M1_n,
    input        RFSH_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_rom_2_cs,
    output reg m68k_ram_cs,
    output reg m68k_spr_cs,
    output reg m68k_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg m68k_scr_flip_cs,
    output reg input_p1_cs,
    output reg input_p2_cs,
    output reg input_dsw1_cs,
    output reg input_dsw2_cs,
    output reg input_coin_cs,
    output reg m68k_rotary1_cs,
    output reg m68k_rotary2_cs,
    output reg m68k_rotary_lsb_cs,    
    output reg m_invert_ctrl_cs,
    output reg m68k_latch_cs,
    output reg z80_latch_read_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,
    output reg   z80_latch_cs,

    output reg   z80_sound0_cs,
    output reg   z80_sound1_cs,
    output reg   z80_upd_cs,
    output reg   z80_upd_r_cs
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
        input [15:0] base_address;
        input  [7:0] width;
begin
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n && RFSH_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n && M1_n;
end
endfunction

always @ (*) begin
    // Memory mapping based on PCB type
    z80_rom_cs       = !MREQ_n && RFSH_n && z80_addr[15:0] < 16'hf000;
    z80_ram_cs       = !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800;
    z80_latch_cs     = !MREQ_n && RFSH_n && z80_addr[15:0] == 16'hf800;

    case (pcb)
        pcb_A7007_A8007: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff );
            m68k_rom_2_cs    = m68k_cs( 24'h300000, 24'h33ffff );

            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h043fff );

            //  write only
            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw;

            //  read only
            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw;

            input_p2_cs      = m68k_cs( 24'h080002, 24'h080003 );
            input_coin_cs    = m68k_cs( 24'h080004, 24'h080005 );
            m_invert_ctrl_cs = m68k_cs( 24'h080006, 24'h080007 );

            m68k_scr_flip_cs = m68k_cs( 24'h0c0000, 24'h0c0001 );

            m68k_rotary1_cs      = m68k_cs( 24'h0c0000, 24'h0c0001 );
            m68k_rotary2_cs      = m68k_cs( 24'h0c8000, 24'h0c8001 );
            m68k_rotary_lsb_cs   = m68k_cs( 24'h0d0000, 24'h0d0001 );

            input_dsw1_cs    = m68k_cs( 24'h0f0000, 24'h0f0001 ) ;
            input_dsw2_cs    = m68k_cs( 24'h0f0008, 24'h0f0009 ) ;

            z80_latch_read_cs = m68k_cs( 24'h0f8000, 24'h0f8001 ) ;
            m68k_spr_cs      = m68k_cs( 24'h100000, 24'h107fff ) ;
            m68k_fg_ram_cs   = m68k_cs( 24'h200000, 24'h200fff ) | m68k_cs( 24'h201000, 24'h201fff ) ;
            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h400fff ) ;

            z80_sound0_cs    = z80_io_cs(8'h00); // ym3812 address
            z80_sound1_cs    = z80_io_cs(8'h20); // ym3812 data
            z80_upd_cs       = z80_io_cs(8'h40); // 7759 write
            z80_upd_r_cs     = z80_io_cs(8'h80); // 7759 reset

        end

        pcb_A7008: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;
            m68k_rom_2_cs    = 0;
            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h043fff ) ;

            //  read only
            input_p2_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;

            //  write only 
            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;

            //  read only
            input_coin_cs    = m68k_cs( 24'h0c0000, 24'h0c0001 ) & m68k_rw ;

            m_invert_ctrl_cs = 0;

            //  write only
            m68k_scr_flip_cs = m68k_cs( 24'h0c0000, 24'h0c0001 ) & !m68k_rw;

            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) ;

            m68k_rotary1_cs      = 0;
            m68k_rotary2_cs      = 0;
            m68k_rotary_lsb_cs   = 0;

            input_dsw1_cs    = m68k_cs( 24'h0f0000, 24'h0f0001 ) ;
            input_dsw2_cs    = m68k_cs( 24'h0f0008, 24'h0f0009 ) ;
            m68k_spr_cs      = m68k_cs( 24'h200000, 24'h207fff ) ;
            m68k_fg_ram_cs   = m68k_cs( 24'h100000, 24'h100fff ) | m68k_cs( 24'h101000, 24'h101fff );
            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h400fff ) ;

            z80_latch_read_cs = 0;


            z80_sound0_cs    = z80_io_cs(8'h00); // ym3812 address
            z80_sound1_cs    = z80_io_cs(8'h20); // ym3812 data
            z80_upd_cs       = z80_io_cs(8'h40); // 7759 write
            z80_upd_r_cs     = z80_io_cs(8'h80); // 7759 reset

        end

        pcb_A7008_SS: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;
            m68k_rom_2_cs    = 0;
            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h043fff ) ;

            //  read only
            input_p2_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;
            //  write only
            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;

            //  read only
            input_coin_cs    = m68k_cs( 24'h0c0000, 24'h0c0001 ) & m68k_rw ;

            m_invert_ctrl_cs = 0;

            //  write only
            m68k_scr_flip_cs = m68k_cs( 24'h0c0000, 24'h0c0001 ) & !m68k_rw;


            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) ;

            input_dsw1_cs    = m68k_cs( 24'h0f0000, 24'h0f0001 ) ;
            input_dsw2_cs    = m68k_cs( 24'h0f0008, 24'h0f0009 ) ;

            m68k_rotary1_cs      = 0;
            m68k_rotary2_cs      = 0;
            m68k_rotary_lsb_cs   = 0;

            m68k_spr_cs      = m68k_cs( 24'h200000, 24'h207fff ) ;
            m68k_fg_ram_cs   = m68k_cs( 24'h100000, 24'h100fff ) | m68k_cs( 24'h101000, 24'h101fff );
            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h400fff ) ;

            z80_latch_read_cs = 0;

            z80_sound0_cs    = z80_io_cs(8'h00); // ym3812 address
            z80_sound1_cs    = z80_io_cs(8'h20); // ym3812 data
            z80_upd_cs       = z80_io_cs(8'h40); // 7759 write
            z80_upd_r_cs     = z80_io_cs(8'h80); // 7759 reset
        end

        default: begin
            m68k_rom_cs      = 0;
            m68k_rom_2_cs    = 0;

            m68k_ram_cs      = 0;

            //  write only
            m68k_latch_cs    = 0;

            //  read only
            input_p1_cs      = 0;

            input_p2_cs      = 0;
            input_coin_cs    = 0;
            m_invert_ctrl_cs = 0;

            m68k_scr_flip_cs = 0;

            m68k_rotary1_cs      = 0;
            m68k_rotary2_cs      = 0;
            m68k_rotary_lsb_cs   = 0;

            input_dsw1_cs    = 0;
            input_dsw2_cs    = 0;

            z80_latch_read_cs = 0;
            m68k_spr_cs      = 0;
            m68k_fg_ram_cs   = 0;
            m68k_pal_cs      = 0;

            z80_sound0_cs    = 0;
            z80_sound1_cs    = 0;
            z80_upd_cs       = 0;
            z80_upd_r_cs     = 0;

        end
    endcase

end

endmodule
