--Blue Shark Color Overlay Gehstock 2019
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;


entity BlueShark_Overlay is
	port(
		Video             : in    std_logic;
		Overlay           : in    std_logic;
		CLK               : in    std_logic;
		Rst_n_s           : in    std_logic;
		HSync             : in    std_logic;
		VSync             : in    std_logic;
		AD                : in    std_logic_vector(15 downto 0);
		O_VIDEO_R         : out   std_logic;
		O_VIDEO_G         : out   std_logic;
		O_VIDEO_B         : out   std_logic;
		O_HSYNC           : out   std_logic;
		O_VSYNC           : out   std_logic
		);
end BlueShark_Overlay;

architecture rtl of BlueShark_Overlay is

		signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal HSync_t1        : std_logic;
	signal Overlay_B1      : boolean;
	signal Overlay_B1_VCnt : boolean;
	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal col_data        : std_logic_vector(3 downto 0);
	signal col_addr        : std_logic_vector(9 downto 0);
begin	
	process (Rst_n_s, Clk)
		variable cnt : unsigned(3 downto 0);
	begin
		if Rst_n_s = '0' then
			cnt := "0000";
		elsif Clk'event and Clk = '1' then
			if cnt = 9 then
				cnt := "0000";
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;
	
  p_overlay : process(Rst_n_s, Clk)
	variable HStart : boolean;
  begin
	if Rst_n_s = '0' then
	  HCnt <= (others => '0');
	  VCnt <= (others => '0');
	  HSync_t1 <= '0';
	  Overlay_B1_VCnt <= false;
	  Overlay_B1 <= false;
	elsif Clk'event and Clk = '1' then
	  HSync_t1 <= HSync;
	  HStart := (HSync_t1 = '0') and (HSync = '1');

	  if HStart then
		HCnt <= (others => '0');
	  else
		HCnt <= HCnt + "1";
	  end if;

	  if (VSync = '0') then
		VCnt <= (others => '0');
	  elsif HStart then
		VCnt <= VCnt + "1";
	  end if;

	  if HStart then
		if (Vcnt>= x"28") and (Vcnt <= x"35") then--Top Start
		  Overlay_B1_VCnt <= true;
		else
		  Overlay_B1_VCnt <= false;
		end if;
	  end if;

	  if (HCnt <= x"0") and Overlay_B1_VCnt then--Left Start
		Overlay_B1 <= true;
	  elsif (HCnt >= x"228") then--Right End
		Overlay_B1 <= false;
	  end if;
	end if;
  end process;

  p_video_out_comb : process(Video, Overlay_B1)
  begin
	if (Video = '0') then
	  VideoRGB  <= "000";
	else
	  if Overlay_B1 then
		VideoRGB  <= "001";
	  else
		VideoRGB  <= "111";
	  end if;
	end if;
  end process;

  
  O_VIDEO_R <= VideoRGB(2) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_G <= VideoRGB(1) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_B <= VideoRGB(0) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_HSYNC   <= HSync;
  O_VSYNC   <= VSync;


end;