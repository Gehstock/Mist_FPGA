-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity PROM3_DST is
  port (
    ADDR        : in    std_logic_vector(6 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of PROM3_DST is


  type ROM_ARRAY is array(0 to 127) of std_logic_vector(7 downto 0);
  constant ROM : ROM_ARRAY := (
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0000
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0008
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0010
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0018
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0020
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0028
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0030
    x"0F",x"0D",x"0F",x"0F",x"0F",x"0D",x"0F",x"0F", -- 0x0038
    x"07",x"0F",x"0E",x"0D",x"0F",x"0F",x"0E",x"0D", -- 0x0040
    x"0F",x"0F",x"0E",x"0D",x"0F",x"0F",x"0E",x"0D", -- 0x0048
    x"0F",x"0F",x"0E",x"0D",x"0F",x"0F",x"0F",x"0B", -- 0x0050
    x"07",x"0F",x"0E",x"0D",x"0F",x"0F",x"0E",x"0D", -- 0x0058
    x"0F",x"0F",x"0E",x"0D",x"0F",x"0F",x"0E",x"0D", -- 0x0060
    x"0F",x"0F",x"0F",x"0B",x"07",x"0F",x"0E",x"0D", -- 0x0068
    x"0F",x"0F",x"0E",x"0D",x"0F",x"0F",x"0E",x"0D", -- 0x0070
    x"0F",x"0F",x"0E",x"0D",x"0F",x"0F",x"0F",x"0B"  -- 0x0078
  );

begin

  p_rom : process(ADDR)
  begin
     DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;
end RTL;
