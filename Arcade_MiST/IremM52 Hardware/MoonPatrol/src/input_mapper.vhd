library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.pace_pkg.all;

entity inputmapper is
	generic
	(
    NUM_DIPS    : integer := 8;
		NUM_INPUTS  : integer := 2
	);
	port
	(
    clk       : in std_logic;
    rst_n     : in std_logic;

    -- inputs from keyboard controller
    reset     : in std_logic;
    key_down  : in std_logic;
    key_up    : in std_logic;
    data      : in std_logic_vector(7 downto 0);
    -- inputs from jamma connector
    jamma			: in from_JAMMA_t;

    -- user outputs
    dips			: in	std_logic_vector(NUM_DIPS-1 downto 0);
    inputs		: out from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1)
	);
end inputmapper;

architecture SYN of inputmapper is

begin

  process (clk, rst_n, dips)
    variable jamma_v	: from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1);
    variable keybd_v 	: from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1);
  begin

       -- note: all inputs are active LOW

      if rst_n = '0' then
        for i in 0 to NUM_INPUTS-1 loop
          jamma_v(i).d := (others =>'1');
          keybd_v(i).d := (others =>'0');
        end loop;
        
      elsif rising_edge (clk) then

        -- handle JAMMA inputs
        jamma_v(0).d(0) := jamma.p(1).start;
        jamma_v(0).d(1) := jamma.p(2).start;
        jamma_v(0).d(2) := jamma.service;
        jamma_v(0).d(3) := jamma.coin(1) and jamma.p(1).button(3);
        jamma_v(1).d(0) := jamma.p(1).right;
        jamma_v(1).d(1) := jamma.p(1).left;
        jamma_v(1).d(2) := jamma.p(1).down;
        jamma_v(1).d(3) := jamma.p(1).up;
        jamma_v(1).d(5) := jamma.p(1).button(2);
        jamma_v(1).d(7) := jamma.p(1).button(1);
        jamma_v(2).d(4) := jamma.coin(2);
        
        
        -- this is PS/2 reset only
        if (reset = '1') then
          for i in 0 to NUM_INPUTS-2 loop
            keybd_v(i).d := (others =>'1');
          end loop;
          keybd_v(NUM_INPUTS-1).d := (others =>'0');
         end if;
      end if; -- rising_edge (clk)

      -- assign outputs
      inputs(0).d <= jamma_v(0).d and not keybd_v(0).d;
      inputs(1).d <= jamma_v(1).d and not keybd_v(1).d;
      inputs(2).d <= jamma_v(2).d and not keybd_v(2).d;
      inputs(3).d <= dips(7 downto 0); --"11111111";  -- 1C/1C, 10/30/50K, 3 lives
		
      inputs(4).d <= dips(15 downto 8);--"11111100";
      -- activate service which is only checked on startup
     -- inputs(4).d <= "01111100";
      inputs(NUM_INPUTS-1).d <= keybd_v(NUM_INPUTS-1).d;

  end process;

end architecture SYN;


