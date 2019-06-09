--===========================================================================--
--
--  S Y N T H E Z I A B L E    I/O Port   C O R E
--
--  www.OpenCores.Org - May 2004
--  This core adheres to the GNU public license  
--
-- File name      : pia6821.vhd
--
-- Purpose        : Implements 2 x 8 bit parallel I/O ports
--                  with programmable data direction registers
--                  
-- Dependencies   : ieee.Std_Logic_1164
--                  ieee.std_logic_unsigned
--
-- Author         : John E. Kent      
--
--===========================================================================----
--
-- Revision History:
--
-- Date:          Revision         Author
-- 1 May 2004     0.0              John Kent
-- Initial version developed from ioport.vhd
--
--
-- Unkown date     0.0.1 found at Pacedev repository
-- remove High Z output and and oe signal
--
-- 18 October 2017 0.0.2           DarFpga
-- Set output to low level when in data is in input mode 
-- (to avoid infered latch warning)
--
--===========================================================================----
--
-- Memory Map
--
-- IO + $00 - Port A Data & Direction register
-- IO + $01 - Port A Control register
-- IO + $02 - Port B Data & Direction Direction Register
-- IO + $03 - Port B Control Register
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pia6821 is
	port (	
	 	clk       : in    std_logic;
    rst       : in    std_logic;
    cs        : in    std_logic;
    rw        : in    std_logic;
    addr      : in    std_logic_vector(1 downto 0);
    data_in   : in    std_logic_vector(7 downto 0);
	 	data_out  : out   std_logic_vector(7 downto 0);
	 	irqa      : out   std_logic;
	 	irqb      : out   std_logic;
	 	pa_i      : in std_logic_vector(7 downto 0);
	 	pa_o      : out std_logic_vector(7 downto 0);
	 	pa_oe     : out std_logic_vector(7 downto 0);
	 	ca1       : in    std_logic;
	 	ca2_i     : in std_logic;
	 	ca2_o     : out std_logic;
	 	ca2_oe    : out std_logic;
	 	pb_i      : in std_logic_vector(7 downto 0);
	 	pb_o      : out std_logic_vector(7 downto 0);
	 	pb_oe     : out std_logic_vector(7 downto 0);
	 	cb1       : in    std_logic;
	 	cb2_i     : in std_logic;
	 	cb2_o     : out std_logic;
	 	cb2_oe    : out std_logic
	 );
end;

architecture pia_arch of pia6821 is

signal porta_ddr   : std_logic_vector(7 downto 0);
signal porta_data  : std_logic_vector(7 downto 0);
signal porta_ctrl  : std_logic_vector(5 downto 0);
signal porta_read  : std_logic;

signal portb_ddr   : std_logic_vector(7 downto 0);
signal portb_data  : std_logic_vector(7 downto 0);
signal portb_ctrl  : std_logic_vector(5 downto 0);
signal portb_read  : std_logic;
signal portb_write : std_logic;

signal ca1_del     : std_logic;
signal ca1_rise    : std_logic;
signal ca1_fall    : std_logic;
signal ca1_edge    : std_logic;
signal irqa1       : std_logic;

signal ca2_del     : std_logic;
signal ca2_rise    : std_logic;
signal ca2_fall    : std_logic;
signal ca2_edge    : std_logic;
signal irqa2       : std_logic;
signal ca2_out     : std_logic;

signal cb1_del     : std_logic;
signal cb1_rise    : std_logic;
signal cb1_fall    : std_logic;
signal cb1_edge    : std_logic;
signal irqb1       : std_logic;

signal cb2_del     : std_logic;
signal cb2_rise    : std_logic;
signal cb2_fall    : std_logic;
signal cb2_edge    : std_logic;
signal irqb2       : std_logic;
signal cb2_out     : std_logic;

begin

--------------------------------
--
-- read I/O port
--
--------------------------------

pia_read : process(	addr,	cs,
                    irqa1, irqa2, irqb1, irqb2,
                    porta_ddr,  portb_ddr,
										porta_data, portb_data,
										porta_ctrl, portb_ctrl,
						   			pa_i,       pb_i )
variable count : integer;
begin
      case addr is
	     when "00" =>
		    for count in 0 to 7 loop
			   if porta_ctrl(2) = '0' then
				  data_out(count) <= porta_ddr(count);
			     porta_read <= '0';
            else
				  if porta_ddr(count) = '1' then
                data_out(count) <= porta_data(count);
              else
                data_out(count) <= pa_i(count);
              end if;
			     porta_read <= cs;
            end if;
			 end loop;
			 portb_read <= '0';

	     when "01" =>
		    data_out <= irqa1 & irqa2 & porta_ctrl;
			 porta_read <= '0';
			 portb_read <= '0';

		  when "10" =>
		    for count in 0 to 7 loop
			   if portb_ctrl(2) = '0' then
				  data_out(count) <= portb_ddr(count);
				  portb_read <= '0';
            else
				  if portb_ddr(count) = '1' then
                data_out(count) <= portb_data(count);
              else
                data_out(count) <= pb_i(count);
				  end if;
				  portb_read <= cs;
            end if;
			 end loop;
			 porta_read <= '0';

		  when "11" =>
		    data_out <= irqb1 & irqb2 & portb_ctrl;
			 porta_read <= '0';
			 portb_read <= '0';

		  when others =>
		    data_out <= "00000000";
			 porta_read <= '0';
			 portb_read <= '0';

		end case;
end process;

---------------------------------
--
-- Write I/O ports
--
---------------------------------

pia_write : process( clk, rst, addr, cs, rw, data_in,
                        porta_ctrl, portb_ctrl,
                        porta_data, portb_data,
						porta_ddr, portb_ddr )
begin
  if rst = '1' then
      porta_ddr   <= "00000000";
      porta_data  <= "00000000";
      porta_ctrl  <= "000000";
      portb_ddr   <= "00000000";
      portb_data  <= "00000000";
		portb_ctrl  <= "000000";
		portb_write <= '0';
  elsif clk'event and clk = '1' then
    if cs = '1' and rw = '0' then
      case addr is
	     when "00" =>
		    if porta_ctrl(2) = '0' then
		       porta_ddr  <= data_in;
		       porta_data <= porta_data;
			 else
		       porta_ddr  <= porta_ddr;
		       porta_data <= data_in;
			 end if;
			 porta_ctrl  <= porta_ctrl;
		    portb_ddr   <= portb_ddr;
		    portb_data  <= portb_data;
			 portb_ctrl  <= portb_ctrl;
			 portb_write <= '0';
		  when "01" =>
		    porta_ddr   <= porta_ddr;
		    porta_data  <= porta_data;
			 porta_ctrl  <= data_in(5 downto 0);
		    portb_ddr   <= portb_ddr;
		    portb_data  <= portb_data;
			 portb_ctrl  <= portb_ctrl;
			 portb_write <= '0';
	     when "10" =>
		    porta_ddr   <= porta_ddr;
		    porta_data  <= porta_data;
			 porta_ctrl  <= porta_ctrl;
		    if portb_ctrl(2) = '0' then
		       portb_ddr   <= data_in;
		       portb_data  <= portb_data;
			    portb_write <= '0';
			 else
		       portb_ddr   <= portb_ddr;
		       portb_data  <= data_in;
			    portb_write <= '1';
			 end if;
			 portb_ctrl  <= portb_ctrl;
		  when "11" =>
		    porta_ddr   <= porta_ddr;
		    porta_data  <= porta_data;
			 porta_ctrl  <= porta_ctrl;
		    portb_ddr   <= portb_ddr;
		    portb_data  <= portb_data;
			 portb_ctrl  <= data_in(5 downto 0);
			 portb_write <= '0';
		  when others =>
		    porta_ddr   <= porta_ddr;
		    porta_data  <= porta_data;
			 porta_ctrl  <= porta_ctrl;
		    portb_ddr   <= portb_ddr;
		    portb_data  <= portb_data;
			 portb_ctrl  <= portb_ctrl;
			 portb_write <= '0';
		end case;
	 else
		    porta_ddr   <= porta_ddr;
		    porta_data  <= porta_data;
			 porta_ctrl  <= porta_ctrl;
		    portb_data  <= portb_data;
		    portb_ddr   <= portb_ddr;
			 portb_ctrl  <= portb_ctrl;
			 portb_write <= '0';
	 end if;
  end if;
end process;

---------------------------------
--
-- direction control port a
--
---------------------------------
porta_direction : process ( porta_data, porta_ddr )
variable count : integer;
begin
  for count in 0 to 7 loop
    if porta_ddr(count) = '1' then
      pa_o(count) <= porta_data(count);
		pa_oe(count) <= '1';
    else
      pa_o(count) <= '0'; 
      pa_oe(count) <= '0';
    end if;
  end loop;
end process;

---------------------------------
--
-- CA1 Edge detect
--
---------------------------------
ca1_input : process( clk, rst, ca1, ca1_del,
                     ca1_rise, ca1_fall, ca1_edge,
							irqa1, porta_ctrl, porta_read )
begin
  if rst = '1' then
    ca1_del  <= '0';
	 ca1_rise <= '0';
    ca1_fall <= '0';
	 ca1_edge <= '0';
	 irqa1    <= '0';
  elsif clk'event and clk = '0' then
    ca1_del  <= ca1;
    ca1_rise <= (not ca1_del) and ca1;
    ca1_fall <= ca1_del and (not ca1);
	 if ca1_edge = '1' then
	    irqa1 <= '1';
	 elsif porta_read = '1' then
	    irqa1 <= '0';
    else
	    irqa1 <= irqa1;
    end if;
  end if;  

  if porta_ctrl(1) = '0' then
	 ca1_edge <= ca1_fall;
  else
	 ca1_edge <= ca1_rise;
  end if;
end process;

---------------------------------
--
-- CA2 Edge detect
--
---------------------------------
ca2_input : process( clk, rst, ca2_i, ca2_del,
                     ca2_rise, ca2_fall, ca2_edge,
							irqa2, porta_ctrl, porta_read )
begin
  if rst = '1' then
    ca2_del  <= '0';
	 ca2_rise <= '0';
    ca2_fall <= '0';
	 ca2_edge <= '0';
	 irqa2    <= '0';
  elsif clk'event and clk = '0' then
    ca2_del  <= ca2_i;
    ca2_rise <= (not ca2_del) and ca2_i;
    ca2_fall <= ca2_del and (not ca2_i);
	 if porta_ctrl(5) = '0' and ca2_edge = '1' then
	    irqa2 <= '1';
	 elsif porta_read = '1' then
	    irqa2 <= '0';
    else
	    irqa2 <= irqa2;
    end if;
  end if;  

  if porta_ctrl(4) = '0' then
	 ca2_edge <= ca2_fall;
  else
	 ca2_edge <= ca2_rise;
  end if;
end process;

---------------------------------
--
-- CA2 output control
--
---------------------------------
ca2_output : process( clk, rst, porta_ctrl, porta_read, ca1_edge, ca2_out )
begin
  if rst='1' then
    ca2_out <= '0';
  elsif clk'event and clk='0' then
    case porta_ctrl(5 downto 3) is
    when "100" => -- read PA clears, CA1 edge sets
      if porta_read = '1' then
	     ca2_out <= '0';
      elsif ca1_edge = '1' then
	     ca2_out <= '1';
      else
	     ca2_out <= ca2_out;
      end if;
    when "101" => -- read PA clears, E sets
      ca2_out <= not porta_read;
    when "110" =>	-- set low
	   ca2_out <= '0';
    when "111" =>	-- set high
	   ca2_out <= '1';
    when others => -- no change
	   ca2_out <= ca2_out;
    end case;
  end if;
end process;

---------------------------------
--
-- CA2 direction control
--
---------------------------------
ca2_direction : process( porta_ctrl, ca2_out )
begin
  if porta_ctrl(5) = '0' then
   ca2_oe <= '0';
   ca2_o <= '0'; 
  else
   ca2_o <= ca2_out;
	ca2_oe <= '1';
  end if;
end process;

---------------------------------
--
-- direction control port b
--
---------------------------------
portb_direction : process ( portb_data, portb_ddr )
variable count : integer;
begin
  for count in 0 to 7 loop
    if portb_ddr(count) = '1' then
      pb_o(count) <= portb_data(count);
		pb_oe(count) <= '1';
    else
      pb_o(count) <= '0'; 
      pb_oe(count) <= '0';
    end if;
  end loop;
end process;

---------------------------------
--
-- CB1 Edge detect
--
---------------------------------
cb1_input : process( clk, rst, cb1, cb1_del,
                     cb1_rise, cb1_fall, cb1_edge,
							irqb1, portb_ctrl, portb_read )
begin
  if rst = '1' then
    cb1_del  <= '0';
	 cb1_rise <= '0';
    cb1_fall <= '0';
	 cb1_edge <= '0';
	 irqb1    <= '0';
  elsif clk'event and clk = '0' then
    cb1_del  <= cb1;
    cb1_rise <= (not cb1_del) and cb1;
    cb1_fall <= cb1_del and (not cb1);
	 if cb1_edge = '1' then
	    irqb1 <= '1';
	 elsif portb_read = '1' then
	    irqb1 <= '0';
    else
	    irqb1 <= irqb1;
    end if;
  end if;
    
  if portb_ctrl(1) = '0' then
	 cb1_edge <= cb1_fall;
  else
	 cb1_edge <= cb1_rise;
  end if;
end process;

---------------------------------
--
-- CB2 Edge detect
--
---------------------------------
cb2_input : process( clk, rst, cb2_i, cb2_del,
                     cb2_rise, cb2_fall, cb2_edge,
							irqb2, portb_ctrl, portb_read )
begin
  if rst = '1' then
    cb2_del  <= '0';
	 cb2_rise <= '0';
    cb2_fall <= '0';
	 cb2_edge <= '0';
	 irqb2    <= '0';
  elsif clk'event and clk = '0' then
    cb2_del  <= cb2_i;
    cb2_rise <= (not cb2_del) and cb2_i;
    cb2_fall <= cb2_del and (not cb2_i);
	 if portb_ctrl(5) = '0' and cb2_edge = '1' then
	    irqb2 <= '1';
	 elsif portb_read = '1' then
	    irqb2 <= '0';
    else
	    irqb2 <= irqb2;
    end if;
  end if;
    
  if portb_ctrl(4) = '0' then
	 cb2_edge <= cb2_fall;
  else
	 cb2_edge <= cb2_rise;
  end if;

end process;

---------------------------------
--
-- CB2 output control
--
---------------------------------
cb2_output : process( clk, rst, portb_ctrl, portb_write, cb1_edge, cb2_out )
begin
  if rst='1' then
    cb2_out <= '0';
  elsif clk'event and clk='0' then
    case portb_ctrl(5 downto 3) is
    when "100" => -- write PB clears, CA1 edge sets
      if portb_write = '1' then
	     cb2_out <= '0';
      elsif cb1_edge = '1' then
	     cb2_out <= '1';
      else
	     cb2_out <= cb2_out;
      end if;
    when "101" => -- write PB clears, E sets
      cb2_out <= not portb_write;
    when "110" =>	-- set low
	   cb2_out <= '0';
    when "111" =>	-- set high
	   cb2_out <= '1';
    when others => -- no change
	   cb2_out <= cb2_out;
    end case;
  end if;
end process;

---------------------------------
--
-- CB2 direction control
--
---------------------------------
cb2_direction : process( portb_ctrl, cb2_out )
begin
  if portb_ctrl(5) = '0' then
    cb2_oe <= '0';
    cb2_o <=  '0'; 
  else
    cb2_o <= cb2_out;
	 cb2_oe <= '1';
  end if;
end process;

---------------------------------
--
-- IRQ control
--
---------------------------------
pia_irq : process( irqa1, irqa2, irqb1, irqb2, porta_ctrl, portb_ctrl )
begin
  irqa <= (irqa1 and porta_ctrl(0)) or (irqa2 and porta_ctrl(3));
  irqb <= (irqb1 and portb_ctrl(0)) or (irqb2 and portb_ctrl(3));
end process;

end pia_arch;
	
