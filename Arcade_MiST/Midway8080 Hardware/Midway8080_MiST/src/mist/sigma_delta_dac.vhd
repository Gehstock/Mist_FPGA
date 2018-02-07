library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sigma_delta_dac is
  port
  (
    clk     : in std_logic;
    din     : in std_logic_vector(7 downto 0);
    
    dout    : out std_logic
  );
end entity sigma_delta_dac;

architecture SYN of sigma_delta_dac is

  signal si : unsigned(15 downto 0) := (others => '0');
  signal so : unsigned(15 downto 0) := (others => '0');
  
begin

  si(15 downto 10) <= "000000";
  si(9 downto 0) <= unsigned(so(9) & so(9) & din);
  
  process (clk)
  begin
    if rising_edge(clk) then
      so <= si + so;
      dout <= so(9);
    end if;
  end process;

end architecture SYN;
