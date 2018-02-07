-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity PROM7_DST is
  port (
    CLK         : in    std_logic;
    ADDR        : in    std_logic_vector(4 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of PROM7_DST is


  type ROM_ARRAY is array(0 to 31) of std_logic_vector(7 downto 0);
  constant ROM : ROM_ARRAY := (
    x"00",x"07",x"66",x"EF",x"00",x"F8",x"EA",x"6F", -- 0x0000
    x"00",x"3F",x"00",x"C9",x"38",x"AA",x"AF",x"F6", -- 0x0008
    x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x0010
    x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- 0x0018
  );

begin

  p_rom : process
  begin
    wait until rising_edge(CLK);
       DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;
end RTL;
