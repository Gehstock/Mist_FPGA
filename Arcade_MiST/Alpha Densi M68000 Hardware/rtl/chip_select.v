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
    input        RD_n,
    input        WR_n,
    input        M1_n,
    input        RFSH_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_rom_2_cs,
    output reg m68k_ram_cs,
    output reg m68k_spr_cs,
    output reg m68k_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg m68k_sp85_cs,

    output reg input_p1_cs,
    output reg m68k_dsw_cs,

    output reg m68k_rotary2_cs,
    output reg m68k_rotary_msb_cs,

    output reg vbl_int_clr_cs,
    output reg cpu_int_clr_cs,
    output reg watchdog_clr_cs,

    output reg m68k_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,

    output reg   z80_latch_cs,
    output reg   z80_latch_clr_cs,
    output reg   z80_dac_cs,
    output reg   z80_ym2413_cs, // OPN YM2413
    output reg   z80_ym2203_cs, // OPLL YM2203
    output reg   z80_bank_set_cs,
    output reg   z80_banked_cs
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
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n & RFSH_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n ;
end
endfunction

//-- board config 6 bits
//        00 = II
//        01 = III
//        11 = V
//mcu id  00 = don't care
//        01 = 0x8814
//        10 = 0x8512
//        11 = 0x8713
//coin     0 = 0x2222 / 1 = 0x2423
//invert   0 = input not inverted / 1 = inverted

always @ (*) begin
    // Memory mapping based on PCB type
    m68k_rom_cs        = 0;
    m68k_ram_cs        = 0;
    m68k_latch_cs      = 0;
    input_p1_cs        = 0;
    m68k_dsw_cs        = 0;
    m68k_fg_ram_cs     = 0;
    m68k_spr_cs        = 0;
    m68k_rotary2_cs    = 0;
    m68k_rotary_msb_cs = 0;
    m68k_sp85_cs       = 0;
    m68k_pal_cs        = 0;
    m68k_rom_2_cs      = 0;
    cpu_int_clr_cs     = 0;
    vbl_int_clr_cs     = 0;
    watchdog_clr_cs    = 0;
    z80_rom_cs         = 0;
    z80_ram_cs         = 0;
    z80_banked_cs      = 0;
    z80_latch_cs       = 0;
    z80_latch_clr_cs   = 0;
    z80_dac_cs         = 0;
    z80_ym2413_cs      = 0;
    z80_ym2203_cs      = 0;
    z80_bank_set_cs    = 0;

    // reset microcontroller interrupt 
    cpu_int_clr_cs    = m68k_cs( 24'h0d8000, 24'h0dffff ) & m68k_rw; // tst.b $d8000.l

    // reset vblank interrupt 
    vbl_int_clr_cs    = m68k_cs( 24'h0e0000, 24'h0e7fff ) & m68k_rw; // tst.b $e0000.l

    case (pcb)
        SKYADV, SKYADVU, GANGWARS, SBASEBALJ, SBASEBAL: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h043fff ) ;

            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;

            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;

            m68k_dsw_cs      = m68k_cs( 24'h0c0000, 24'h0c0001 ) ;

            m68k_fg_ram_cs   = m68k_cs( 24'h100000, 24'h100fff ) ;

            m68k_spr_cs      = m68k_cs( 24'h200000, 24'h207fff ) ;

            m68k_rotary2_cs  = 0 ;

            m68k_rotary_msb_cs = 0;

            m68k_sp85_cs     = m68k_cs( 24'h300000, 24'h303fff ) ;

            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h401fff ) ;

            m68k_rom_2_cs    = m68k_cs( 24'h800000, 24'h83ffff ) ;

            // reset watchdog interrupt ( implement? )
            watchdog_clr_cs   = m68k_cs( 24'h0e8000, 24'h0effff ) ; // tst.b $e8000.l

            z80_rom_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] <  16'h8000 );
            z80_ram_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'h8000 && z80_addr[15:0] < 16'h8800 );
            z80_banked_cs     = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            // read latch.  latch is active on all i/o reads
            z80_latch_cs      = (!IORQ_n) && (!RD_n) ; 

            z80_latch_clr_cs  = ( z80_addr[3:1] == 3'b000 ) && ( !IORQ_n ) && (!WR_n);

            // only the lower 4 bits are used to decode port
            // 0x08-0x09
            z80_dac_cs        = ( z80_addr[3:1] == 3'b100 ) && ( !IORQ_n ) && (!WR_n) ; // 8 bit DAC

            // 0x0a-0x0b
            z80_ym2413_cs     = ( z80_addr[3:1] == 3'b101 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0c-0x0d
            z80_ym2203_cs     = ( z80_addr[3:1] == 3'b110 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0E-0x0F
            z80_bank_set_cs   = ( z80_addr[3:1] == 3'b111 ) && ( !IORQ_n ) && (!WR_n); // select latches z80 D[4:0]
        end

        GOLDMEDL: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;
            
            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h040fff ) ;
            
            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;
            
            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;
            

            m68k_dsw_cs      = m68k_cs( 24'h0c0000, 24'h0c007f ) ;
            
            m68k_rotary2_cs  = 0 ;

            m68k_rotary_msb_cs = 0;
            
            m68k_fg_ram_cs   = m68k_cs( 24'h100000, 24'h100fff ) ;
            
            m68k_spr_cs      = m68k_cs( 24'h200000, 24'h207fff ) ;
            
            m68k_sp85_cs     = m68k_cs( 24'h300000, 24'h303fff ) ;
            
            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h400fff ) ;

            m68k_rom_2_cs    = m68k_cs( 24'h800000, 24'h83ffff ) ;

            // reset watchdog interrupt ( implement? )
            watchdog_clr_cs   = 0; //m68k_cs( 24'h0e8000, 24'h0effff ) ; // tst.b $e8000.l
             
            z80_rom_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] <  16'h8000 );
            z80_ram_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'h8000 && z80_addr[15:0] < 16'h8800 );
            z80_banked_cs     = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'hc000 );
            
            // read latch.  latch is active on all i/o reads
            z80_latch_cs      = (!IORQ_n) && (!RD_n) ; 
            
            z80_latch_clr_cs  = ( z80_addr[3:1] == 3'b000 ) && ( !IORQ_n ) && (!WR_n);  
            
            // only the lower 4 bits are used to decode port
            // 0x08-0x09
            z80_dac_cs        = ( z80_addr[3:1] == 3'b100 ) && ( !IORQ_n ) && (!WR_n) ; // 8 bit DAC
            
            // 0x0a-0x0b
            z80_ym2413_cs     = ( z80_addr[3:1] == 3'b101 ) && ( !IORQ_n ) && (!WR_n); 
            
            // 0x0c-0x0d
            z80_ym2203_cs     = ( z80_addr[3:1] == 3'b110 ) && ( !IORQ_n ) && (!WR_n); 
            
            // 0x0E-0x0F
            z80_bank_set_cs   = ( z80_addr[3:1] == 3'b111 ) && ( !IORQ_n ) && (!WR_n); // select latches z80 D[4:0]
        end

        SKYSOLDR, TIMESOLD, BATFIELD: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

            m68k_ram_cs      = m68k_cs( 24'h040000, 24'h040fff ) ;

            m68k_latch_cs    = m68k_cs( 24'h080000, 24'h080001 ) & !m68k_rw ;

            input_p1_cs      = m68k_cs( 24'h080000, 24'h080001 ) & m68k_rw ;

            // dsw / CN1 rotary / Ver II text banking
            m68k_dsw_cs      = m68k_cs( 24'h0c0000, 24'h0c007f ) ;

            m68k_rotary2_cs  = m68k_cs( 24'h0c8000, 24'h0c8001 ) & m68k_rw;

            m68k_rotary_msb_cs  = m68k_cs( 24'h0d0000, 24'h0d0001 ) ;

            m68k_fg_ram_cs   = m68k_cs( 24'h100000, 24'h100fff ) ;

            m68k_spr_cs      = m68k_cs( 24'h200000, 24'h207fff ) ;

            m68k_sp85_cs     = m68k_cs( 24'h300000, 24'h303fff ) ;

            m68k_pal_cs      = m68k_cs( 24'h400000, 24'h400fff ) ;

            m68k_rom_2_cs    = m68k_cs( 24'h800000, 24'h83ffff ) ;

            // reset watchdog interrupt ( implement? )
            watchdog_clr_cs   = 0; //m68k_cs( 24'h0e8000, 24'h0effff ) ; // tst.b $e8000.l

            z80_rom_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] <  16'h8000 );
            z80_ram_cs        = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'h8000 && z80_addr[15:0] < 16'h8800 );
            z80_banked_cs     = ( MREQ_n == 0 && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            // read latch.  latch is active on all i/o reads
            z80_latch_cs      = (!IORQ_n) && (!RD_n) ; 

            z80_latch_clr_cs  = ( z80_addr[3:1] == 3'b000 ) && ( !IORQ_n ) && (!WR_n);  

            // only the lower 4 bits are used to decode port
            // 0x08-0x09
            z80_dac_cs        = ( z80_addr[3:1] == 3'b100 ) && ( !IORQ_n ) && (!WR_n) ; // 8 bit DAC

            // 0x0a-0x0b
            z80_ym2413_cs     = ( z80_addr[3:1] == 3'b101 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0c-0x0d
            z80_ym2203_cs     = ( z80_addr[3:1] == 3'b110 ) && ( !IORQ_n ) && (!WR_n); 

            // 0x0E-0x0F
            z80_bank_set_cs   = ( z80_addr[3:1] == 3'b111 ) && ( !IORQ_n ) && (!WR_n); // select latches z80 D[4:0]
        end
        default:;
    endcase

end

endmodule
