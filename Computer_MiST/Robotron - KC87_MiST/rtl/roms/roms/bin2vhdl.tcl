#!/usr/bin/tclsh

set fileName "rom.bin"
if { $::argc > 0 } {
    set fileName [lindex $::argv 0]
} 

set entityName "rom"
if { $::argc > 1 } {
    set entityName [lindex $::argv 1]
} 

set f [open $fileName r]
fconfigure $f -translation binary
set addr -1
    
while { 1 } {
    set s [read $f 16]
    
    binary scan $s H* data
        
    for {set i 0} {$i < [string length $data]} {incr i 2} {
        set mem([incr addr]) [string range $data $i $i+1]
    }
                
    if { [string length $s] == 0 } {
        break
    }
}

close $f

set numBits [expr int(ceil(log([lindex $addr end]) / log(2)))]
set maxAddr [expr int(pow(2,$numBits))]

puts "library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity $entityName is
    generic(
        AddrWidth   : integer := [expr $numBits]
    );
    port (
        clk  : in std_logic;
        addr : in std_logic_vector(AddrWidth-1 downto 0);
        data : out std_logic_vector(7 downto 0)
    );
end $entityName;

architecture rtl of $entityName is
    type rom[expr $maxAddr]x8 is array (0 to 2**AddrWidth-1) of std_logic_vector(7 downto 0); 
    constant romData : rom[expr $maxAddr]x8 := ("
puts -nonewline "        "
for {set i 0} {$i < $maxAddr} {incr i} {
    if {[info exists mem($i)]} {
        puts -nonewline " x\"$mem($i)\""
    } else {
        puts -nonewline " x\"00\""
    }
    
    if {$i < $maxAddr - 1} {
        puts  -nonewline ", "
    } else {
        puts  -nonewline "  "
    }
    
    if {$i % 8 == 7} {
        puts -nonewline "-- [format %4.4X [expr $i-7]]\n        "
    }   
}
puts ");
    
begin
    process begin
        wait until rising_edge(clk);
        data <= romData(to_integer(unsigned(addr)));
    end process;
end;"