library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sound is 
  generic
  (
    CLK_MHz           : natural
  );
  port
  (
    sysClk            : in    std_logic;
    reset             : in    std_logic;
    
    sndif_rd          : in    std_logic;
    sndif_wr          : in    std_logic;
    sndif_datai       : in    std_logic_vector(7 downto 0);
    sndif_addr        : in    std_logic_vector(15 downto 0);
    
    snd_clk           : out   std_logic;
    snd_data_l        : out   std_logic_vector(7 downto 0);
    snd_data_r        : out   std_logic_vector(7 downto 0);
    sndif_datao       : out   std_logic_vector(7 downto 0)
  );
end entity sound;

architecture SYN of Sound is

	component invaders_audio
		Port 
			(
			  Clk : in  std_logic;
			  S1  : in  std_logic_vector(5 downto 0);
			  S2  : in  std_logic_vector(5 downto 0);
			  Aud : out std_logic_vector(7 downto 0)
		  );
	end component;

-- Signal Declarations

	-- audio module clock
	signal clk_5M		  : std_logic;
	signal clk_10M	  : std_logic;
	
	-- port latches
	signal s1_r			  : std_logic_vector(5 downto 0);
	signal s2_r			  : std_logic_vector(5 downto 0);
	
  signal snd_data_s : std_logic_vector(7 downto 0);
  
begin

  sndif_datao <= X"00";

	-- latches
	process (sysClk, reset)
		variable wr_r : std_logic := '0';
	begin
		if reset = '1' then
			wr_r := '0';
		elsif rising_edge(sysClk) then
			-- latch port data on rising edge of WRITE
			if sndif_wr = '1' and wr_r = '0' then
				case sndif_addr(2 downto 0) is
					when "011" =>
						s1_r <= sndif_datai(5 downto 0);
					when "101" =>
						s2_r <= sndif_datai(5 downto 0);
					when others =>
				end case;
			end if;
			wr_r := sndif_wr;
		end if;
	end process;
	
	-- apparently the audio module wants a 10MHz clock
	process (sysClk, reset)
    subtype count_t is integer range 0 to CLK_MHz/5;
		variable count : count_t := 0;
	begin
    if reset = '1' then
      count := 0;
      clk_10M <= '0';
      clk_5M <= '0';
		elsif rising_edge(sysClk) then
      clk_10M <= '0';
      clk_5M <= '0';
      if count = count_t'high/2 then
        clk_10M <= '1';
        count := count + 1;
      elsif count = count_t'high then
        clk_10M <= '1';
        clk_5M <= '1';
        count := 0;
      else
        count := count + 1;
      end if;
		end if;
	end process;

  -- can use anything suitable
  snd_clk <= clk_5M;
		
  audio_inst : invaders_audio
    port map
      (
        Clk => clk_10M,
        S1  => s1_r,
        S2  => s2_r,
        Aud => snd_data_s
      );
     
  snd_data_l <= snd_data_s;
  snd_data_r <= snd_data_s;
  
end architecture SYN;
