--
--  fg.vhd
--
--  Generate a random noise.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: fg.vhd, v0.3 2001/11/14 00:00:00 SEILEBOST $
--
-- from  XAPP211.pdf & XAPP211.ZIP (XILINX APPLICATION)
--
--The following is example code that implements one LFSR which can be used as part of pn generators.
--The number of taps, tap points, and LFSR width are parameratizable. When targetting Xilinx (Virtex)
--all the latest synthesis vendors (Leonardo, Synplicity, and FPGA Express) will infer the shift 
--register LUTS (SRL16) resulting in a very efficient implementation.
--
--Control signals have been provided to allow external circuitry to control such things as filling,
--puncturing, stalling (augmentation), etc.
--
--Mike Gulotta
--11/4/99
--Revised 3/17/00:  Fixed "commented" block diagram to match polynomial.
--
--
--###################################################################################################
--          I Polinomials:                                                                          #
--          I(x) = X**17 + X**2 + 1                                                                 #
--                                                                                                  #
--          LFSR implementation format examples:                                                    #
--###################################################################################################
--                                                                                                  #
--          I(x) = X**17 + X**2 + 1                                                                 #
--                        ________                                                                  #
--                       |        |<<.........................                  #
--                       | Parity |                          |                  #
--      .................|        |<<...                     |                  #
--     |                 |________|    |                     |                  #
--     |                               |                     |                  #
--     |          __________________   |   ___ ___           |                  #
--     |...|\    |    |        |    |  |  |   |   |          | pn_out_i         #
--         ||-->>| 16 | - - - -|  2 |-----| 1 | 0 | >>---------->>              #
--DataIn_i.|/    |____|________|____|     |___|___|                             #
--          |                      srl_i                                                            #
-- FillSel..|                                                                                       #
--                                  ---> shifting -->>                                              #

library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i_pn_gen is
  generic(NumOfTaps_i  : integer := 2;   -- # of taps for I channel LFSR, including output tap.
          Width        : integer := 17); -- LFSR length (ie, total # of storage elements)
  port(clk, ShiftEn, FillSel, DataIn_i, RESET  : in  std_logic;
       pn_out_i                                : out std_logic);
end i_pn_gen ;


architecture rtl of i_pn_gen is

  type     TapPointArray_i is array (NumOfTaps_i-1 downto 0) of integer;
  constant Tap_i : TapPointArray_i := (2, 0);  
  signal   srl_i       : std_logic_vector(Width-1     downto 0);   -- shift register.
  signal   par_fdbk_i  : std_logic_vector(NumOfTaps_i downto 0);   -- Parity feedback.
  signal   lfsr_in_i   : std_logic;                                -- mux output.


begin

---------------------------------------------------------------------
------------------ I Channel ----------------------------------------
---------------------------------------------------------------------

  Shift_i : process (clk, reset)
  begin
    if (RESET = '1') then
       SRL_I <= "00000000000000000";
    elsif clk'event and clk = '1' then
      if (ShiftEn = '1') then
        srl_i <= lfsr_in_i & srl_i(srl_i'high downto 1);
      end if; 
    end if;
  end process;

  par_fdbk_i(0) <= '0';

  fdbk_i : for X in 0 to Tap_i'high generate -- parity generator
               par_fdbk_i(X+1) <= par_fdbk_i(X) xor srl_i(Tap_i(X));
           end generate fdbk_i;

  lfsr_in_i <= DataIn_i when FillSel = '1' else par_fdbk_i(par_fdbk_i'high);
  
  pn_out_i <= srl_i(srl_i'low);  -- PN I channel output.

  
end rtl;



