*****************************************************************
**              Arcade: Atari Pong (1972)                      **
** A Verilog implementation based on the original schematics.  **
*****************************************************************

                Written by: Richard Eng
                email:      engric@gmail.com
                twitter:    @richard_eng
                www:        retrobits.no
                git:        github.com/Eicar

---------
Changelog
---------
  2019-10-06 Initial release

------
Inputs
------

MAME/IPAC/JPAC Style Keyboard inputs:
    5   : Coin 1
    6   : Coin 2

+Analog joysticks for paddles (player 1+2)

---------
File list
---------

sys/*     GPL-2, Copyright (C) 2019 Sorgelig
rtl/*     MIT, Copyright (c) 2019 Richard Eng

---
Q&A
---

-Q: How accurate is this implementation?
 A: This implementation is based on the original Atari schematics. However, the
    original hardware consists of both digital (sync+async logic) and analog circuits. The analog circuits
    are simulated using digital logic. All signals should be accurate to the system clock edges (7.159MHz).

-Q: Help! I'm unable to move the paddles using the keyboard!
 A: Currently only analog joystick controls are supported.

-Q: Help! I'm unable to move the paddle to the top of the screen!
 A: This is not a bug. The original hardware design did not allow for this to happen.

-Q: The core "reset" does not seem to work
 A: This is true. The original Pong hardware did not support a global "reset" signal.
    I might add support for this in the future.

-Q: Can you please add support for XXX!
 A: I will probably not add features not present in the original game.
    This core is all about accuracy. 

-Q: Your HDL code looks like crap!
 A: You are probably right about that! I have a 20+ years software developer background but HDL is
    pretty new to me. Hopefully I will get better at it :)
    
-Q: I've found a bug!
 A: Please let me know about it! I really want this core to be as accurate as possible.
    I will make sure you will get credit for it!

-Q: This core is awesome! How can I make a donation?
 A: All donations are welcome and extremely appreciated! Donations will make it possible
    for me to spend more time on writing new cores.

    Donations can be sent to: paypal.me/riceng


-End of file
