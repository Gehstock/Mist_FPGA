------------------------------------------------------------------------------
-- FPGA GALAXIAN
--
-- Version  downto  2.50
--
-- Copyright(c) 2004 Katsumi Degawa , All rights reserved
--
-- Important  not
--
-- This program is freeware for non-commercial use.
-- The author does not guarantee this program.
-- You can use this at your own risk.
--
-- 2004- 4-30  galaxian modify by K.DEGAWA
-- 2004- 5- 6  first release.
-- 2004- 8-23  Improvement with T80-IP.
-- 2004- 9-22  The problem which missile didn't sometimes come out from was improved.
------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

--use work.pkg_galaxian.all;

entity galaxian is
	port(
		W_CLK_18M  : in  std_logic;
		W_CLK_12M  : in  std_logic;
		W_CLK_6M   : in  std_logic;

		P1_CSJUDLR : in  std_logic_vector(6 downto 0);
		P2_CSJUDLR : in  std_logic_vector(6 downto 0);
		I_RESET    : in  std_logic;

		W_R        : out std_logic_vector(2 downto 0);
		W_G        : out std_logic_vector(2 downto 0);
		W_B        : out std_logic_vector(1 downto 0);
		HBLANK     : out std_logic;
		VBLANK     : out std_logic;
		W_H_SYNC   : out std_logic;
		W_V_SYNC   : out std_logic;
		O_AUDIO    : out std_logic_vector( 9 downto 0);
		O_CMPBL    : out std_logic
	);
end;

architecture RTL of galaxian is
	--    CPU ADDRESS BUS
	signal W_A                : std_logic_vector(15 downto 0) := (others => '0');
	--    CPU IF
	signal W_CPU_CLK          : std_logic := '0';
	signal W_CPU_MREQn        : std_logic := '0';
	signal W_CPU_NMIn         : std_logic := '0';
	signal W_CPU_RDn          : std_logic := '0';
	signal W_CPU_RFSHn        : std_logic := '0';
	signal W_CPU_WAITn        : std_logic := '0';
	signal W_CPU_WRn          : std_logic := '0';
	signal W_CPU_WR           : std_logic := '0';
	signal W_RESETn           : std_logic := '0';
	-------- H and V COUNTER -------------------------
	signal W_C_BLn            : std_logic := '0';
	signal W_C_BLnX           : std_logic := '0';
	signal W_C_BLXn           : std_logic := '0';
	signal W_H_BL             : std_logic := '0';
	signal W_H_SYNC_int       : std_logic := '0';
	signal W_V_BLn            : std_logic := '0';
	signal W_V_BL2n           : std_logic := '0';
	signal W_V_SYNC_int       : std_logic := '0';
	signal W_H_CNT            : std_logic_vector(8 downto 0) := (others => '0');
	signal W_V_CNT            : std_logic_vector(7 downto 0) := (others => '0');
	-------- CPU RAM  ----------------------------
	signal W_CPU_RAM_DO       : std_logic_vector(7 downto 0) := (others => '0');
	-------- ADDRESS DECDER ----------------------
	signal W_BD_G             : std_logic := '0';
	signal W_CPU_RAM_CS       : std_logic := '0';
	signal W_CPU_RAM_RD       : std_logic := '0';
--	signal W_CPU_RAM_WR       : std_logic := '0';
	signal W_DIP_OE           : std_logic := '0';
	signal W_H_FLIP           : std_logic := '0';
	signal W_DRIVER_WE        : std_logic := '0';
	signal W_OBJ_RAM_RD       : std_logic := '0';
	signal W_OBJ_RAM_RQ       : std_logic := '0';
	signal W_OBJ_RAM_WR       : std_logic := '0';
	signal W_STARS_ON         : std_logic := '0';
	signal W_STARS_OFFn       : std_logic := '0';
	signal W_SW0_OE           : std_logic := '0';
	signal W_SW1_OE           : std_logic := '0';
	signal W_V_FLIP           : std_logic := '0';
	signal W_VID_RAM_RD       : std_logic := '0';
	signal W_VID_RAM_WR       : std_logic := '0';
	signal W_WDR_OE           : std_logic := '0';
	--------- INPORT -----------------------------
	signal W_SW_DO            : std_logic_vector( 7 downto 0) := (others => '0');
	--------- VIDEO  -----------------------------
	signal W_VID_DO           : std_logic_vector( 7 downto 0) := (others => '0');
	-----  DATA I/F -------------------------------------
	signal W_CPU_ROM0_DO       : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_CPU_ROM1_DO       : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_CPU_ROM_DOB      : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_BDO              : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_BDI              : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_CPU_RAM_CLK      : std_logic := '0';
	signal W_FS               : std_logic_vector( 2 downto 0) := (others => '0');

	signal blx_comb           : std_logic := '0';
	signal W_1VF              : std_logic := '0';
	signal W_256HnX           : std_logic := '0';
	signal W_8HF              : std_logic := '0';
	signal W_MISSILEn         : std_logic := '0';
	signal W_SHELLn           : std_logic := '0';
	signal W_MS_D             : std_logic := '0';
	signal W_MS_R             : std_logic := '0';
	signal W_MS_G             : std_logic := '0';
	signal W_MS_B             : std_logic := '0';

	signal in_game            : std_logic_vector( 1 downto 0) := (others => '0');
	signal ROM_D              : std_logic_vector( 7 downto 0) := (others => '0');
	signal rst_count          : std_logic_vector( 3 downto 0) := (others => '0');
	signal W_COL              : std_logic_vector( 2 downto 0) := (others => '0');
	signal W_STARS_B          : std_logic_vector( 1 downto 0) := (others => '0');
	signal W_STARS_G          : std_logic_vector( 1 downto 0) := (others => '0');
	signal W_STARS_R          : std_logic_vector( 1 downto 0) := (others => '0');
	signal W_VID              : std_logic_vector( 1 downto 0) := (others => '0');
	signal W_VIDEO_B          : std_logic_vector( 1 downto 0) := (others => '0');
	signal W_VIDEO_G          : std_logic_vector( 2 downto 0) := (others => '0');
	signal W_VIDEO_R          : std_logic_vector( 2 downto 0) := (others => '0');
	signal W_GFX_BANK         : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_GFX_BANK_WR      : std_logic := '0';
	signal W_PROT_DO          : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_PROT_DOB         : std_logic_vector( 7 downto 0) := (others => '0');
	signal PSG_EN             : std_logic := '0';
	signal PSG_D              : std_logic_vector(7 downto 0);
	signal PSG_A,PSG_B,PSG_C  : std_logic_vector(7 downto 0);
	signal sel          : std_logic_vector( 3 downto 0) := (others => '0');
	
component ym2149
	port (
		CLK       : in  std_logic;
		CE        : in  std_logic;
		RESET     : in  std_logic;
		BDIR      : in  std_logic;
		BC        : in  std_logic;
		DI        : in  std_logic_vector(7 downto 0);
		DO        : out std_logic_vector(7 downto 0);
		CHANNEL_A : out std_logic_vector(7 downto 0);
		CHANNEL_B : out std_logic_vector(7 downto 0);
		CHANNEL_C : out std_logic_vector(7 downto 0)
	);
	end component;


begin
	mc_vid : entity work.MC_VIDEO
	port map(
		I_CLK_18M     => W_CLK_18M,
		I_CLK_12M     => W_CLK_12M,
		I_CLK_6M      => W_CLK_6M,
		I_H_CNT       => W_H_CNT,
		I_V_CNT       => W_V_CNT,
		I_H_FLIP      => W_H_FLIP,
		I_V_FLIP      => W_V_FLIP,
		I_V_BLn       => W_V_BLn,
		I_C_BLn       => W_C_BLn,
		I_A           => W_A(10 downto 0),
		I_OBJ_SUB_A   => "000",
		I_BD          => W_BDI,
		I_OBJ_RAM_RQ  => W_OBJ_RAM_RQ,
		I_OBJ_RAM_RD  => W_OBJ_RAM_RD,
		I_OBJ_RAM_WR  => W_OBJ_RAM_WR,
		I_VID_RAM_RD  => W_VID_RAM_RD,
		I_VID_RAM_WR  => W_VID_RAM_WR,
		I_DRIVER_WR   => W_DRIVER_WE,
		I_BANK        => W_GFX_BANK,
		O_C_BLnX      => W_C_BLnX,
		O_8HF         => W_8HF,
		O_256HnX      => W_256HnX,
		O_1VF         => W_1VF,
		O_MISSILEn    => W_MISSILEn,
		O_SHELLn      => W_SHELLn,
		O_BD          => W_VID_DO,
		O_VID         => W_VID,
		O_COL         => W_COL
	);

	cpu : entity work.T80as
	port map (
		RESET_n       => W_RESETn,
		CLK_n         => W_CPU_CLK,
		WAIT_n        => W_CPU_WAITn,
		INT_n         => '1',
		NMI_n         => W_CPU_NMIn,
		BUSRQ_n       => '1',
		MREQ_n        => W_CPU_MREQn,
		RD_n          => W_CPU_RDn,
		WR_n          => W_CPU_WRn,
		RFSH_n        => W_CPU_RFSHn,
		A             => W_A,
		DI            => W_BDO,
		DO            => W_BDI,
		M1_n          => open,
		IORQ_n        => open,
		HALT_n        => open,
		BUSAK_n       => open,
		DOE           => open
	);

	mc_cpu_ram : entity work.MC_CPU_RAM
	port map (
		I_CLK         => W_CPU_RAM_CLK,
		I_ADDR        => W_A(10 downto 0),
		I_D           => W_BDI,
		I_WE          => W_CPU_WR,
		I_OE          => W_CPU_RAM_RD,
		O_D           => W_CPU_RAM_DO
	);

	mc_adec : entity work.MC_ADEC
	port map(
		I_CLK_12M     => W_CLK_12M,
		I_CLK_6M      => W_CLK_6M,
		I_CPU_CLK     => W_CPU_CLK,
		I_RSTn        => W_RESETn,

		I_CPU_A       => W_A,
		I_CPU_D       => W_BDI(0),
		I_MREQn       => W_CPU_MREQn,
		I_RFSHn       => W_CPU_RFSHn,
		I_RDn         => W_CPU_RDn,
		I_WRn         => W_CPU_WRn,
		I_H_BL        => W_H_BL,
		I_V_BLn       => W_V_BLn,

		O_WAITn       => W_CPU_WAITn,
		O_NMIn        => W_CPU_NMIn,
--		O_CPU_ROM_CS  => W_CPU_ROM_CS,
		O_CPU_RAM_RD  => W_CPU_RAM_RD,
--		O_CPU_RAM_WR  => W_CPU_RAM_WR,
		O_CPU_RAM_CS  => W_CPU_RAM_CS,
--		O_OBJ_RAM_RD  => W_OBJ_RAM_RD,
--		O_OBJ_RAM_WR  => W_OBJ_RAM_WR,
		O_OBJ_RAM_RQ  => W_OBJ_RAM_RQ,
--		O_VID_RAM_RD  => W_VID_RAM_RD,
--		O_VID_RAM_WR  => W_VID_RAM_WR,
		O_SW0_OE      => W_SW0_OE,
		O_SW1_OE      => W_SW1_OE,
		O_DIP_OE      => W_DIP_OE,
		O_WDR_OE      => W_WDR_OE,
		O_DRIVER_WE   => W_DRIVER_WE,
--		O_SOUND_WE    => W_SOUND_WE,
--		O_PITCH       => W_PITCH,
		O_H_FLIP      => W_H_FLIP,
		O_V_FLIP      => W_V_FLIP,
		O_BD_G        => W_BD_G,
		O_STARS_ON    => W_STARS_ON
	);

W_VID_RAM_RD <= '1' when W_CPU_RDn = '0' and (W_A(15 downto 11) = "01001") else '0';--0100 1000 0000 0000 		4800
W_VID_RAM_WR <= '1' when W_CPU_WR = '1' and (W_A(15 downto 11) = "01001") else '0';--0100 1100 0000 0000

W_OBJ_RAM_RD <= '1' when W_CPU_RDn = '0' and (W_A(15 downto 11) = "01010") else '0';--0101 0000 0000 0000		5000
W_OBJ_RAM_WR <= '1' when W_CPU_WR = '1' and (W_A(15 downto 11) = "01010") else '0';--0101 0000 0000 0000

	-- active high buttons
	mc_inport : entity work.MC_INPORT
	port map (
		I_COIN1       => P1_CSJUDLR(6),
		I_COIN2       => P2_CSJUDLR(6),
		I_1P_START    => P1_CSJUDLR(5),
		I_2P_START    => P2_CSJUDLR(5),
		I_1P_SH       => P1_CSJUDLR(4),
		I_2P_SH       => P2_CSJUDLR(4),
		I_1P_LE       => P1_CSJUDLR(1),
		I_2P_LE       => P2_CSJUDLR(1),
		I_1P_RI       => P1_CSJUDLR(0),
		I_2P_RI       => P2_CSJUDLR(0),
		I_1P_UP       => P1_CSJUDLR(3),
		I_2P_UP       => P2_CSJUDLR(3),
		I_1P_DW       => P1_CSJUDLR(2),
		I_2P_DW       => P2_CSJUDLR(2),
		I_SW0_OE      => W_SW0_OE,
		I_SW1_OE      => W_SW1_OE,
		I_DIP_OE      => W_DIP_OE,
		O_D           => W_SW_DO
	);

	mc_hv : entity work.MC_HV_COUNT
	port map(
		I_CLK         => W_CLK_6M,
		I_RSTn        => W_RESETn,
		O_H_CNT       => W_H_CNT,
		O_H_SYNC      => W_H_SYNC_int,
		O_H_BL        => W_H_BL,
		O_V_CNT       => W_V_CNT,
		O_V_SYNC      => W_V_SYNC_int,
		O_V_BL2n      => W_V_BL2n,
		O_V_BLn       => W_V_BLn,
		O_C_BLn       => W_C_BLn
	);

	mc_col_pal : entity work.MC_COL_PAL
	port map(
		I_CLK_12M     => W_CLK_12M,
		I_CLK_6M      => W_CLK_6M,
		I_VID         => W_VID,
		I_COL         => W_COL,
		I_C_BLnX      => W_C_BLnX,
		O_C_BLXn      => W_C_BLXn,
		O_STARS_OFFn  => W_STARS_OFFn,
		O_R           => W_VIDEO_R,
		O_G           => W_VIDEO_G,
		O_B           => W_VIDEO_B
	);

	mc_stars : entity work.MC_STARS
	port map (
		I_CLK_18M     => W_CLK_18M,
		I_CLK_6M      => W_CLK_6M,
		I_H_FLIP      => W_H_FLIP,
		I_V_SYNC      => W_V_SYNC_int,
		I_8HF         => W_8HF,
		I_256HnX      => W_256HnX,
		I_1VF         => W_1VF,
		I_2V          => W_V_CNT(1),
		I_STARS_ON    => W_STARS_ON,
		I_STARS_OFFn  => W_STARS_OFFn,
		O_R           => W_STARS_R,
		O_G           => W_STARS_G,
		O_B           => W_STARS_B,
		O_NOISE       => open
	);

--------- ROM           -------------------------------------------------------
	mc_roms1 : entity work.program0
	port map (
		CLK  => W_CLK_12M,
		ADDR => W_A(13 downto 0),
		DATA => W_CPU_ROM0_DO
	);
	
	mc_romsw : entity work.program1
	port map (
		CLK  => W_CLK_12M,
		ADDR => W_A(13 downto 0),
		DATA => W_CPU_ROM1_DO
	);
	
	W_PROT_DO <= X"4F" when (W_A(11 downto 0) = X"114") else--01 0001 0100
                X"D3" when (W_A(11 downto 0) = X"118") else
                X"CF" when (W_A(11 downto 0) = X"214") else
                X"02" when (W_A(11 downto 0) = X"235") else
                X"FF" when (W_A(11 downto 0) = X"311") else--11 0001 0001
                X"FF";


-------- VIDEO  -----------------------------
	blx_comb <= not ( W_C_BLXn and W_V_BL2n );
	W_V_SYNC <= not W_V_SYNC_int;
	W_H_SYNC <= not W_H_SYNC_int;
	O_CMPBL  <= W_C_BLnX;
	
	-- MISSILE => Yellow ;
	-- SHELL   => White  ;
	W_MS_D <= not (W_MISSILEn and W_SHELLn);
	W_MS_R <= not   blx_comb  and W_MS_D;
	W_MS_G <= not   blx_comb  and W_MS_D;
	W_MS_B <= not   blx_comb  and W_MS_D and not W_SHELLn ;

	W_R <= W_VIDEO_R or (W_STARS_R & "0") or (W_MS_R & W_MS_R & "0");
	W_G <= W_VIDEO_G or (W_STARS_G & "0") or (W_MS_G & W_MS_G & "0");
	W_B <= W_VIDEO_B or (W_STARS_B) or (W_MS_B & W_MS_B);

	process(W_CLK_6M)
	begin
		if rising_edge(W_CLK_6M) then
			HBLANK   <= not W_C_BLXn;
			VBLANK   <= not W_V_BL2n;
		end if;
	end process;


-----  CPU I/F  -------------------------------------

	W_CPU_CLK     <= W_H_CNT(0);
	W_CPU_RAM_CLK <= W_CLK_12M and W_CPU_RAM_CS;

	W_CPU_ROM_DOB <= 	W_CPU_ROM0_DO when (W_A(15 downto 0) >= x"0000") and (W_A(15 downto 0) < x"4000") and W_CPU_RDn = '0' else
							W_CPU_ROM1_DO when (W_A(15 downto 0) >= x"8000") and (W_A(15 downto 0) < x"B000") and W_CPU_RDn = '0' else (others=>'0');
							
	W_PROT_DOB    <= W_PROT_DO when (W_A(15 downto 12) = "1011") else (others=>'0');

	W_RESETn  <= not I_RESET;
	W_BDO     <= W_SW_DO  or W_VID_DO or W_CPU_RAM_DO or W_CPU_ROM_DOB or W_PROT_DOB;
	W_CPU_WR  <= not W_CPU_WRn;
	W_GFX_BANK_WR <= '1' when W_CPU_WR = '1' and (W_A(15 downto 4) = X"600") else '0';

sel <= W_A(3 downto 0);	
	
process(W_CLK_18M, W_GFX_BANK_WR, W_BDI) begin
	if (W_GFX_BANK_WR = '1') then
		case (sel) is
			when "0010" =>   W_GFX_BANK(0) <= W_BDI(0);
			when "0011" =>   W_GFX_BANK(1) <= W_BDI(0);
			when "0100" =>   W_GFX_BANK(2) <= W_BDI(0);
			when "0101" =>   W_GFX_BANK(3) <= W_BDI(0);
			when "0110" =>   W_GFX_BANK(4) <= W_BDI(0);
			when others =>
		end case;
	end if;
end process;
	
	
	process(W_CPU_CLK, I_RESET)
	begin
		if (I_RESET = '1') then
			rst_count <= (others => '0');
		elsif rising_edge( W_CPU_CLK) then
			if ( rst_count /= x"f") then
				rst_count <= rst_count + 1;
			end if;
		end if;
	end process;

--	0100 1000 0000 0000 x4800
-- 0101 1000 0000 0000 x5800
-- 0101 1001 0000 0000 x5900

--	map(0x5800, 0x5800).mirror(0x00ff).w("8910.0", FUNC(ay8910_device::data_w));
--	map(0x5900, 0x5900).mirror(0x00ff).w("8910.0", FUNC(ay8910_device::address_w));

	PSG_EN <= '1' when (W_A(15 downto 11) = "01011" and W_A(7 downto 0) = X"00") else '0';

	process(W_CPU_CLK)
	begin
		if rising_edge(W_CPU_CLK) then
			if PSG_EN = '1' and W_A(8) = '1' then
				PSG_D <= W_A(7 downto 0);
			end if;
		end if;
	end process;

	O_AUDIO <= ("00" & PSG_A) + ("00" & PSG_B) + ("00" & PSG_C);

	psg : ym2149
	port map (
		CLK       => W_CPU_CLK,
		CE        => '1',
		RESET     => I_RESET,
		BDIR      => PSG_EN and W_A(0) and not W_A(8),
		BC        => W_A(1),
		DI        => PSG_D,
		CHANNEL_A => PSG_A,
		CHANNEL_B => PSG_B,
		CHANNEL_C => PSG_C
);
end RTL;
