-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity PROM1_DST is
  port (
    CLK         : in    std_logic;
    ADDR        : in    std_logic_vector(7 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of PROM1_DST is


  type ROM_ARRAY is array(0 to 255) of std_logic_vector(7 downto 0);
  constant ROM : ROM_ARRAY := (
    x"07",x"09",x"0A",x"0B",x"0C",x"0D",x"0D",x"0E", -- 0x0000
    x"0E",x"0E",x"0D",x"0D",x"0C",x"0B",x"0A",x"09", -- 0x0008
    x"07",x"05",x"04",x"03",x"02",x"01",x"01",x"00", -- 0x0010
    x"00",x"00",x"01",x"01",x"02",x"03",x"04",x"05", -- 0x0018
    x"07",x"0C",x"0E",x"0E",x"0D",x"0B",x"09",x"0A", -- 0x0020
    x"0B",x"0B",x"0A",x"09",x"06",x"04",x"03",x"05", -- 0x0028
    x"07",x"09",x"0B",x"0A",x"08",x"05",x"04",x"03", -- 0x0030
    x"03",x"04",x"05",x"03",x"01",x"00",x"00",x"02", -- 0x0038
    x"07",x"0A",x"0C",x"0D",x"0E",x"0D",x"0C",x"0A", -- 0x0040
    x"07",x"04",x"02",x"01",x"00",x"01",x"02",x"04", -- 0x0048
    x"07",x"0B",x"0D",x"0E",x"0D",x"0B",x"07",x"03", -- 0x0050
    x"01",x"00",x"01",x"03",x"07",x"0E",x"07",x"00", -- 0x0058
    x"07",x"0D",x"0B",x"08",x"0B",x"0D",x"09",x"06", -- 0x0060
    x"0B",x"0E",x"0C",x"07",x"09",x"0A",x"06",x"02", -- 0x0068
    x"07",x"0C",x"08",x"04",x"05",x"07",x"02",x"00", -- 0x0070
    x"03",x"08",x"05",x"01",x"03",x"06",x"03",x"01", -- 0x0078
    x"00",x"08",x"0F",x"07",x"01",x"08",x"0E",x"07", -- 0x0080
    x"02",x"08",x"0D",x"07",x"03",x"08",x"0C",x"07", -- 0x0088
    x"04",x"08",x"0B",x"07",x"05",x"08",x"0A",x"07", -- 0x0090
    x"06",x"08",x"09",x"07",x"07",x"08",x"08",x"07", -- 0x0098
    x"07",x"08",x"06",x"09",x"05",x"0A",x"04",x"0B", -- 0x00A0
    x"03",x"0C",x"02",x"0D",x"01",x"0E",x"00",x"0F", -- 0x00A8
    x"00",x"0F",x"01",x"0E",x"02",x"0D",x"03",x"0C", -- 0x00B0
    x"04",x"0B",x"05",x"0A",x"06",x"09",x"07",x"08", -- 0x00B8
    x"00",x"01",x"02",x"03",x"04",x"05",x"06",x"07", -- 0x00C0
    x"08",x"09",x"0A",x"0B",x"0C",x"0D",x"0E",x"0F", -- 0x00C8
    x"0F",x"0E",x"0D",x"0C",x"0B",x"0A",x"09",x"08", -- 0x00D0
    x"07",x"06",x"05",x"04",x"03",x"02",x"01",x"00", -- 0x00D8
    x"00",x"01",x"02",x"03",x"04",x"05",x"06",x"07", -- 0x00E0
    x"08",x"09",x"0A",x"0B",x"0C",x"0D",x"0E",x"0F", -- 0x00E8
    x"00",x"01",x"02",x"03",x"04",x"05",x"06",x"07", -- 0x00F0
    x"08",x"09",x"0A",x"0B",x"0C",x"0D",x"0E",x"0F"  -- 0x00F8
  );

begin

  p_rom : process
  begin
    wait until rising_edge(CLK);
       DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;
end RTL;
