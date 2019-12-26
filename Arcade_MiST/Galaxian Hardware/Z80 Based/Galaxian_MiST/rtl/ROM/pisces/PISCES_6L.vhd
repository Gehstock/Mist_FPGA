-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity PISCES_6L is
  port (
    CLK         : in    std_logic;
    ADDR        : in    std_logic_vector(4 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of PISCES_6L is


  type ROM_ARRAY is array(0 to 31) of std_logic_vector(7 downto 0);
  constant ROM : ROM_ARRAY := (
    x"00",x"33",x"C3",x"F6",x"00",x"17",x"C0",x"3F", -- 0x0000
    x"00",x"D8",x"07",x"3F",x"00",x"C0",x"C4",x"07", -- 0x0008
    x"00",x"C0",x"B0",x"1F",x"00",x"1E",x"71",x"07", -- 0x0010
    x"00",x"F6",x"07",x"F0",x"00",x"76",x"07",x"C6"  -- 0x0018
  );

begin

  p_rom : process
  begin
    wait until rising_edge(CLK);
       DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;
end RTL;
