library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity invaders_memory is
	port(
		CLK             : in    std_logic;--10mhz	
		RWE_n           : in    std_logic;
		AD              : in    std_logic_vector(15 downto 0);
		RAB             : in    std_logic_vector(12 downto 0);
		RDB             : out    std_logic_vector(7 downto 0);
		RWD             : in    std_logic_vector(7 downto 0);
		IB              : out    std_logic_vector(7 downto 0)
		);
end invaders_memory;

architecture rtl of invaders_memory is
	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);

begin	
		u_rom_h : entity work.INVADERS_ROM_H
	  port map (
		CLK         => Clk,
		ENA         => '1',
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_0
		);
	--
	u_rom_g : entity work.INVADERS_ROM_G
	  port map (
		CLK         => Clk,
		ENA         => '1',
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_1
		);
	--
	u_rom_f : entity work.INVADERS_ROM_F
	  port map (
		CLK         => Clk,
		ENA         => '1',
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_2
		);
	--
	u_rom_e : entity work.INVADERS_ROM_E
	  port map (
		CLK         => Clk,
		ENA         => '1',
		ADDR        => AD(10 downto 0),
		DATA        => rom_data_3
		);
	--
	p_rom_data : process(AD, rom_data_0, rom_data_1, rom_data_2, rom_data_3)
	begin
	  IB <= (others => '0');
	  case AD(12 downto 11) is
		when "00" => IB <= rom_data_0;
		when "01" => IB <= rom_data_1;
		when "10" => IB <= rom_data_2;
		when "11" => IB <= rom_data_3;
		when others => null;
	  end case;
	end process;


	rams : for i in 0 to 3 generate
	  u_ram : entity work.WRAM
	  port map (
		q   => RDB((i*2)+1 downto (i*2)),
		address => RAB,
		clock  => Clk,
		data   => RWD((i*2)+1 downto (i*2)),
		rden   => '1',
		wren   => not RWE_n
		);
	end generate;

end;