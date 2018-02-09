library IEEE;
use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;

-- AY-3-8910 sound generator
-- Chip-level module, registers and decoding
entity ay_3_8910 is
port
(
    -- AY-3-8910 sound controller
    clk         : in    std_logic;
    reset       : in    std_logic;
    clk_en      : in    std_logic;      -- Clock enable pulse - this should occur between 1 and 2.5MHz

    -- CPU I/F
    cpu_d_in    : in    std_logic_vector(7 downto 0);
    cpu_d_out   : out   std_logic_vector(7 downto 0);
    cpu_bdir    : in    std_logic;
    cpu_bc1     : in    std_logic;
    cpu_bc2     : in    std_logic;

    -- I/O I/F
    io_a_in     : in    std_logic_vector(7 downto 0);
    io_b_in     : in    std_logic_vector(7 downto 0);
    io_a_out    : out   std_logic_vector(7 downto 0);
    io_b_out    : out   std_logic_vector(7 downto 0);

    -- Sound output
    snd_A       : out   std_logic_vector(7 downto 0);
    snd_B       : out   std_logic_vector(7 downto 0);
    snd_C       : out   std_logic_vector(7 downto 0)

    -- Debug
    --deb_addr       : out      std_logic_vector(3 downto 0);
    --deb_TPA          : out std_logic_vector(11 downto 0);    -- Tone generator period channel A
    --deb_TPB          : out std_logic_vector(11 downto 0);    -- Tone generator period channel B
    --deb_TPC          : out std_logic_vector(11 downto 0);    -- Tone generator period channel C
    --deb_NGP          : out std_logic_vector(4 downto 0);     -- Noise generator period
    --deb_MCIOEN       : out std_logic_vector(7 downto 0);     -- Mixer, control and I/O enable
    --deb_ACA          : out std_logic_vector(4 downto 0);     -- Amplitude control channel A
    --deb_ACB          : out std_logic_vector(4 downto 0);     -- Amplitude control channel B
    --deb_ACC          : out std_logic_vector(4 downto 0);     -- Amplitude control channel C
    --deb_EPC          : out std_logic_vector(15 downto 0);    -- Envelope period control
    --deb_ESR          : out std_logic_vector(3 downto 0);     -- Envelope shape/cycle control
    --deb_ESR_updated  : out std_logic;                        -- ESR was written, reset envelope

    -- Test outputs
    --deb_clk16_en : out std_logic;
    --deb_clk1256_en : out std_logic;
    --deb_wave_A : out std_logic;
    --deb_wave_B : out std_logic;
    --deb_wave_C : out std_logic;
    --deb_noise_out   : out std_logic;
    --deb_mixed_A     : out std_logic;
    --deb_mixed_B     : out std_logic;
    --deb_mixed_C : out std_logic;
    --deb_env_out   : out std_logic_vector(3 downto 0);
    --deb_ampl_A   : out std_logic_vector(3 downto 0);
    --deb_ampl_B    : out std_logic_vector(3 downto 0);
    --deb_ampl_C   : out std_logic_vector(3 downto 0);
    --deb_psnd_A    : out std_logic_vector(4 downto 0);
    --deb_psnd_B   : out std_logic_vector(4 downto 0);
    --deb_psnd_C   : out std_logic_vector(4 downto 0);
    --deb_ef_cont : out std_logic;
    --deb_ef_attack : out std_logic;
    --deb_ef_alt : out std_logic;
    --deb_ef_hold : out std_logic;

    --deb_div_cnt  : out std_logic_vector(7 downto 0);
    --deb_tcnt_A   : out std_logic_vector(11 downto 0);
    --deb_tcnt_B  : out std_logic_vector(11 downto 0);
    --deb_tcnt_C  : out std_logic_vector(11 downto 0);
    --deb_nse     : out std_logic_vector(4 downto 0);
    --deb_ecnt : out std_logic_vector(15 downto 0);
    --deb_ephase : out std_logic_vector(3 downto 0);
    --deb_nse_lfsr : out std_logic_vector(17 downto 0);
    --deb_noise_in : out std_logic;
    --deb_env_holding : out std_logic;
    --deb_env_inv : out std_logic

) ;
end ay_3_8910;

architecture rtl of ay_3_8910 is
    signal TPA          : std_logic_vector(11 downto 0);    -- Tone generator period channel A
    signal TPB          : std_logic_vector(11 downto 0);    -- Tone generator period channel B
    signal TPC          : std_logic_vector(11 downto 0);    -- Tone generator period channel C
    signal NGP          : std_logic_vector(4 downto 0);     -- Noise generator period
    signal MCIOEN       : std_logic_vector(7 downto 0);     -- Mixer, control and I/O enable
    signal ACA          : std_logic_vector(4 downto 0);     -- Amplitude control channel A
    signal ACB          : std_logic_vector(4 downto 0);     -- Amplitude control channel B
    signal ACC          : std_logic_vector(4 downto 0);     -- Amplitude control channel C
    signal EPC          : std_logic_vector(15 downto 0);    -- Envelope period control
    signal ESR          : std_logic_vector(3 downto 0);     -- Envelope shape/cycle control
    signal PAO          : std_logic_vector(7 downto 0);     -- Port A out
    signal PBO          : std_logic_vector(7 downto 0);     -- Port B out
    signal ESR_updated  : std_logic;                        -- ESR was written, reset envelope

    use work.all;

begin

    -- Connect core sound processing module to input registers
    ay_core: entity ay_3_8910_core port map(clk => clk, reset => reset, clk_en => clk_en,
        TPA => TPA, TPB => TPB, TPC => TPC, NGP => NGP, MCIOEN => MCIOEN, ACA => ACA, ACB => ACB,
        ACC => ACC, EPC => EPC, ESR => ESR, ESR_updated => ESR_updated,
        snd_A => snd_A, snd_B => snd_B, snd_C => snd_C
        --deb_clk16_en => deb_clk16_en,
        --deb_clk1256_en => deb_clk1256_en,
        --deb_wave_A => deb_wave_A,
        --deb_wave_B => deb_wave_B,
        --deb_wave_C => deb_wave_C,
        --deb_noise_out => deb_noise_out,
        --deb_mixed_A => deb_mixed_A,
        --deb_mixed_B => deb_mixed_B,
        --deb_mixed_C => deb_mixed_C,
        --deb_env_out => deb_env_out,
        --deb_ampl_A => deb_ampl_A,
        --deb_ampl_B => deb_ampl_B,
        --deb_ampl_C => deb_ampl_C,
        --deb_psnd_A => deb_psnd_A,
        --deb_psnd_B => deb_psnd_B,
        --deb_psnd_C => deb_psnd_C,
        --deb_ef_cont => deb_ef_cont,
        --deb_ef_attack => deb_ef_attack,
        --deb_ef_alt => deb_ef_alt,
        --deb_ef_hold => deb_ef_hold,
        --deb_div_cnt => deb_div_cnt,
        --deb_tcnt_A => deb_tcnt_A,
        --deb_tcnt_B => deb_tcnt_B,
        --deb_tcnt_C => deb_tcnt_C,
        --deb_nse => deb_nse,
        --deb_ecnt => deb_ecnt,
        --deb_ephase => deb_ephase,
        --deb_nse_lfsr => deb_nse_lfsr,
        --deb_noise_in => deb_noise_in,
        --deb_env_holding => deb_env_holding,
        --deb_env_inv => deb_env_inv

    );

    -- I/O outputs
    io_a_out <= PAO when MCIOEN(6) = '0' else X"FF";
    io_b_out <= PBO when MCIOEN(7) = '0' else X"FF";

    -- Main process
    process (clk, clk_en, reset)
        variable addr           : std_logic_vector(3 downto 0);     -- Addressed register

        variable rTPA           : std_logic_vector(11 downto 0);    -- Tone generator period channel A
        variable rTPB           : std_logic_vector(11 downto 0);    -- Tone generator period channel B
        variable rTPC           : std_logic_vector(11 downto 0);    -- Tone generator period channel C
        variable rNGP           : std_logic_vector(4 downto 0);     -- Noise generator period
        variable rMCIOEN        : std_logic_vector(7 downto 0);     -- Mixer, control and I/O enable
        variable rACA           : std_logic_vector(4 downto 0);     -- Amplitude control channel A
        variable rACB           : std_logic_vector(4 downto 0);     -- Amplitude control channel B
        variable rACC           : std_logic_vector(4 downto 0);     -- Amplitude control channel C
        variable rEPC           : std_logic_vector(15 downto 0);    -- Envelope period control
        variable rESR           : std_logic_vector(3 downto 0);     -- Envelope shape/cycle control
        variable rPAO           : std_logic_vector(7 downto 0);     -- Port A out
        variable rPBO           : std_logic_vector(7 downto 0);     -- Port B out
        variable rESR_updated   : std_logic;                        -- ESR was written, reset envelope
    begin
        TPA <= rTPA;                TPB <= rTPB;
        TPC <= rTPC;                NGP <= rNGP;
        MCIOEN <= rMCIOEN;          ACA <= rACA;
        ACB <= rACB;                ACC <= rACC;
        EPC <= rEPC;                ESR <= rESR;
        PAO <= rPAO;                PBO <= rPBO;
        ESR_updated <= rESR_updated;

        -- Debug
        --deb_addr <= addr;
        --deb_TPA <= TPA;
        --deb_TPB <= TPB;
        --deb_TPC <= TPC;
        --deb_NGP <= NGP;
        --deb_MCIOEN <= MCIOEN;
        --deb_ACA <= ACA;
        --deb_ACB <= ACB;
        --deb_ACC <= ACC;
        --deb_EPC <= EPC;
        --deb_ESR <= ESR;
        --deb_ESR_updated <= ESR_updated;

        if reset = '1' then

            rTPA := X"000";
            rTPB := X"000";
            rTPC := X"000";
            rNGP := "00000";
            rMCIOEN := X"00";
            rACA := "00000";
            rACB := "00000";
            rACC := "00000";
            rEPC := X"0000";
            rESR := X"0";
            rESR_updated := '0';

        elsif rising_edge(clk) then

--            if clk_en = '1' then
                rESR_updated := '0';

                -- Latch address
                if  (cpu_bdir = '0' and cpu_bc2 = '0' and cpu_bc1 = '1') or
                    (cpu_bdir = '1' and cpu_bc2 = '0' and cpu_bc1 = '0') or
                    (cpu_bdir = '1' and cpu_bc2 = '1' and cpu_bc1 = '1') then

                    addr(3 downto 0) := cpu_d_in(3 downto 0);

        -- Data write
                elsif (cpu_bdir = '1' and cpu_bc2 = '1' and cpu_bc1 = '0') then
                    case addr(3 downto 0) is
                    when X"0" => rTPA(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"1" => rTPA(11 downto 8) := cpu_d_in(3 downto 0);
                    when X"2" => rTPB(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"3" => rTPB(11 downto 8) := cpu_d_in(3 downto 0);
                    when X"4" => rTPC(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"5" => rTPC(11 downto 8) := cpu_d_in(3 downto 0);
                    when X"6" => rNGP(4 downto 0) := cpu_d_in(4 downto 0);
                    when X"7" => rMCIOEN(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"8" => rACA(4 downto 0) := cpu_d_in(4 downto 0);
                    when X"9" => rACB(4 downto 0) := cpu_d_in(4 downto 0);
                    when X"A" => rACC(4 downto 0) := cpu_d_in(4 downto 0);
                    when X"B" => rEPC(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"C" => rEPC(15 downto 8) := cpu_d_in(7 downto 0);
                    when X"D" => rESR(3 downto 0) := cpu_d_in(3 downto 0); rESR_updated := '1';
                    when X"E" => rPAO(7 downto 0) := cpu_d_in(7 downto 0);
                    when X"F" => rPBO(7 downto 0) := cpu_d_in(7 downto 0);
                    when others =>
                    end case;

        -- Data read
        elsif (cpu_bdir = '0' and cpu_bc2 = '1' and cpu_bc1 = '1') then
              cpu_d_out <= X"00";
                    case addr(3 downto 0) is
                    when X"0" => cpu_d_out <= rTPA(7 downto 0);
                    when X"1" => cpu_d_out(3 downto 0) <= rTPA(11 downto 8);
                    when X"2" => cpu_d_out <= rTPB(7 downto 0);
                    when X"3" => cpu_d_out(3 downto 0) <= rTPB(11 downto 8);
                    when X"4" => cpu_d_out <= rTPC(7 downto 0);
                    when X"5" => cpu_d_out(3 downto 0) <= rTPC(11 downto 8);
                    when X"6" => cpu_d_out(4 downto 0) <= rNGP(4 downto 0);
                    when X"7" => cpu_d_out <= rMCIOEN(7 downto 0);
                    when X"8" => cpu_d_out(4 downto 0) <= rACA(4 downto 0);
                    when X"9" => cpu_d_out(4 downto 0) <= rACB(4 downto 0);
                    when X"A" => cpu_d_out(4 downto 0) <= rACC(4 downto 0);
                    when X"B" => cpu_d_out <= rEPC(7 downto 0);
                    when X"C" => cpu_d_out <= rEPC(15 downto 8);
                    when X"D" => cpu_d_out(3 downto 0) <= rESR(3 downto 0);
                    when X"E" => cpu_d_out <= io_a_in(7 downto 0);
                    when X"F" => cpu_d_out <= io_b_in(7 downto 0);
                    when others =>
                    end case;
                end if;
--            end if;

        end if;
    end process;
end rtl;

