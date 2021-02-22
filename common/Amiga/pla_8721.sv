module pla_8721(
    input rom_256,
    input va14,
    input charen,
    input hiram,
    input loram,
    input ba,
    input vma5,
    input vma4,
    input ms0,
    input ms1,
    input ms2,
    input ms3,
    input z80io,
    input z80en,
    input exrom,
    input game,
    input rw,
    input aec,
    input dmaack,
    input vicfix,
    input a10,
    input a11,
    input a12,
    input a13,
    input a14,
    input a15,
    input clk,

    output sden,
    output roml,
    output romh,
    output clrbnk,
    output from,
    output rom4,
    output rom3,
    output rom2,
    output rom1,
    output iocs,
    output dir,
    output reg dwe,
    output reg casenb,
    output vic,
    output ioacc,
    output gwe,
    output colram,
    output charom
	 );


wire p0 = charen & hiram & ba & !ms3 & game &  rw & aec & a12 & !a13 & a14 & a15;
wire p1 = charen & hiram &      !ms3 & game & !rw & aec & a12 & !a13 & a14 & a15;
wire p2 = charen & loram & ba & !ms3 & game &  rw & aec & a12 & !a13 & a14 & a15;
wire p3 = charen & loram &      !ms3 & game & !rw & aec & a12 & !a13 & a14 & a15;
wire p4 = charen & hiram & ba & !ms3 & !exrom & !game &  rw & aec & a12 & !a13 & a14 & a15;
wire p5 = charen & hiram &      !ms3 & !exrom & !game & !rw & aec & a12 & !a13 & a14 & a15;
wire p6 = charen & loram & ba & !ms3 & !exrom & !game &  rw & aec & a12 & !a13 & a14 & a15;
wire p7 = charen & loram &      !ms3 & !exrom & !game & !rw & aec & a12 & !a13 & a14 & a15;

wire p8 = ba & !ms3 & exrom & !game & rw & aec & a13 & !a13 & a14 & a15;
wire p9 =      !ms3 & exrom & !game & rw & aec & a12 & !a13 & a14 & a15;
wire p10 = ba & !ms2 & ms3 &  rw & aec & a12 & !a13 & a14 & a15;
wire p11 =      !ms2 & ms3 & !rw & aec & a12 & !a13 & a14 & a15;
wire p12 = charen & hiram & ba & !ms3 & game &  rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p13 = charen & hiram &      !ms3 & game & !rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p14 = charen & loram & ba & !ms3 & game &  rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p15 = charen & loram &      !ms3 & game & !rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;

wire p16 = charen & hiram & ba & !ms3 & !exrom & !game &  rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p17 = charen & hiram &      !ms3 & !exrom & !game & !rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p18 = charen & loram & ba & !ms3 & !exrom & !game &  rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p19 = charen & loram &      !ms3 & !exrom & !game & !rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;

wire p20 = ba & !ms3 & exrom & !game & rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p21 =      !ms3 & exrom & !game & rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;

wire p22 = ba & !ms2 & ms3 &  rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;
wire p23 =      !ms2 & ms3 & !rw & aec & !a10 & !a11 & a12 & !a13 & a14 & a15;

wire p24 = charen & hiram & ba & !ms3 & game &  rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p25 = charen & hiram &      !ms3 & game & !rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p26 = charen & loram & ba & !ms3 & game &  rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p27 = charen & loram &      !ms3 & game & !rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;

wire p28 = charen & hiram & ba & !ms3 & !exrom & !game &  rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p29 = charen & hiram &      !ms3 & !exrom & !game & !rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p30 = charen & loram & ba & !ms3 & !exrom & !game &  rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p31 = charen & loram &      !ms3 & !exrom & !game & !rw & aec & !a10 & a11 & a12 & !a13       & a15;

wire p32 = ba & !ms3 & exrom & !game & rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p33 =      !ms3 & exrom & !game & rw & aec & !a10 & a11 & a12 & !a13       & a15;

wire p34 = ba & !ms2 & ms3 &  rw & aec & !a10 & a11 & a12 & !a13 & a14 & a15;
wire p35 =      !ms2 & ms3 & !rw & aec & !a10 & a11 & a12 & !a13       & a15;

wire p36 = !aec;
wire p37 = !rw & aec & !a10 & a11 & a12 & !a13 & a15;

wire p39 = !charen & hiram & !ms3 &           game & rw & aec & a12 & !a13 & a14 & a15;
wire p40 = !charen & loram & !ms3 &           game & rw & aec & a12 & !a13 & a14 & a15;
wire p41 = !charen & hiram & !ms3 & !exrom & !game & rw & aec & a12 & !a13 & a14 & a15;

wire p42 = va14 & !vma5 & vma4 & !ms3          &  game & !aec;
wire p43 = va14 & !vma5 & vma4 & !ms3 & !exrom & !game & !aec;

wire p44 = !ms0 & !ms1 & ms2 &ms3 & z80en & rw & aec & a12 & !a13 & a14 & a15;
wire p45 = hiram & loram & !ms3 & !exrom & rw & aec & !a13 & !a14 & a15;

wire p46 = !ms3 & exrom & !game & aec & !a13 & !a14 & a15;
wire p47 = ms0 & !ms1 & ms3 & exrom & !game & aec & !a14 & a15;
wire p48 = !ms0 & ms1 & ms3                 & aec & !a14 & a15;

wire p49 = hiram & !ms3 & !exrom & !game & aec & a13 & !a14 & a15;
wire p50 = ms3 & exrom & !game & aec & a13 & !a14 & a15;

wire p51 = vma5 & vma4 & !ms3 & exrom & !game & !aec;
wire p52 =  ms0 & !ms1 & ms3 & rw & aec & !a12 & !a13 & a14 & a15;
wire p53 = !ms0 &  ms1 & ms3 & rw & aec & !a12 & !a13 & a14 & a15;
wire p54 = !ms0 & !ms1 & ms3 & rw & aec & !a12 & !a13 & a14 & a15;

wire p55 = !ms0 & !ms1 & z80io & !z80en & rw & aec & !a12 & !a13 & !a14 & !a15;
wire p56 = !ms0 & !ms1 & ms3 & rw & aec & !a14 &  a15;
wire p57 = !ms0 & !ms1 & ms3 & rw & aec &  a14 & !a15;

wire p58 = hiram         & !ms3          &  game & rw & aec & a13 &  a14 & a15;
wire p59 = hiram         & !ms3 & !exrom & !game & rw & aec & a13 &  a14 & a15;
wire p60 = hiram & loram & !ms3          &  game & rw & aec & a13 & !a14 & a15;

wire p61 = !z80io & !z80en & aec & !a10 & !a11        & !a13 & a14 & a15;
wire p62 = !z80io & !z80en & aec               &  a12 & !a13 & a14 & a15;
wire p63 = !z80io & !z80en & aec & !a10 &  a11 &  a12 & !a13 & a14 & a15;

wire p64 = !rw & aec;
wire p65 =  rw & aec;
wire p66 = !aec;

wire p67 = !ms2 & !z80en       & aec & !a10 & !a11 & a12 & !a13 & !a14 & !a15;
wire p68 = !ms2 & !z80en & !rw & aec & !a10 & !a11 & a12 & !a13 & !a14 & !a15;

wire p69 = !charen & !vma5 & vma4 & ms3 & aec;

wire p70 = !rom_256 & !ms0 & !ms1 & ms3 & rw & aec               & a14 & !a15;
wire p71 = !rom_256 & !ms0 & !ms1 & ms3 & rw & aec & !a12 & !a13 & a14 &  a15;
wire p72 = !rom_256 & !ms0 & !ms1 & z80io & !z80en & rw & aec & !a12 & !a13 & !a14 & !a15;

wire p73 = clk;
wire p74 = rw & !aec & vicfix;

wire p75 =            !ms0 & !ms1       & ms3 & rw & aec       &  a13 & a14 & a15;
wire p76 = !rom_256 & !ms0 & !ms1       & ms3 & rw & aec       &  a13 & a14 & a15;
wire p77 =            !ms0 &  ms1       & ms3 & rw & aec       &  a13 & a14 & a15;
wire p78 =            !ms0 &  ms1 & ms2 & ms3 & rw & aec & a12 & !a13 & a14 & a15;
wire p79 =             ms0 & !ms1       & ms3 & rw & aec       &  a13 & a14 & a15;
wire p80 =             ms0 & !ms1 & ms2 & ms3 & rw & aec & a12 & !a13 & a14 & a15;

wire p81 = !ms3 & exrom & !game & aec &  a12        & !a14 & !a15;
wire p82 = !ms3 & exrom & !game & aec        &  a13 & !a14;
wire p83 = !ms3 & exrom & !game & aec               &  a14;
wire p84 = !ms3 & exrom & !game & aec & !a12 & !a13 &  a14 &  a15;

wire p85 = !loram & ms3 &  aec;
wire p86 = !hiram & ms3 & !aec;

/* outputs */

wire sden = p42 || p43 || p66 || p69;
wire roml = p45 || p46 || p47;
wire romh = p49 || p50 || p51 || p52 || p79 || p80;
wire clrbnk = p85 || p86;
wire from = p48 || p53 || p77 || p78;
wire rom4 = p54 || p55 || p75;
wire rom3 = p56 || p70;
wire rom2 = p57;
wire rom1 = p58 || p59 || p60 || p71 || p71 || p76;
wire iocs = p0 || p1 || p2 || p3 || p4 || p5 || p6 || p7 || p8 || p9 || p10 || p11 || p62;
wire dir = p12 || p14 || p16 || p18 || p20 || p22 || p24 || p26 || p28 || p30 || p32 || p34 || p39 || p40 || p41 || p44 || p65;
wire vic = p12 || p13 || p14 || p15 || p16 || p17 || p18 || p19 || p20 || p21 || p22 || p23 || p61;
wire ioacc = p0 || p1 || p2 || p3 || p4 || p5 || p6 || p7 || p8 || p9 || p10 || p11 || 
               p12 || p13 || p14 || p15 || p16 || p17 || p18 || p19 || p20 || p21 || p22 || p61 || p62;
wire gwe = p37;
wire colram = p24 || p25 || p26 || p27 || p28 || p29 || p30 || p31 || p32 || p33 || p34 || p35 || p36 || p63 || p67;
wire charrom = p39 || p40 || p41 || p42 || p43 || p44 || p69;

wire casenb_latch = p73 || p74;

wire casenb_int = p0 || p1 || p2 || p3 || p4 || p5 || p6 || p7 || p8 || p9
                || p10 || p11 || p12 || p13 || p14 || p15 || p16 || p17 || p18 || p19
                || p20 || p21 || p22 || p23 || p39 || p40 || p41 || p42 || p43 || p44
                || p45 || p46 || p47 || p48 || p49 || p50 || p51 || p52 || p53 || p54
                || p55 || p56 || p57 || p58 || p59 || p60 || p61 || p62 || p63 || p67
                || p69 || p70 || p71 || p72 || p75 || p76 || p77 || p78 || p79 || p80
                || p81 || p82 || p83 || p84;

/* Latched outputs */

always @ (clk or p64)
  if (clk)
    dwe <= p64;

always @ (casenb_latch or casenb_int)
  if (casenb_latch)
    casenb <= casenb_int;

endmodule 