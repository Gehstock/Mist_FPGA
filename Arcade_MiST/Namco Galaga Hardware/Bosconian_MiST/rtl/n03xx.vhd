-- Namco 03xx Playfield Data Buffer
-- Nolan Nicholson, 2021

-- From https://www.jrok.com/hardware/custom_ic/cus03/:
--   This part of the scrolling circuit used on Bosconian, Pole Position and Xevious. It's basically
--   an 3 x 6 bit register that allows 6 bits of data to be written out after a certain number of clock
--   pulses have passed. This can be on either the rising or falling edge of the input clock. Shifting
--   is set by 3 'shift' control inputs. When not shifting it just passes data through transparently.

-- This is my current best guess of the pin layout:
  -- VCC/GND ?? | 9    10 | SHIFT1 ??
  --  SHIFT2 ?? | 8    11 | SHIFT0 ??
  --         I5 | 7    12 | O5
  --         I4 | 6    13 | O4
  --         I3 | 5    14 | O3
  --         I2 | 4    15 | O2
  --         I1 | 3    16 | O1
  --         I0 | 2    17 | O0
  --        CLK | 1    18 | VCC/GND ??

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n03xx is port (
  clk_i    : in std_ulogic;
  clk_en_i : in std_ulogic;
  shift_i  : in std_ulogic_vector(2 downto 0); -- pins 8, 10, 11
  data_i   : in std_ulogic_vector(5 downto 0);

  data_o  : out std_ulogic_vector(5 downto 0)
);
end n03xx;

architecture rtl of n03xx is
  type t_queue is array(1 to 3) of std_ulogic_vector(5 downto 0);
  signal queue : t_queue;

begin
  proc_shift : process(clk_i, clk_en_i) is
  begin
    if rising_edge(clk_i) then
      if clk_en_i = '1' then
        queue(1) <= data_i;
        queue(2) <= queue(1);
        queue(3) <= queue(2);
      end if;
    end if;
  end process proc_shift;

  -- TODO:
  -- This way of parsing the shift inputs appears to produce correct
  -- scrolling in Bosconian, but probably not in Pole Position.
  with shift_i select
    data_o <= data_i   when "000",
              queue(1) when "001",
              queue(2) when "010",
              queue(3) when "011",
              queue(1) when "100",
              queue(1) when "101",
              queue(1) when "110",
              queue(1) when "111";

end rtl;
