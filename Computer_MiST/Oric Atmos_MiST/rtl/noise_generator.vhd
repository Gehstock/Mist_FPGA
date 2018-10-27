--
--  NOISE_GENERATOR.vhd
--
--  Generator a noise tone.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: NOISE_GENERATOR.vhd, v0.41 2002/01/03 00:00:00 SEILEBOST $
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity noise_generator is
    Port ( CLK          : in     std_logic;
           RST          : in     std_logic;
           --WR           : in     std_logic;
           --CS           : in     std_logic;
           DATA         : in     std_logic_vector(4 downto 0);
           CLK_N        : out    std_logic -- pseudo clock 
			);
end noise_generator;

architecture Behavioral of noise_generator is

SIGNAL COUNT   : std_logic_vector(4 downto 0);
signal poly17  : std_logic_vector(16 downto 0) := (others => '0');
--SIGNAL ShiftEn : std_logic;
--SIGNAL FillSel : std_logic;
--SIGNAL DataIn  : std_logic;
--SIGNAL lData   : std_logic_vector(4 downto 0);

--COMPONENT i_pn_gen port (clk, ShiftEn, FillSel, DataIn_i, RESET : in  std_logic;
--                        pn_out_i                               : out std_logic);
--END COMPONENT;

begin

--U_IPNG :  I_PN_GEN PORT MAP ( CLK      => CLK,
--                              ShiftEn  => ShiftEn,
--                              FillSel  => FillSel,
--                              RESET    => RST,
--                              DataIn_i => DataIn,
--                              pn_out_i => CLK_N);

 -- The noise generator
 PROCESS(CLK,RST)
    variable COUNT_MAX   : std_logic_vector(4 downto 0);
    variable poly17_zero : std_logic;
 BEGIN
    if (RST = '1') then
	    poly17 <= (others => '0');
    elsif ( CLK'event and  CLK = '1') then
       if (DATA = "00000") then
          COUNT_MAX := "00000";
       else
          COUNT_MAX := (DATA - "1");
       end if;

       -- Manage the polynome = 0 to regenerate another sequence
       poly17_zero := '0';
       if (poly17 = "00000000000000000") then poly17_zero := '1'; end if;

       if (COUNT >= COUNT_MAX) then
          COUNT <= "00000";
          poly17 <= (poly17(0) xor poly17(2) xor poly17_zero) 
		            & poly17(16 downto 1);
       else
          COUNT <= (COUNT + "1");
       end if;
    end if;
    
  END PROCESS;
  
 CLK_N <= poly17(0);
 
end Behavioral;
