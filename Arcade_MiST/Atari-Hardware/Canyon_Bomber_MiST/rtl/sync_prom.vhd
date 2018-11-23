-- Asynchronous implementation of the bipolar PROM used to decode some of the sync signals
-- This PROM data is used in several Kee and Atari games. Combinatorial logic uses no block 
-- RAM and is vendor agnostic

library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity prom is 
port(		
			address		: in	std_logic_vector(7 downto 0);
			data			: out	std_logic_vector(3 downto 0)
			);
end prom;

architecture rtl of prom is


begin


process(address)
begin
	case address is
		when "01111111" =>
         data <= "1000";
		when "10000000" =>
         data <= "1010";
      when "10000001" =>
         data <= "1010";
      when "10000010" =>
         data <= "1010";
      when "10000011" =>
         data <= "1010";
      when "10000100" =>
         data <= "1010";
      when "10000101" =>
         data <= "1110";
      when "11100000" =>
         data <= "1000";
      when "11100001" =>
         data <= "1000";
      when "11100010" =>
         data <= "1000";
      when "11100011" =>
         data <= "1000";
		when "11100100" =>	
		   data <= "1000";
		when "11100101" =>
         data <= "1000";
		when "11100110" =>
         data <= "1000";
		when "11100111" =>
         data <= "1000";
		when "11101000" =>
         data <= "1000";
		when "11101001" =>
         data <= "1000";
		when "11101010" =>
         data <= "1000";
		when "11101011" =>
         data <= "1000";
		when "11101100" =>
         data <= "1000";
		when "11101101" =>
         data <= "1000";
		when "11101110" =>
         data <= "1000";
		when "11101111" =>
         data <= "1010";
		when "11110000" =>
         data <= "1010";
		when "11110001" =>
         data <= "1010";
		when "11110010" =>
         data <= "1011";
		when "11110011" =>
         data <= "1011";
		when "11110100" =>
         data <= "1011";
		when "11110101" =>
         data <= "1010";
		when "11110110" =>
         data <= "1010";
		when "11110111" =>
         data <= "1010";
		when "11111000" =>
         data <= "1010";
		when "11111001" =>
         data <= "1010";
		when "11111010" =>
         data <= "1010";
		when "11111011" =>
         data <= "1010";
		when "11111100" =>
         data <= "1010";
		when "11111101" =>
         data <= "1010";
		when "11111110" =>
         data <= "1010";
		when "11111111" =>
         data <= "1010";
      when others =>
         data <= "0000";
      end case;
end process;

end rtl;