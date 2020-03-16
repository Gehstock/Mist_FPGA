Library IEEE;
Use     IEEE.std_logic_1164.all;

library work;
use work.pace_pkg.all;

entity inputs is
  generic
  (
    NUM_DIPS        : integer := 8;
    NUM_INPUTS      : integer := 2
  );
  port
  (
    clk             : in std_logic;                               
    reset           : in std_logic;                                                          
    jamma           : in from_JAMMA_t;

    dips            : in std_logic_vector(NUM_DIPS-1 downto 0);
    inputs          : out from_MAPPED_INPUTS_t(0 to NUM_INPUTS-1)
  );
end entity inputs;

architecture SYN of inputs is

  signal reset_n        : std_logic;

    
begin

  reset_n <= not reset;


  inputmapper_inst : entity work.inputmapper
    generic map
    (
      NUM_DIPS    => NUM_DIPS,
      NUM_INPUTS  => NUM_INPUTS
    )
    port map
    (
      clk       => clk,
      rst_n     => reset_n,
      jamma     => jamma,
      dips      => dips,
      inputs    => inputs
    );

end architecture SYN;
