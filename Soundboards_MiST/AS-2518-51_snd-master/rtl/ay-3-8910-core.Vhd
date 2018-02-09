library IEEE;
use IEEE.std_logic_1164.all;
Use IEEE.std_logic_arith.all;
Use IEEE.std_logic_unsigned.all;

-- (async) 5 to 8-bit linear to log value convolver
entity lin5_to_log8 is
port
(
    a       : in    std_logic_vector(4 downto 0);
    o       : out   std_logic_vector(7 downto 0)
);
end lin5_to_log8;

architecture rtl of lin5_to_log8 is
begin
    o <= X"00" when a = "00000" else
         X"01" when a = "00001" else
         X"01" when a = "00010" else
         X"02" when a = "00011" else
         X"02" when a = "00100" else
         X"02" when a = "00101" else
         X"03" when a = "00110" else
         X"04" when a = "00111" else
         X"04" when a = "01000" else 
         X"05" when a = "01001" else
         X"06" when a = "01010" else
         X"08" when a = "01011" else
         X"09" when a = "01100" else
         X"0B" when a = "01101" else
         X"0D" when a = "01110" else
         X"10" when a = "01111" else
         X"13" when a = "10000" else
         X"16" when a = "10001" else
         X"1B" when a = "10010" else
         X"20" when a = "10011" else
         X"26" when a = "10100" else
         X"2D" when a = "10101" else
         X"36" when a = "10110" else
         X"40" when a = "10111" else
         X"4C" when a = "11000" else
         X"5A" when a = "11001" else
         X"6B" when a = "11010" else
         X"80" when a = "11011" else
         X"98" when a = "11100" else
         X"B5" when a = "11101" else
         X"D7" when a = "11110" else
         X"FF" when a = "11111";
end rtl;



library IEEE;
use IEEE.std_logic_1164.all;
Use IEEE.std_logic_arith.all;
Use IEEE.std_logic_unsigned.all;

-- AY-3-8910 sound generator
-- Internals
entity ay_3_8910_core is
port
(
    clk         : in    std_logic;
    reset       : in    std_logic;
    clk_en      : in    std_logic;      -- Clock enable pulse - this should occur between 1 and 2.5MHz

    -- Registers
    TPA         : in    std_logic_vector(11 downto 0);  -- Tone generator period channel A
    TPB         : in    std_logic_vector(11 downto 0);  -- Tone generator period channel B
    TPC         : in    std_logic_vector(11 downto 0);  -- Tone generator period channel C
    NGP         : in    std_logic_vector(4 downto 0);   -- Noise generator period
    MCIOEN      : in    std_logic_vector(7 downto 0);   -- Mixer, control and I/O enable
    ACA         : in    std_logic_vector(4 downto 0);   -- Amplitude control channel A
    ACB         : in    std_logic_vector(4 downto 0);   -- Amplitude control channel B
    ACC         : in    std_logic_vector(4 downto 0);   -- Amplitude control channel C
    EPC         : in    std_logic_vector(15 downto 0);  -- Envelope period control
    ESR         : in    std_logic_vector(3 downto 0);   -- Envelope shape/cycle control
    ESR_updated : in    std_logic;                      -- ESR was written, reset envelope

    -- Sound output
    snd_A       : out   std_logic_vector(7 downto 0);
    snd_B       : out   std_logic_vector(7 downto 0);
    snd_C       : out   std_logic_vector(7 downto 0);

    -- Test outputs
    deb_clk16_en : out std_logic;
    deb_clk1256_en : out std_logic;
    deb_wave_A : out std_logic;
    deb_wave_B : out std_logic;
    deb_wave_C : out std_logic;
    deb_noise_out   : out std_logic;
    deb_mixed_A     : out std_logic;
    deb_mixed_B     : out std_logic;
    deb_mixed_C : out std_logic;
    deb_env_out   : out std_logic_vector(3 downto 0);
    deb_ampl_A   : out std_logic_vector(3 downto 0);
    deb_ampl_B    : out std_logic_vector(3 downto 0);
    deb_ampl_C   : out std_logic_vector(3 downto 0);
    deb_psnd_A    : out std_logic_vector(4 downto 0);
    deb_psnd_B   : out std_logic_vector(4 downto 0);
    deb_psnd_C   : out std_logic_vector(4 downto 0);
    deb_ef_cont : out std_logic;
    deb_ef_attack : out std_logic;
    deb_ef_alt : out std_logic;
    deb_ef_hold : out std_logic;

    deb_div_cnt  : out std_logic_vector(7 downto 0);
    deb_tcnt_A   : out std_logic_vector(11 downto 0);
    deb_tcnt_B  : out std_logic_vector(11 downto 0);
    deb_tcnt_C  : out std_logic_vector(11 downto 0);
    deb_nse     : out std_logic_vector(4 downto 0);
    deb_ecnt : out std_logic_vector(15 downto 0);
    deb_ephase : out std_logic_vector(3 downto 0);
    deb_nse_lfsr : out std_logic_vector(17 downto 0);
    deb_noise_in : out std_logic;
    deb_env_holding : out std_logic;
    deb_env_inv : out std_logic

) ;
end ay_3_8910_core;

architecture rtl of ay_3_8910_core is

    signal clk16_en     : std_logic;                    -- High 1/16 of input clock
    signal clk256_en    : std_logic;                    -- High 1/256 of input clock

    signal wave_A       : std_logic;                    -- Square wave A
    signal wave_B       : std_logic;                    -- Square wave B
    signal wave_C       : std_logic;                    -- Square wave C

    signal noise_out    : std_logic;                    -- Noise wave

    signal mixed_A      : std_logic;                    -- Mixed wave A
    signal mixed_B      : std_logic;                    -- Mixed wave B
    signal mixed_C      : std_logic;                    -- Mixed wave C

    signal env_out      : std_logic_vector(3 downto 0); -- Envelope wave

    signal ampl_A       : std_logic_vector(3 downto 0); -- Current amplitude, channel A
    signal ampl_B       : std_logic_vector(3 downto 0); -- Current amplitude, channel B
    signal ampl_C       : std_logic_vector(3 downto 0); -- Current amplitude, channel C

    signal psnd_A       : std_logic_vector(4 downto 0); -- Sound out, channel A, pre lin-log
    signal psnd_B       : std_logic_vector(4 downto 0); -- Sound out, channel A, pre lin-log
    signal psnd_C       : std_logic_vector(4 downto 0); -- Sound out, channel A, pre lin-log

    signal ef_cont      : std_logic;                    -- Envelope continue
    signal ef_attack    : std_logic;                    -- Envelope attack
    signal ef_alt       : std_logic;                    -- Envelope alternate
    signal ef_hold      : std_logic;                    -- Envelope hold

    use work.all;

begin

    -- Magic helper signals
    ef_cont   <= ESR(3);
    ef_attack <= ESR(2);
    ef_alt    <= ESR(1);
    ef_hold   <= ESR(0);

    -- Debug signals
    deb_clk16_en <= clk16_en;
    deb_clk1256_en <= clk256_en;
    deb_wave_A <= wave_A;
    deb_wave_B <= wave_B;
    deb_wave_C <= wave_C;
    deb_noise_out <= noise_out;
    deb_mixed_A <= mixed_A;
    deb_mixed_B <= mixed_B;
    deb_mixed_C <= mixed_C;
    deb_env_out <= env_out;
    deb_ampl_A <= ampl_A;
    deb_ampl_B <= ampl_B;
    deb_ampl_C <= ampl_C;
    deb_psnd_A <= psnd_A;
    deb_psnd_B <= psnd_B;
    deb_psnd_C <= psnd_C;
    deb_ef_cont <= ef_cont;
    deb_ef_attack <= ef_attack;
    deb_ef_alt <= ef_alt;
    deb_ef_hold <= ef_hold;

    -- Waveform mixer scale selection
    ampl_A <= env_out when ACA(4) = '1' else ACA(3 downto 0);
    ampl_B <= env_out when ACB(4) = '1' else ACB(3 downto 0);
    ampl_C <= env_out when ACC(4) = '1' else ACC(3 downto 0);

    -- Waveform output
    psnd_A(4 downto 1) <= ampl_A when mixed_A = '1' else X"0"; psnd_A(0) <= '1';
    psnd_B(4 downto 1) <= ampl_B when mixed_B = '1' else X"0"; psnd_B(0) <= '1';
    psnd_C(4 downto 1) <= ampl_C when mixed_C = '1' else X"0"; psnd_C(0) <= '1';

    -- Instantiate linear to logarithmic output convolvers
    sA_log: entity lin5_to_log8 port map(a => psnd_A, o => snd_A);
    sB_log: entity lin5_to_log8 port map(a => psnd_B, o => snd_B);
    sC_log: entity lin5_to_log8 port map(a => psnd_C, o => snd_C);

    -- Waveform mixers
    mixed_A <= (wave_A or MCIOEN(0)) and (noise_out or MCIOEN(3));
    mixed_B <= (wave_B or MCIOEN(1)) and (noise_out or MCIOEN(4));
    mixed_C <= (wave_C or MCIOEN(2)) and (noise_out or MCIOEN(5));

    -- Main process
    process (clk, clk_en, reset)

        variable div_cnt    : std_logic_vector(7 downto 0); -- Clock divider counter

        variable wave_A_v   : std_logic;                        -- Square wave A
        variable wave_B_v   : std_logic;                        -- Square wave B
        variable wave_C_v   : std_logic;                        -- Square wave C

        variable tcnt_A     : std_logic_vector(11 downto 0);    -- Square wave A period counter
        variable tcnt_B     : std_logic_vector(11 downto 0);    -- Square wave B period counter
        variable tcnt_C     : std_logic_vector(11 downto 0);    -- Square wave C period counter
        variable nse        : std_logic_vector(4 downto 0);     -- Noise period counter

        variable ecnt       : std_logic_vector(15 downto 0);    -- Envelope period counter
        variable ephase     : std_logic_vector(3 downto 0);     -- Envelope waveform counter

        variable nse_lfsr   : std_logic_vector(17 downto 0);    -- Noise generator LFSR
        variable noise_in   : std_logic;

        variable env_holding: std_logic;                        -- Envelope in hold state
        variable env_inv    : std_logic;                        -- Envelope inverted

    begin

        -- Debug signals
        deb_div_cnt <= div_cnt;     -- 7 downto 0
        deb_tcnt_A <= tcnt_A;       -- 11 downto 0
        deb_tcnt_B <= tcnt_B;       -- 11 downto 0
        deb_tcnt_C <= tcnt_C;       -- 11 downto 0
        deb_nse <= nse;             -- 4 downto 0
        deb_ecnt <= ecnt;           -- 15 downto 0
        deb_ephase <= ephase;       -- 3 downto 0
        deb_nse_lfsr <= nse_lfsr;   -- 17 downto 0
        deb_noise_in <= noise_in;
        deb_env_holding <= env_holding;
        deb_env_inv <= env_inv;

        wave_A <= wave_A_v;
        wave_B <= wave_B_v;
        wave_C <= wave_C_v;

        if div_cnt(3 downto 0) = "1111" then
            clk16_en <= '1';
        else
            clk16_en <= '0';
        end if;

--      clk256_en <= (div_cnt = "11111111");

        noise_out <= nse_lfsr(0);

        if reset = '1' then
            wave_A_v    := '0';
            wave_B_v    := '0';
            wave_C_v    := '0';

            div_cnt     := X"00";
            tcnt_A      := X"000";
            tcnt_B      := X"000";
            tcnt_C      := X"000";
            nse_lfsr    := "000000000000000000";
            
            ecnt        := X"0000";
            ephase      := X"0";
            env_holding := '0';
            env_inv     := '0';

        elsif rising_edge(clk) then

            if clk_en = '1' then
                -- Clock divider
                div_cnt := div_cnt + 1;

                -- Envelope shape/cycle control updated, reset envelope state
                if ESR_updated = '1' then
                    ecnt        := X"0000";
                    ephase      := X"0";
                    env_holding := '0';
                    env_inv     := '0';
                end if;

                -- Envelope waveform generation
                -- Envelope holding
                if env_holding = '1' then
                    if ef_cont = '1' then
                        env_out(3) <= (ef_attack xor ef_alt);
                        env_out(2) <= (ef_attack xor ef_alt);
                        env_out(1) <= (ef_attack xor ef_alt);
                        env_out(0) <= (ef_attack xor ef_alt);
                    else
                        env_out <= X"0";
                    end if;
                -- Otherwise envelope is a function of ephase
                else
                    env_out(3) <= ((not ef_attack) xor env_inv) xor ephase(3);
                    env_out(2) <= ((not ef_attack) xor env_inv) xor ephase(2);
                    env_out(1) <= ((not ef_attack) xor env_inv) xor ephase(1);
                    env_out(0) <= ((not ef_attack) xor env_inv) xor ephase(0);
                end if;
                    
                -- Events with period clk/16
                if clk16_en = '1' then
                    -- Tone generator counters
                    -- Channel A
                    if unsigned(tcnt_A) >= unsigned(TPA) then
                        wave_A_v := not wave_A_v;
                        tcnt_A := X"000";
                    else
                        tcnt_A := tcnt_A + 1;
                    end if;
                    
                    -- Channel B
                    if unsigned(tcnt_B) >= unsigned(TPB) then
                        wave_B_v := not wave_B_v;
                        tcnt_B := X"000";
                    else
                        tcnt_B := tcnt_B + 1;
                    end if;

                    -- Channel C
                    if unsigned(tcnt_C) >= unsigned(TPC) then
                        wave_C_v := not wave_C_v;
                        tcnt_C := X"000";
                    else
                        tcnt_C := tcnt_C + 1;
                    end if;

                    -- Noise period counter and LFSR
                    if nse >= NGP then
                        nse := "00000";
                        noise_in := nse_lfsr(0) xnor nse_lfsr(3);        -- Input = bit 0 xor bit 3
                        nse_lfsr(16 downto 0) := nse_lfsr(17 downto 1); -- Shift right - bit 0 is output bit
                        nse_lfsr(17) := noise_in;                       -- Bit 16 is input bit
                    else
                        nse := nse + 1;
                    end if;
                    
                    -- Envelope counters
                    if ecnt >= EPC then
                        if ephase = "1111" then
                            -- If hold flag is set, latch hold value after one envelope cycle
                            if ef_hold = '1' or ef_cont = '0' then
                                env_holding := '1';
                            end if;
                            
                            -- If alternate flag is set, toggle inverted flag
                            if ef_alt = '1' then
                                env_inv := not env_inv;
                            end if;
                            ephase := X"0";
                        else
                            ephase := ephase + 1;
                        end if;
                        ecnt := X"0000";
                    else
                        ecnt := ecnt + 1;
                    end if;

                end if;

                -- Events with period clk/256
--              if clk256_en = '1' then
--              end if;

            end if;
        end if;
    end process;
end rtl;



