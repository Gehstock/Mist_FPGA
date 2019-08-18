Acorn System 1 - Port to MiST

ToDo: Mouse and Keyboard




This is a port of Acorn System 1 inspired by the work of David Banks.


This version has a huge 512 bytes of rom
and a massive 1024 bytes of memory. The display is the latest 9 digit (only 8 used )7 segment plus dp.
The keyboard is 25 soft touch positive click switches.

My first computer was a system 1. I could spend hours entering one machine 
code instruction at a time, then more hours debugging my mistakes.
Then switch off and it was all lost. 
Ahh those were the days.

I would think that this port will be of limited interest but I could not find any other 
port of this machine.

The mouse is the yellow dot on the screen. Left click to press switch.

At present this is a basic system 1 there are no bells or whistles. 
No input (tape) or output as yet.

You will have to forgive the vga output, all hand drawn using several hundred 'if' statements.

The quickest way to test is after load, press the rst key. Press 'm' key.
Enter '0015' and press 'm' again.
The address 0015 is the 3rd character from the right. The value shouls read 80.
type any hex character to change the value and the character will change. 



Dave Wood (oldgit)