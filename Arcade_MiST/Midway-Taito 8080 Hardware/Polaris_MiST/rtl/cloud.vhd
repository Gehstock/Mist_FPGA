library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- background cloud for Polaris - doesn't use rom, instead uses 256 pixel wide bitmap

entity cloud is
port (
	clk			: in  std_logic;
	pixel_en  	: in  std_logic;
	v    			: in  std_logic_vector(11 downto 0); -- Vertical
	h    			: in  std_logic_vector(11 downto 0); -- Horizontal
	flip        : in  std_logic;
	pixel       : out std_logic
);
end entity;

architecture prom of cloud is
	-- Scrolls 1 pixel every 4 frames
   signal scroll : unsigned(9 downto 0) := (others => '0');

	type cloud is array(NATURAL range <>) of unsigned(7 downto 0);
	
	-- Cloud bitmap is 256 x 14 pixels
	constant lookup : cloud := (
		X"00",X"00",X"30",X"00",X"00",X"00",X"00",X"20",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"FE",X"40",X"00",X"00",X"07",X"40",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"01",X"FF",X"80",X"0C",X"01",X"9C",X"C0",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"7C",X"00",X"1E",X"17",X"28",X"30",X"0E",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"18",X"01",X"FC",X"0F",X"E0",X"01",X"58",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"0F",X"F0",X"3F",X"FC",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"02",X"7F",X"E4",X"7F",X"FF",X"07",X"80",X"04",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"07",X"FF",X"FE",X"FF",X"FB",X"EE",X"C0",X"18",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"01",X"FF",X"FF",X"FF",X"E1",X"EE",X"39",X"30",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"1F",X"F7",X"7F",X"07",X"0F",X"8E",X"D8",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"3F",X"E2",X"1E",X"1F",X"95",X"00",X"64",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"0F",X"E0",X"00",X"0F",X"D4",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"01",X"D0",X"00",X"18",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"40",X"00",X"64",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00");
			
begin

	-- Clouds bitmapped is drawn from vertical line 23 downwards and scrolls right to left at fixed speed 

	doclouds : process(clk,h,v)
	  variable bx : unsigned(8 downto 0);
	  variable by : integer;
	  variable addr : integer;
	begin
		if rising_edge(clk) then
			if (pixel_en='1') then
				by := to_integer(unsigned(h));

				-- Decrement cloud scroll when both set to 16 (random point on the screen)
				if (by = 16 and v = "000000001000") then
					scroll <= scroll - 1;
				end if;
				
				-- Are we in cloud area, if so plot some pixels
				if (flip = '1') then
					-- Draw as is
					if (by > 22) and (by < 37) then
						by := (36 - by) * 32;
						bx := unsigned('0' & (not v(7 downto 0))) + ('0' & scroll(9 downto 2));
						addr := by + to_integer(unsigned(bx(7 downto 3)));
						
						case bx(2 downto 0) is
							when "000" => pixel <= lookup(addr)(7);
							when "001" => pixel <= lookup(addr)(6);
							when "010" => pixel <= lookup(addr)(5);
							when "011" => pixel <= lookup(addr)(4);
							when "100" => pixel <= lookup(addr)(3);
							when "101" => pixel <= lookup(addr)(2);
							when "110" => pixel <= lookup(addr)(1);
							when "111" => pixel <= lookup(addr)(0);
						end case;
					else
						pixel <= '0';
					end if;
				else
					-- Draw flipped
					by := 255 - by;
					if (by > 22) and (by < 37) then
						by := (36 - by) * 32;
						bx := unsigned('0' & v(7 downto 0)) + ('0' & scroll(9 downto 2));
						addr := by + to_integer(unsigned(bx(7 downto 3)));
						
						case bx(2 downto 0) is
							when "000" => pixel <= lookup(addr)(7);
							when "001" => pixel <= lookup(addr)(6);
							when "010" => pixel <= lookup(addr)(5);
							when "011" => pixel <= lookup(addr)(4);
							when "100" => pixel <= lookup(addr)(3);
							when "101" => pixel <= lookup(addr)(2);
							when "110" => pixel <= lookup(addr)(1);
							when "111" => pixel <= lookup(addr)(0);
						end case;
					else
						pixel <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

end architecture;