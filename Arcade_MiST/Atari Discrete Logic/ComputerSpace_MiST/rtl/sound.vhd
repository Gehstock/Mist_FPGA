-----------------------------------------------------------------------------	
-- SOUND LOGIC																					--	
-- For use with Computer Space FPGA emulator											--
-- Sound stored in DE0 nano embedded fpga memory as "ROM IP Component"		--
-- The sounds are: 8 bit @ 11kHz															--
--																									--
-- sounds are:																					--
-- > rocket rotate																			--
-- > rocket thrust																			--
-- > rocket missile shooting																--
-- > explosion																					--		
-- > saucer missile shooting																--
-- > background ambience sound															--
--																									--
-- v1.0																							--
-- by Mattias G, 2015																		--
-- Enjoy!																						-- 
-----------------------------------------------------------------------------

library 	ieee;
use 		ieee.std_logic_1164.all; 
use 		ieee.numeric_std.all;
use 		IEEE.std_logic_signed.all;
use 		IEEE.std_logic_unsigned.all;
library 	work;

--80---------------------------------------------------------------------------|

entity sound is 
	port (
	clock_50, audio_gate 						: in std_logic;
	
	sound_switch									: in std_logic_vector (7 downto 0);
	-- sound_switch(1):  rocket rotate
	-- sound_switch(2):  rocket thrust
	-- sound_switch(3):  rocket missile
	-- sound_switch(4):  explosion
	-- sound_switch(5):  saucer missile
	-- sound_switch(7):  background ambience 	
			
	-- 16 bit wav to be used as input
	-- to sigma delta audio dac logic.
	-- just a normal raw wav file without
	-- the wav header
	sigma_delta_wav 								: out signed (15 downto 0) 
	);
	
end sound;


architecture sound_architecture
				 of sound is 

component rocket_rotate is
	port (
	address											: in STD_LOGIC_VECTOR (10 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component rocket_thrust is
	port (
	address											: in STD_LOGIC_VECTOR (11 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component rocket_shooting is
	port (
	address											: in STD_LOGIC_VECTOR (12 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component explosion is
	port (
	address											: in STD_LOGIC_VECTOR (13 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component saucer_shooting is
	port (
	address											: in STD_LOGIC_VECTOR (11 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component bakam is
	port (
	address											: in STD_LOGIC_VECTOR (13 DOWNTO 0);
	clock												: IN STD_LOGIC  := '1';
	q													: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;


type state_type is (FREQ_COUNT, READ_BYTE, MERGE_SOUNDS);

signal state 	: state_type  := FREQ_COUNT;

-- memory clock
signal fm_clock 									: std_logic;

signal reset 										: std_logic := '1';

signal sample_rate_count 						: integer := 1;

--  memory low and high bytes
signal fm_data_low_1, fm_data_low_2			: signed (7 DOWNTO 0); 
signal fm_data_low_3, fm_data_low_4			: signed (7 DOWNTO 0); 
signal fm_data_low_5, fm_data_low_7 		: signed (7 DOWNTO 0);

-- current sound memory
-- addresses for each sound 1-7
signal sound_adr_1		 						: STD_LOGIC_VECTOR (10 DOWNTO 0);
signal sound_adr_1_num							: natural range 0 to 1042303;
-- for comparisons

signal sound_adr_2		 						: STD_LOGIC_VECTOR (11 DOWNTO 0);
signal sound_adr_2_num							: natural range 0 to 1042303;
-- for comparisons

signal sound_adr_3		 						: STD_LOGIC_VECTOR (12 DOWNTO 0);
signal sound_adr_3_num							: natural range 0 to 1042303;
-- for comparisons

signal sound_adr_4		 						: STD_LOGIC_VECTOR (13 DOWNTO 0);
signal sound_adr_4_num							: natural range 0 to 1042303;
-- for comparisons

signal sound_adr_5		 						: STD_LOGIC_VECTOR (11 DOWNTO 0);
signal sound_adr_5_num							: natural range 0 to 1042303;
-- for comparisons

signal sound_adr_7		 						: STD_LOGIC_VECTOR (13 DOWNTO 0);
signal sound_adr_7_num							: natural range 0 to 1042303;
-- for comparisons

-- hard coded sound memory
-- address intervals for each
-- sound 1-7		 

signal sound_adr_4_state 						: std_logic := '0'; 
														-- initial state	

-- not using bit 0,
-- only bit 1 to 5

signal sound_prev 								: std_logic_vector (6 downto 0)
														:="0000000" ;

--signals for audio codec
signal fm_data_16_bit	 						: signed (8 DOWNTO 0) 
														:="000000000"; 

signal rocket_rotate_rom_read					: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 
signal rocket_thrust_rom_read					: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 
signal rocket_shooting_rom_read				: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 
signal background_ambience_rom_read			: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 
signal explosion_rom_read						: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 
signal saucer_shooting_rom_read				: STD_LOGIC_VECTOR (7 DOWNTO 0) ; 


-------------------------------------------------------------------------------
begin

-----------------------------------------------------------------------------
-- rocket rotate sound ROM 																--
-----------------------------------------------------------------------------
rocket_rotate_sound :	component rocket_rotate 
								port map (
								address	=> sound_adr_1,
								clock	 	=> clock_50,
								q	 		=> rocket_rotate_rom_read
								);

rocket_thrust_sound :	component rocket_thrust 
								port map (
								address	=> sound_adr_2,
								clock	 	=> clock_50,
								q	 		=> rocket_thrust_rom_read
								);


rocket_shooting_sound :	component rocket_shooting 
								port map (
								address	=> sound_adr_3,
								clock	 	=> clock_50,
								q	 		=> rocket_shooting_rom_read
								);

explosion_sound 		:	component explosion 
								port map (
								address	=> sound_adr_4,
								clock	 	=> clock_50,
								q	 		=> explosion_rom_read
								);
																		
saucer_shooting_sound :	component saucer_shooting 
								port map (
								address	=> sound_adr_5,
								clock	 	=> clock_50,
								q	 		=> saucer_shooting_rom_read
								);
										
																		
background_ambience :	component bakam 
								port map (
								address	=> sound_adr_7,
								clock	 	=> clock_50,
								q	 		=> background_ambience_rom_read
								);
								
-----------------------------------------------------------------------------
-- Sound sample retrieval																	--	
-- sound by sound, sample by sample														--
-- 11 kHz 									 													--
-- 8 bit																							--
----------------------------------------------------------------------------- 
process (clock_50)
begin
	if rising_edge (clock_50)then
		if audio_gate = '1' then

			sound_prev(4) <= sound_switch(4); 	

			case state is

			when FREQ_COUNT =>
				sample_rate_count <= sample_rate_count +1;
				if sample_rate_count > 4535 then   -- 12kHz 
					state <= READ_BYTE;
					sample_rate_count <= 1;
				else
					state <= FREQ_COUNT;
				end if;
				
				if sound_prev(4) = '0' and sound_switch(4) = '1' then
				-- explosion single shot verification, '0' means ready for 
				-- single shot
					sound_adr_4_state	<= '1';  -- '1' means single shot ongoing
					sound_adr_4 		<= (others => '0'); -- set to start of sound
					sound_adr_4_num 	<= 0;  -- set to start of sound
				end if;

			when READ_BYTE =>    -- read byte

				-- 1 = rocket rotate
				if sound_switch(1) = '1' then
					fm_data_low_1 <= signed (rocket_rotate_rom_read);	
				else
					fm_data_low_1 <= "00000000"; -- set to '0' if sound is not on
				end if;		

				-- 2 = rocket thrust
				if sound_switch(2) = '1' then
					fm_data_low_2 <= signed (rocket_thrust_rom_read);
						-- read sample if sound is active
				else
					fm_data_low_2 <=  "00000000"; -- set to '0' if sound is not on
				end if;

				-- 3 = rocket shooting
				if sound_switch(3) = '1' then
					fm_data_low_3 <= signed (rocket_shooting_rom_read);
						-- read sample if sound is active
				else
					fm_data_low_3 <=  "00000000"; -- set to '0' if sound is not on
				end if;

				-- 4 = rocket & saucer explosion
				if sound_adr_4_state = '1' then  -- single shot ongoing
					fm_data_low_4 <= signed (explosion_rom_read);
						-- read sample if sound is active
				else
					fm_data_low_4 <=  "00000000"; -- set to '0' if sound is not on
				end if;			

				-- 5 = saucer shooting
				if sound_switch(5) = '1' then
					fm_data_low_5 <= signed (saucer_shooting_rom_read);       
						-- read sample if sound is active
				else
					fm_data_low_5 <=  "00000000"; -- set to '0' if sound is not on
				end if;

				-- 7 = background ambience
				fm_data_low_7 <= signed (background_ambience_rom_read);       

				-- increase adress pointers
				-- 1 = rocket rotate : loop
				if sound_adr_1_num < 4529 then  
					sound_adr_1 <= sound_adr_1 + 1;
					sound_adr_1_num <= sound_adr_1_num + 1;
				else
					sound_adr_1 <= (others => '0');
					sound_adr_1_num <= 0;
				end if;	
					
				-- 2 = rocket thrust : loop
				if sound_adr_2_num < 5067 then  
					sound_adr_2 		<= sound_adr_2 + 1;
					sound_adr_2_num 	<= sound_adr_2_num + 1;
				else
					sound_adr_2 		<= (others => '0');
					sound_adr_2_num 	<= 0;
				end if;
				
				-- 3 = rocket shooting : loop
				if sound_adr_3_num < 20072 then  
					sound_adr_3 		<= sound_adr_3 + 1;
					sound_adr_3_num 	<= sound_adr_3_num + 1;
				else
					sound_adr_3 		<= (others => '0');
					sound_adr_3_num 	<= 0;
				end if;

					
				-- 4 = rocket & saucer explosion/single shot
				-- no loop
				if sound_adr_4_num < 8781 then  
					sound_adr_4 		<= sound_adr_4 + 1;
					sound_adr_4_num 	<= sound_adr_4_num + 1;
				else
					sound_adr_4_state <= '0'; -- single shot ongoing <= '1'; 
													  -- single shot is complete
					sound_adr_4 		<= (others => '0');
					sound_adr_4_num 	<= 0;
				end if;	
					
				-- 5 = saucer shooting : loop
				if sound_adr_5_num < 6636 then  
					sound_adr_5 		<= sound_adr_5 + 1;
					sound_adr_5_num 	<= sound_adr_5_num + 1;
				else
					sound_adr_5 		<= (others => '0');
					sound_adr_5_num 	<= 0;
				end if;	
				
				-- 7 = background ambience : loop
				if sound_adr_7_num < 13874 then  
					sound_adr_7 		<= sound_adr_7 + 1;
					sound_adr_7_num 	<= sound_adr_7_num + 1;
				else
					sound_adr_7 		<= (others => '0');
					sound_adr_7_num 	<= 0;
				end if;				
				
				state <= MERGE_SOUNDS;				
				
			when MERGE_SOUNDS =>    -- read byte	
			-- transfer read data and fix endian (from little endian to big endian)
				
				sigma_delta_wav <=(fm_data_low_1(7) & fm_data_low_1(7) & fm_data_low_1 & "000000") + 
										(fm_data_low_2(7) & fm_data_low_2(7) & fm_data_low_2 & "000000") + 
										(fm_data_low_3(7) & fm_data_low_3(7) & fm_data_low_3 & "000000") + 
										(fm_data_low_4(7) & fm_data_low_4(7) & fm_data_low_4 & "000000") + 
										(fm_data_low_5(7) & fm_data_low_5(7) & fm_data_low_5(7) & fm_data_low_5 & "00000") + 
										(fm_data_low_7(7) & fm_data_low_7(7) & fm_data_low_7 & "000000");
  
				state <= FREQ_COUNT;
	
			when others =>
				state <= FREQ_COUNT;
				
			end case;
		end if;
	end if;
end process;

end sound_architecture;
