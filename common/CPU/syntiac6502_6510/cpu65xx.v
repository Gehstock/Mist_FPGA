// -----------------------------------------------------------------------
//
//                                 FPGA 64
//
//     A fully functional commodore 64 implementation in a single FPGA
//
// -----------------------------------------------------------------------
// Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
// http://www.syntiac.com/fpga64.html
// -----------------------------------------------------------------------
//
// Table driven, cycle exact 6502/6510 core
//
// -----------------------------------------------------------------------

// -----------------------------------------------------------------------

// Store Zp    (3) => fetch, cycle2, cycleEnd
// Store Zp,x  (4) => fetch, cycle2, preWrite, cycleEnd
// Read  Zp,x  (4) => fetch, cycle2, cycleRead, cycleRead2
// Rmw   Zp,x  (6) => fetch, cycle2, cycleRead, cycleRead2, cycleRmw, cycleEnd
// Store Abs   (4) => fetch, cycle2, cycle3, cycleEnd
// Store Abs,x (5) => fetch, cycle2, cycle3, preWrite, cycleEnd
// Rts         (6) => fetch, cycle2, cycle3, cycleRead, cycleJump, cycleIncrEnd
// Rti         (6) => fetch, cycle2, stack1, stack2, stack3, cycleJump
// Jsr         (6) => fetch, cycle2, .. cycle5, cycle6, cycleJump
// Jmp abs     (-) => fetch, cycle2, .., cycleJump
// Jmp (ind)   (-) => fetch, cycle2, .., cycleJump
// Brk / irq   (6) => fetch, cycle2, stack2, stack3, stack4
// -----------------------------------------------------------------------

module cpu65xx
(
  clk,
  enable,
  reset,
  nmi_n,
  irq_n,
  so_n,

  din,
  dout,
  addr,
  we,

  debugOpcode,
  debugPc,
  debugA,
  debugX,
  debugY,
  debugS
);

parameter pipelineOpcode = 1'b0;
parameter pipelineAluMux = 1'b0;
parameter pipelineAluOut = 1'b0;


input         clk;
input         enable;
input         reset;
input         nmi_n;
input         irq_n;
input         so_n;

input   [7:0] din;
output  [7:0] dout;
output [15:0] addr;
output        we;

output  [7:0] debugOpcode;
output [15:0] debugPc;
output  [7:0] debugA;
output  [7:0] debugX;
output  [7:0] debugY;
output  [7:0] debugS;

//  type cpuCycles is
localparam [4:0]
  opcodeFetch       = 5'b00000,  // New opcode is read and registers updated
  cycle2            = 5'b00001,
  cycle3            = 5'b00010,
  cyclePreIndirect  = 5'b00011,
  cycleIndirect     = 5'b00100,
  cycleBranchTaken  = 5'b00101,
  cycleBranchPage   = 5'b00110,
  cyclePreRead      = 5'b00111,  // Cycle before read while doing zeropage indexed addressing.
  cycleRead         = 5'b01000,  // Read cycle
  cycleRead2        = 5'b01001,  // Second read cycle after page-boundary crossing.
  cycleRmw          = 5'b01010,  // Calculate ALU output for read-modify-write instr.
  cyclePreWrite     = 5'b01011,  // Cycle before write when doing indexed addressing.
  cycleWrite        = 5'b01100,  // Write cycle for zeropage or absolute addressing.
  cycleStack1       = 5'b01101,
  cycleStack2       = 5'b01110,
  cycleStack3       = 5'b01111,
  cycleStack4       = 5'b10000,
  cycleJump         = 5'b10001,  // Last cycle of Jsr, Jmp. Next fetch address is target addr.
  cycleEnd          = 5'b10010;

  reg  [4:0] theCpuCycle;
  reg  [4:0] nextCpuCycle;
  reg        updateRegisters;
  reg        processIrq;
  reg        nmiReg;
  reg        nmiEdge;
  reg        irqReg; // Delay IRQ input with one clock cycle.
  reg        soReg;  // SO pin edge detection

// Opcode decoding
`define opcUpdateA    43
`define opcUpdateX    42
`define opcUpdateY    41
`define opcUpdateS    40
`define opcUpdateN    39
`define opcUpdateV    38
`define opcUpdateD    37
`define opcUpdateI    36
`define opcUpdateZ    35
`define opcUpdateC    34

`define opcSecondByte 33
`define opcAbsolute   32
`define opcZeroPage   31
`define opcIndirect   30
`define opcStackAddr  29 // Push/Pop address
`define opcStackData  28 // Push/Pop status/data
`define opcJump       27
`define opcBranch     26
`define indexX        25
`define indexY        24
`define opcStackUp    23
`define opcWrite      22
`define opcRmw        21
`define opcIncrAfter  20 // Insert extra cycle to increment PC (RTS)
`define opcRti        19
`define opcIRQ        18

`define opcInA        17
`define opcInE        16
`define opcInX        15
`define opcInY        14
`define opcInS        13
`define opcInT        12
`define opcInH        11
`define opcInClear    10
`define aluMode1From  9
//
`define aluMode1To    6
`define aluMode2From  5
//
`define aluMode2To    3
//
`define opcInCmp      2
`define opcInCpx      1
`define opcInCpy      0

// subtype addrDef is unsigned(0 to 15);
localparam [15:0]
//
//               is Interrupt  -----------------+
//          instruction is RTI ----------------+|
//    PC++ on last cycle (RTS) ---------------+||
//                      RMW    --------------+|||
//                     Write   -------------+||||
//               Pop/Stack up -------------+|||||
//                    Branch   ---------+  ||||||
//                      Jump ----------+|  ||||||
//            Push or Pop data -------+||  ||||||
//            Push or Pop addr ------+|||  ||||||
//                   Indirect  -----+||||  ||||||
//                    ZeroPage ----+|||||  ||||||
//                    Absolute ---+||||||  ||||||
//              PC++ on cycle2 --+|||||||  ||||||
//                               |AZI||JBXY|WM|||
          immediate        = 16'b1000000000000000,
          implied          = 16'b0000000000000000,
// Zero page
          readZp           = 16'b1010000000000000,
          writeZp          = 16'b1010000000010000,
          rmwZp            = 16'b1010000000001000,
// Zero page indexed
          readZpX          = 16'b1010000010000000,
          writeZpX         = 16'b1010000010010000,
          rmwZpX           = 16'b1010000010001000,
          readZpY          = 16'b1010000001000000,
          writeZpY         = 16'b1010000001010000,
          rmwZpY           = 16'b1010000001001000,
// Zero page indirect
          readIndX         = 16'b1001000010000000,
          writeIndX        = 16'b1001000010010000,
          rmwIndX          = 16'b1001000010001000,
          readIndY         = 16'b1001000001000000,
          writeIndY        = 16'b1001000001010000,
          rmwIndY          = 16'b1001000001001000,
//                               |AZI||JBXY|WM||
// Absolute
          readAbs          = 16'b1100000000000000,
          writeAbs         = 16'b1100000000010000,
          rmwAbs           = 16'b1100000000001000,
          readAbsX         = 16'b1100000010000000,
          writeAbsX        = 16'b1100000010010000,
          rmwAbsX          = 16'b1100000010001000,
          readAbsY         = 16'b1100000001000000,
          writeAbsY        = 16'b1100000001010000,
          rmwAbsY          = 16'b1100000001001000,
// PHA PHP
          push             = 16'b0000010000000000,
// PLA PLP
          pop              = 16'b0000010000100000,
// Jumps
          jsr              = 16'b1000101000000000,
          jumpAbs          = 16'b1000001000000000,
          jumpInd          = 16'b1100001000000000,
          relative         = 16'b1000000100000000,
// Specials
          rts              = 16'b0000101000100100,
          rti              = 16'b0000111000100010,
          brk              = 16'b1000111000000001,

          xxxxxxxx         = 16'bxxxxxxxxxxxxxxxx;

localparam [7:0]
  // A = accu
  // E = Accu | 0xEE (for ANE, LXA)
  // X = index X
  // Y = index Y
  // S = Stack pointer
  // H = indexH
  //
  //            AEXYSTHc
  aluInA   = 8'b10000000,
  aluInE   = 8'b01000000,
  aluInEXT = 8'b01100100,
  aluInET  = 8'b01000100,
  aluInX   = 8'b00100000,
  aluInXH  = 8'b00100010,
  aluInY   = 8'b00010000,
  aluInYH  = 8'b00010010,
  aluInS   = 8'b00001000,
  aluInT   = 8'b00000100,
  aluInAX  = 8'b10100000,
  aluInAXH = 8'b10100010,
  aluInAT  = 8'b10000100,
  aluInXT  = 8'b00100100,
  aluInST  = 8'b00001100,
  aluInSet = 8'b00000000,
  aluInClr = 8'b00000001,
  aluInXXX = 8'bxxxxxxxx;

  // Most of the aluModes are just like the opcodes.
  // aluModeInp -> input is output. calculate N and Z
  // aluModeCmp -> Compare for CMP, CPX, CPY
  // aluModeFlg -> input to flags needed for PLP, RTI and CLC, SEC, CLV
  // aluModeInc -> for INC but also INX, INY
  // aluModeDec -> for DEC but also DEX, DEY

  // subtype aluMode1 is unsigned(0 to 3);
localparam [3:0]
  // Logic/Shift ALU
  aluModeInp = 4'b0000,
  aluModeP   = 4'b0001,
  aluModeInc = 4'b0010,
  aluModeDec = 4'b0011,
  aluModeFlg = 4'b0100,
  aluModeBit = 4'b0101,
  // 0110
  // 0111
  aluModeLsr = 4'b1000,
  aluModeRor = 4'b1001,
  aluModeAsl = 4'b1010,
  aluModeRol = 4'b1011,
  // 1100
  // 1101
  // 1110
  aluModeAnc = 4'b1111;

  // subtype aluMode2 is unsigned(0 to 2);
localparam [2:0]
  // Arithmetic ALU
  aluModePss = 3'b000,
  aluModeCmp = 3'b001,
  aluModeAdc = 3'b010,
  aluModeSbc = 3'b011,
  aluModeAnd = 3'b100,
  aluModeOra = 3'b101,
  aluModeEor = 3'b110,
  aluModeArr = 3'b111;

  // subtype aluMode is unsigned(0 to 9);
localparam [9:0]
  aluInp = { aluModeInp, aluModePss, 3'bxxx },
  aluP   = { aluModeP  , aluModePss, 3'bxxx },
  aluInc = { aluModeInc, aluModePss, 3'bxxx },
  aluDec = { aluModeDec, aluModePss, 3'bxxx },
  aluFlg = { aluModeFlg, aluModePss, 3'bxxx },
  aluBit = { aluModeBit, aluModeAnd, 3'bxxx },
  aluRor = { aluModeRor, aluModePss, 3'bxxx },
  aluLsr = { aluModeLsr, aluModePss, 3'bxxx },
  aluRol = { aluModeRol, aluModePss, 3'bxxx },
  aluAsl = { aluModeAsl, aluModePss, 3'bxxx },

  aluCmp = { aluModeInp, aluModeCmp, 3'b100 },
  aluCpx = { aluModeInp, aluModeCmp, 3'b010 },
  aluCpy = { aluModeInp, aluModeCmp, 3'b001 },
  aluAdc = { aluModeInp, aluModeAdc, 3'bxxx },
  aluSbc = { aluModeInp, aluModeSbc, 3'bxxx },
  aluAnd = { aluModeInp, aluModeAnd, 3'bxxx },
  aluOra = { aluModeInp, aluModeOra, 3'bxxx },
  aluEor = { aluModeInp, aluModeEor, 3'bxxx },

  aluSlo = { aluModeAsl, aluModeOra, 3'bxxx },
  aluSre = { aluModeLsr, aluModeEor, 3'bxxx },
  aluRra = { aluModeRor, aluModeAdc, 3'bxxx },
  aluRla = { aluModeRol, aluModeAnd, 3'bxxx },
  aluDcp = { aluModeDec, aluModeCmp, 3'b100 },
  aluIsc = { aluModeInc, aluModeSbc, 3'bxxx },
  aluAnc = { aluModeAnc, aluModeAnd, 3'bxxx },
  aluArr = { aluModeRor, aluModeArr, 3'bxxx },
  aluSbx = { aluModeInp, aluModeCmp, 3'b110 },

  aluXXX = { 4'bxxxx   , 3'bxxx    , 3'bxxx };

localparam [0:0]
  // Stack operations. Push/Pop/None
  stackInc = 1'b0,
  stackDec = 1'b1,
  stackXXX = 1'bx;

  // subtype decodedBitsDef is unsigned(0 to 43);
  // type opcodeInfoTableDef is array(0 to 255) of decodedBitsDef;
  wire [43:0] opcodeInfoTable [0:255];
  //                                // +------- Update register A
  //                                // |+------ Update register X
  //                                // ||+----- Update register Y
  //                                // |||+---- Update register S
  //                                // ||||       +-- Update Flags
  //                                // ||||       |
  //                                // ||||      _|__
  //                                // ||||     /    \
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'h00] = { 4'b0000, 6'b000100, brk       , aluInXXX , aluP   };  // 00 BRK
  assign opcodeInfoTable[8'h01] = { 4'b1000, 6'b100010, readIndX  , aluInT   , aluOra };  // 01 ORA (zp,x)
  assign opcodeInfoTable[8'h02] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 02 *** JAM ***
  assign opcodeInfoTable[8'h03] = { 4'b1000, 6'b100011, rmwIndX   , aluInT   , aluSlo };  // 03 iSLO (zp,x)
  assign opcodeInfoTable[8'h04] = { 4'b0000, 6'b000000, readZp    , aluInXXX , aluXXX };  // 04 iNOP zp
  assign opcodeInfoTable[8'h05] = { 4'b1000, 6'b100010, readZp    , aluInT   , aluOra };  // 05 ORA zp
  assign opcodeInfoTable[8'h06] = { 4'b0000, 6'b100011, rmwZp     , aluInT   , aluAsl };  // 06 ASL zp
  assign opcodeInfoTable[8'h07] = { 4'b1000, 6'b100011, rmwZp     , aluInT   , aluSlo };  // 07 iSLO zp
  assign opcodeInfoTable[8'h08] = { 4'b0000, 6'b000000, push      , aluInXXX , aluP   };  // 08 PHP
  assign opcodeInfoTable[8'h09] = { 4'b1000, 6'b100010, immediate , aluInT   , aluOra };  // 09 ORA imm
  assign opcodeInfoTable[8'h0A] = { 4'b1000, 6'b100011, implied   , aluInA   , aluAsl };  // 0A ASL accu
  assign opcodeInfoTable[8'h0B] = { 4'b1000, 6'b100011, immediate , aluInT   , aluAnc };  // 0B iANC imm
  assign opcodeInfoTable[8'h0C] = { 4'b0000, 6'b000000, readAbs   , aluInXXX , aluXXX };  // 0C iNOP abs
  assign opcodeInfoTable[8'h0D] = { 4'b1000, 6'b100010, readAbs   , aluInT   , aluOra };  // 0D ORA abs
  assign opcodeInfoTable[8'h0E] = { 4'b0000, 6'b100011, rmwAbs    , aluInT   , aluAsl };  // 0E ASL abs
  assign opcodeInfoTable[8'h0F] = { 4'b1000, 6'b100011, rmwAbs    , aluInT   , aluSlo };  // 0F iSLO abs
  assign opcodeInfoTable[8'h10] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // 10 BPL
  assign opcodeInfoTable[8'h11] = { 4'b1000, 6'b100010, readIndY  , aluInT   , aluOra };  // 11 ORA (zp),y
  assign opcodeInfoTable[8'h12] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 12 *** JAM ***
  assign opcodeInfoTable[8'h13] = { 4'b1000, 6'b100011, rmwIndY   , aluInT   , aluSlo };  // 13 iSLO (zp),y
  assign opcodeInfoTable[8'h14] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // 14 iNOP zp,x
  assign opcodeInfoTable[8'h15] = { 4'b1000, 6'b100010, readZpX   , aluInT   , aluOra };  // 15 ORA zp,x
  assign opcodeInfoTable[8'h16] = { 4'b0000, 6'b100011, rmwZpX    , aluInT   , aluAsl };  // 16 ASL zp,x
  assign opcodeInfoTable[8'h17] = { 4'b1000, 6'b100011, rmwZpX    , aluInT   , aluSlo };  // 17 iSLO zp,x
  assign opcodeInfoTable[8'h18] = { 4'b0000, 6'b000001, implied   , aluInClr , aluFlg };  // 18 CLC
  assign opcodeInfoTable[8'h19] = { 4'b1000, 6'b100010, readAbsY  , aluInT   , aluOra };  // 19 ORA abs,y
  assign opcodeInfoTable[8'h1A] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // 1A iNOP implied
  assign opcodeInfoTable[8'h1B] = { 4'b1000, 6'b100011, rmwAbsY   , aluInT   , aluSlo };  // 1B iSLO abs,y
  assign opcodeInfoTable[8'h1C] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // 1C iNOP abs,x
  assign opcodeInfoTable[8'h1D] = { 4'b1000, 6'b100010, readAbsX  , aluInT   , aluOra };  // 1D ORA abs,x
  assign opcodeInfoTable[8'h1E] = { 4'b0000, 6'b100011, rmwAbsX   , aluInT   , aluAsl };  // 1E ASL abs,x
  assign opcodeInfoTable[8'h1F] = { 4'b1000, 6'b100011, rmwAbsX   , aluInT   , aluSlo };  // 1F iSLO abs,x
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'h20] = { 4'b0000, 6'b000000, jsr       , aluInXXX , aluXXX };  // 20 JSR
  assign opcodeInfoTable[8'h21] = { 4'b1000, 6'b100010, readIndX  , aluInT   , aluAnd };  // 21 AND (zp,x)
  assign opcodeInfoTable[8'h22] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 22 *** JAM ***
  assign opcodeInfoTable[8'h23] = { 4'b1000, 6'b100011, rmwIndX   , aluInT   , aluRla };  // 23 iRLA (zp,x)
  assign opcodeInfoTable[8'h24] = { 4'b0000, 6'b110010, readZp    , aluInT   , aluBit };  // 24 BIT zp
  assign opcodeInfoTable[8'h25] = { 4'b1000, 6'b100010, readZp    , aluInT   , aluAnd };  // 25 AND zp
  assign opcodeInfoTable[8'h26] = { 4'b0000, 6'b100011, rmwZp     , aluInT   , aluRol };  // 26 ROL zp
  assign opcodeInfoTable[8'h27] = { 4'b1000, 6'b100011, rmwZp     , aluInT   , aluRla };  // 27 iRLA zp
  assign opcodeInfoTable[8'h28] = { 4'b0000, 6'b111111, pop       , aluInT   , aluFlg };  // 28 PLP
  assign opcodeInfoTable[8'h29] = { 4'b1000, 6'b100010, immediate , aluInT   , aluAnd };  // 29 AND imm
  assign opcodeInfoTable[8'h2A] = { 4'b1000, 6'b100011, implied   , aluInA   , aluRol };  // 2A ROL accu
  assign opcodeInfoTable[8'h2B] = { 4'b1000, 6'b100011, immediate , aluInT   , aluAnc };  // 2B iANC imm
  assign opcodeInfoTable[8'h2C] = { 4'b0000, 6'b110010, readAbs   , aluInT   , aluBit };  // 2C BIT abs
  assign opcodeInfoTable[8'h2D] = { 4'b1000, 6'b100010, readAbs   , aluInT   , aluAnd };  // 2D AND abs
  assign opcodeInfoTable[8'h2E] = { 4'b0000, 6'b100011, rmwAbs    , aluInT   , aluRol };  // 2E ROL abs
  assign opcodeInfoTable[8'h2F] = { 4'b1000, 6'b100011, rmwAbs    , aluInT   , aluRla };  // 2F iRLA abs
  assign opcodeInfoTable[8'h30] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // 30 BMI
  assign opcodeInfoTable[8'h31] = { 4'b1000, 6'b100010, readIndY  , aluInT   , aluAnd };  // 31 AND (zp),y
  assign opcodeInfoTable[8'h32] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 32 *** JAM ***
  assign opcodeInfoTable[8'h33] = { 4'b1000, 6'b100011, rmwIndY   , aluInT   , aluRla };  // 33 iRLA (zp),y
  assign opcodeInfoTable[8'h34] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // 34 iNOP zp,x
  assign opcodeInfoTable[8'h35] = { 4'b1000, 6'b100010, readZpX   , aluInT   , aluAnd };  // 35 AND zp,x
  assign opcodeInfoTable[8'h36] = { 4'b0000, 6'b100011, rmwZpX    , aluInT   , aluRol };  // 36 ROL zp,x
  assign opcodeInfoTable[8'h37] = { 4'b1000, 6'b100011, rmwZpX    , aluInT   , aluRla };  // 37 iRLA zp,x
  assign opcodeInfoTable[8'h38] = { 4'b0000, 6'b000001, implied   , aluInSet , aluFlg };  // 38 SEC
  assign opcodeInfoTable[8'h39] = { 4'b1000, 6'b100010, readAbsY  , aluInT   , aluAnd };  // 39 AND abs,y
  assign opcodeInfoTable[8'h3A] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // 3A iNOP implied
  assign opcodeInfoTable[8'h3B] = { 4'b1000, 6'b100011, rmwAbsY   , aluInT   , aluRla };  // 3B iRLA abs,y
  assign opcodeInfoTable[8'h3C] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // 3C iNOP abs,x
  assign opcodeInfoTable[8'h3D] = { 4'b1000, 6'b100010, readAbsX  , aluInT   , aluAnd };  // 3D AND abs,x
  assign opcodeInfoTable[8'h3E] = { 4'b0000, 6'b100011, rmwAbsX   , aluInT   , aluRol };  // 3E ROL abs,x
  assign opcodeInfoTable[8'h3F] = { 4'b1000, 6'b100011, rmwAbsX   , aluInT   , aluRla };  // 3F iRLA abs,x
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'h40] = { 4'b0000, 6'b111111, rti       , aluInT   , aluFlg };  // 40 RTI
  assign opcodeInfoTable[8'h41] = { 4'b1000, 6'b100010, readIndX  , aluInT   , aluEor };  // 41 EOR (zp,x)
  assign opcodeInfoTable[8'h42] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 42 *** JAM ***
  assign opcodeInfoTable[8'h43] = { 4'b1000, 6'b100011, rmwIndX   , aluInT   , aluSre };  // 43 iSRE (zp,x)
  assign opcodeInfoTable[8'h44] = { 4'b0000, 6'b000000, readZp    , aluInXXX , aluXXX };  // 44 iNOP zp
  assign opcodeInfoTable[8'h45] = { 4'b1000, 6'b100010, readZp    , aluInT   , aluEor };  // 45 EOR zp
  assign opcodeInfoTable[8'h46] = { 4'b0000, 6'b100011, rmwZp     , aluInT   , aluLsr };  // 46 LSR zp
  assign opcodeInfoTable[8'h47] = { 4'b1000, 6'b100011, rmwZp     , aluInT   , aluSre };  // 47 iSRE zp
  assign opcodeInfoTable[8'h48] = { 4'b0000, 6'b000000, push      , aluInA   , aluInp };  // 48 PHA
  assign opcodeInfoTable[8'h49] = { 4'b1000, 6'b100010, immediate , aluInT   , aluEor };  // 49 EOR imm
  assign opcodeInfoTable[8'h4A] = { 4'b1000, 6'b100011, implied   , aluInA   , aluLsr };  // 4A LSR accu
  assign opcodeInfoTable[8'h4B] = { 4'b1000, 6'b100011, immediate , aluInAT  , aluLsr };  // 4B iALR imm
  assign opcodeInfoTable[8'h4C] = { 4'b0000, 6'b000000, jumpAbs   , aluInXXX , aluXXX };  // 4C JMP abs
  assign opcodeInfoTable[8'h4D] = { 4'b1000, 6'b100010, readAbs   , aluInT   , aluEor };  // 4D EOR abs
  assign opcodeInfoTable[8'h4E] = { 4'b0000, 6'b100011, rmwAbs    , aluInT   , aluLsr };  // 4E LSR abs
  assign opcodeInfoTable[8'h4F] = { 4'b1000, 6'b100011, rmwAbs    , aluInT   , aluSre };  // 4F iSRE abs
  assign opcodeInfoTable[8'h50] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // 50 BVC
  assign opcodeInfoTable[8'h51] = { 4'b1000, 6'b100010, readIndY  , aluInT   , aluEor };  // 51 EOR (zp),y
  assign opcodeInfoTable[8'h52] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 52 *** JAM ***
  assign opcodeInfoTable[8'h53] = { 4'b1000, 6'b100011, rmwIndY   , aluInT   , aluSre };  // 53 iSRE (zp),y
  assign opcodeInfoTable[8'h54] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // 54 iNOP zp,x
  assign opcodeInfoTable[8'h55] = { 4'b1000, 6'b100010, readZpX   , aluInT   , aluEor };  // 55 EOR zp,x
  assign opcodeInfoTable[8'h56] = { 4'b0000, 6'b100011, rmwZpX    , aluInT   , aluLsr };  // 56 LSR zp,x
  assign opcodeInfoTable[8'h57] = { 4'b1000, 6'b100011, rmwZpX    , aluInT   , aluSre };  // 57 SRE zp,x
  assign opcodeInfoTable[8'h58] = { 4'b0000, 6'b000100, implied   , aluInClr , aluXXX };  // 58 CLI
  assign opcodeInfoTable[8'h59] = { 4'b1000, 6'b100010, readAbsY  , aluInT   , aluEor };  // 59 EOR abs,y
  assign opcodeInfoTable[8'h5A] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // 5A iNOP implied
  assign opcodeInfoTable[8'h5B] = { 4'b1000, 6'b100011, rmwAbsY   , aluInT   , aluSre };  // 5B iSRE abs,y
  assign opcodeInfoTable[8'h5C] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // 5C iNOP abs,x
  assign opcodeInfoTable[8'h5D] = { 4'b1000, 6'b100010, readAbsX  , aluInT   , aluEor };  // 5D EOR abs,x
  assign opcodeInfoTable[8'h5E] = { 4'b0000, 6'b100011, rmwAbsX   , aluInT   , aluLsr };  // 5E LSR abs,x
  assign opcodeInfoTable[8'h5F] = { 4'b1000, 6'b100011, rmwAbsX   , aluInT   , aluSre };  // 5F SRE abs,x
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'h60] = { 4'b0000, 6'b000000, rts       , aluInXXX , aluXXX };  // 60 RTS
  assign opcodeInfoTable[8'h61] = { 4'b1000, 6'b110011, readIndX  , aluInT   , aluAdc };  // 61 ADC (zp,x)
  assign opcodeInfoTable[8'h62] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 62 *** JAM ***
  assign opcodeInfoTable[8'h63] = { 4'b1000, 6'b110011, rmwIndX   , aluInT   , aluRra };  // 63 iRRA (zp,x)
  assign opcodeInfoTable[8'h64] = { 4'b0000, 6'b000000, readZp    , aluInXXX , aluXXX };  // 64 iNOP zp
  assign opcodeInfoTable[8'h65] = { 4'b1000, 6'b110011, readZp    , aluInT   , aluAdc };  // 65 ADC zp
  assign opcodeInfoTable[8'h66] = { 4'b0000, 6'b100011, rmwZp     , aluInT   , aluRor };  // 66 ROR zp
  assign opcodeInfoTable[8'h67] = { 4'b1000, 6'b110011, rmwZp     , aluInT   , aluRra };  // 67 iRRA zp
  assign opcodeInfoTable[8'h68] = { 4'b1000, 6'b100010, pop       , aluInT   , aluInp };  // 68 PLA
  assign opcodeInfoTable[8'h69] = { 4'b1000, 6'b110011, immediate , aluInT   , aluAdc };  // 69 ADC imm
  assign opcodeInfoTable[8'h6A] = { 4'b1000, 6'b100011, implied   , aluInA   , aluRor };  // 6A ROR accu
  assign opcodeInfoTable[8'h6B] = { 4'b1000, 6'b110011, immediate , aluInAT  , aluArr };  // 6B iARR imm
  assign opcodeInfoTable[8'h6C] = { 4'b0000, 6'b000000, jumpInd   , aluInXXX , aluXXX };  // 6C JMP indirect
  assign opcodeInfoTable[8'h6D] = { 4'b1000, 6'b110011, readAbs   , aluInT   , aluAdc };  // 6D ADC abs
  assign opcodeInfoTable[8'h6E] = { 4'b0000, 6'b100011, rmwAbs    , aluInT   , aluRor };  // 6E ROR abs
  assign opcodeInfoTable[8'h6F] = { 4'b1000, 6'b110011, rmwAbs    , aluInT   , aluRra };  // 6F iRRA abs
  assign opcodeInfoTable[8'h70] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // 70 BVS
  assign opcodeInfoTable[8'h71] = { 4'b1000, 6'b110011, readIndY  , aluInT   , aluAdc };  // 71 ADC (zp),y
  assign opcodeInfoTable[8'h72] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 72 *** JAM ***
  assign opcodeInfoTable[8'h73] = { 4'b1000, 6'b110011, rmwIndY   , aluInT   , aluRra };  // 73 iRRA (zp),y
  assign opcodeInfoTable[8'h74] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // 74 iNOP zp,x
  assign opcodeInfoTable[8'h75] = { 4'b1000, 6'b110011, readZpX   , aluInT   , aluAdc };  // 75 ADC zp,x
  assign opcodeInfoTable[8'h76] = { 4'b0000, 6'b100011, rmwZpX    , aluInT   , aluRor };  // 76 ROR zp,x
  assign opcodeInfoTable[8'h77] = { 4'b1000, 6'b110011, rmwZpX    , aluInT   , aluRra };  // 77 iRRA zp,x
  assign opcodeInfoTable[8'h78] = { 4'b0000, 6'b000100, implied   , aluInSet , aluXXX };  // 78 SEI
  assign opcodeInfoTable[8'h79] = { 4'b1000, 6'b110011, readAbsY  , aluInT   , aluAdc };  // 79 ADC abs,y
  assign opcodeInfoTable[8'h7A] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // 7A iNOP implied
  assign opcodeInfoTable[8'h7B] = { 4'b1000, 6'b110011, rmwAbsY   , aluInT   , aluRra };  // 7B iRRA abs,y
  assign opcodeInfoTable[8'h7C] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // 7C iNOP abs,x
  assign opcodeInfoTable[8'h7D] = { 4'b1000, 6'b110011, readAbsX  , aluInT   , aluAdc };  // 7D ADC abs,x
  assign opcodeInfoTable[8'h7E] = { 4'b0000, 6'b100011, rmwAbsX   , aluInT   , aluRor };  // 7E ROR abs,x
  assign opcodeInfoTable[8'h7F] = { 4'b1000, 6'b110011, rmwAbsX   , aluInT   , aluRra };  // 7F iRRA abs,x
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'h80] = { 4'b0000, 6'b000000, immediate , aluInXXX , aluXXX };  // 80 iNOP imm
  assign opcodeInfoTable[8'h81] = { 4'b0000, 6'b000000, writeIndX , aluInA   , aluInp };  // 81 STA (zp,x)
  assign opcodeInfoTable[8'h82] = { 4'b0000, 6'b000000, immediate , aluInXXX , aluXXX };  // 82 iNOP imm
  assign opcodeInfoTable[8'h83] = { 4'b0000, 6'b000000, writeIndX , aluInAX  , aluInp };  // 83 iSAX (zp,x)
  assign opcodeInfoTable[8'h84] = { 4'b0000, 6'b000000, writeZp   , aluInY   , aluInp };  // 84 STY zp
  assign opcodeInfoTable[8'h85] = { 4'b0000, 6'b000000, writeZp   , aluInA   , aluInp };  // 85 STA zp
  assign opcodeInfoTable[8'h86] = { 4'b0000, 6'b000000, writeZp   , aluInX   , aluInp };  // 86 STX zp
  assign opcodeInfoTable[8'h87] = { 4'b0000, 6'b000000, writeZp   , aluInAX  , aluInp };  // 87 iSAX zp
  assign opcodeInfoTable[8'h88] = { 4'b0010, 6'b100010, implied   , aluInY   , aluDec };  // 88 DEY
  assign opcodeInfoTable[8'h89] = { 4'b0000, 6'b000000, immediate , aluInXXX , aluXXX };  // 84 iNOP imm
  assign opcodeInfoTable[8'h8A] = { 4'b1000, 6'b100010, implied   , aluInX   , aluInp };  // 8A TXA
  assign opcodeInfoTable[8'h8B] = { 4'b1000, 6'b100010, immediate , aluInEXT , aluInp };  // 8B iANE imm
  assign opcodeInfoTable[8'h8C] = { 4'b0000, 6'b000000, writeAbs  , aluInY   , aluInp };  // 8C STY abs
  assign opcodeInfoTable[8'h8D] = { 4'b0000, 6'b000000, writeAbs  , aluInA   , aluInp };  // 8D STA abs
  assign opcodeInfoTable[8'h8E] = { 4'b0000, 6'b000000, writeAbs  , aluInX   , aluInp };  // 8E STX abs
  assign opcodeInfoTable[8'h8F] = { 4'b0000, 6'b000000, writeAbs  , aluInAX  , aluInp };  // 8F iSAX abs
  assign opcodeInfoTable[8'h90] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // 90 BCC
  assign opcodeInfoTable[8'h91] = { 4'b0000, 6'b000000, writeIndY , aluInA   , aluInp };  // 91 STA (zp),y
  assign opcodeInfoTable[8'h92] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // 92 *** JAM ***
  assign opcodeInfoTable[8'h93] = { 4'b0000, 6'b000000, writeIndY , aluInAXH , aluInp };  // 93 iAHX (zp),y
  assign opcodeInfoTable[8'h94] = { 4'b0000, 6'b000000, writeZpX  , aluInY   , aluInp };  // 94 STY zp,x
  assign opcodeInfoTable[8'h95] = { 4'b0000, 6'b000000, writeZpX  , aluInA   , aluInp };  // 95 STA zp,x
  assign opcodeInfoTable[8'h96] = { 4'b0000, 6'b000000, writeZpY  , aluInX   , aluInp };  // 96 STX zp,y
  assign opcodeInfoTable[8'h97] = { 4'b0000, 6'b000000, writeZpY  , aluInAX  , aluInp };  // 97 iSAX zp,y
  assign opcodeInfoTable[8'h98] = { 4'b1000, 6'b100010, implied   , aluInY   , aluInp };  // 98 TYA
  assign opcodeInfoTable[8'h99] = { 4'b0000, 6'b000000, writeAbsY , aluInA   , aluInp };  // 99 STA abs,y
  assign opcodeInfoTable[8'h9A] = { 4'b0001, 6'b000000, implied   , aluInX   , aluInp };  // 9A TXS
  assign opcodeInfoTable[8'h9B] = { 4'b0001, 6'b000000, writeAbsY , aluInAXH , aluInp };  // 9B iSHS abs,y
  assign opcodeInfoTable[8'h9C] = { 4'b0000, 6'b000000, writeAbsX , aluInYH  , aluInp };  // 9C iSHY abs,x
  assign opcodeInfoTable[8'h9D] = { 4'b0000, 6'b000000, writeAbsX , aluInA   , aluInp };  // 9D STA abs,x
  assign opcodeInfoTable[8'h9E] = { 4'b0000, 6'b000000, writeAbsY , aluInXH  , aluInp };  // 9E iSHX abs,y
  assign opcodeInfoTable[8'h9F] = { 4'b0000, 6'b000000, writeAbsY , aluInAXH , aluInp };  // 9F iAHX abs,y
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'hA0] = { 4'b0010, 6'b100010, immediate , aluInT   , aluInp };  // A0 LDY imm
  assign opcodeInfoTable[8'hA1] = { 4'b1000, 6'b100010, readIndX  , aluInT   , aluInp };  // A1 LDA (zp,x)
  assign opcodeInfoTable[8'hA2] = { 4'b0100, 6'b100010, immediate , aluInT   , aluInp };  // A2 LDX imm
  assign opcodeInfoTable[8'hA3] = { 4'b1100, 6'b100010, readIndX  , aluInT   , aluInp };  // A3 LAX (zp,x)
  assign opcodeInfoTable[8'hA4] = { 4'b0010, 6'b100010, readZp    , aluInT   , aluInp };  // A4 LDY zp
  assign opcodeInfoTable[8'hA5] = { 4'b1000, 6'b100010, readZp    , aluInT   , aluInp };  // A5 LDA zp
  assign opcodeInfoTable[8'hA6] = { 4'b0100, 6'b100010, readZp    , aluInT   , aluInp };  // A6 LDX zp
  assign opcodeInfoTable[8'hA7] = { 4'b1100, 6'b100010, readZp    , aluInT   , aluInp };  // A7 iLAX zp
  assign opcodeInfoTable[8'hA8] = { 4'b0010, 6'b100010, implied   , aluInA   , aluInp };  // A8 TAY
  assign opcodeInfoTable[8'hA9] = { 4'b1000, 6'b100010, immediate , aluInT   , aluInp };  // A9 LDA imm
  assign opcodeInfoTable[8'hAA] = { 4'b0100, 6'b100010, implied   , aluInA   , aluInp };  // AA TAX
  assign opcodeInfoTable[8'hAB] = { 4'b1100, 6'b100010, immediate , aluInET  , aluInp };  // AB iLXA imm
  assign opcodeInfoTable[8'hAC] = { 4'b0010, 6'b100010, readAbs   , aluInT   , aluInp };  // AC LDY abs
  assign opcodeInfoTable[8'hAD] = { 4'b1000, 6'b100010, readAbs   , aluInT   , aluInp };  // AD LDA abs
  assign opcodeInfoTable[8'hAE] = { 4'b0100, 6'b100010, readAbs   , aluInT   , aluInp };  // AE LDX abs
  assign opcodeInfoTable[8'hAF] = { 4'b1100, 6'b100010, readAbs   , aluInT   , aluInp };  // AF iLAX abs
  assign opcodeInfoTable[8'hB0] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // B0 BCS
  assign opcodeInfoTable[8'hB1] = { 4'b1000, 6'b100010, readIndY  , aluInT   , aluInp };  // B1 LDA (zp),y
  assign opcodeInfoTable[8'hB2] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // B2 *** JAM ***
  assign opcodeInfoTable[8'hB3] = { 4'b1100, 6'b100010, readIndY  , aluInT   , aluInp };  // B3 iLAX (zp),y
  assign opcodeInfoTable[8'hB4] = { 4'b0010, 6'b100010, readZpX   , aluInT   , aluInp };  // B4 LDY zp,x
  assign opcodeInfoTable[8'hB5] = { 4'b1000, 6'b100010, readZpX   , aluInT   , aluInp };  // B5 LDA zp,x
  assign opcodeInfoTable[8'hB6] = { 4'b0100, 6'b100010, readZpY   , aluInT   , aluInp };  // B6 LDX zp,y
  assign opcodeInfoTable[8'hB7] = { 4'b1100, 6'b100010, readZpY   , aluInT   , aluInp };  // B7 iLAX zp,y
  assign opcodeInfoTable[8'hB8] = { 4'b0000, 6'b010000, implied   , aluInClr , aluFlg };  // B8 CLV
  assign opcodeInfoTable[8'hB9] = { 4'b1000, 6'b100010, readAbsY  , aluInT   , aluInp };  // B9 LDA abs,y
  assign opcodeInfoTable[8'hBA] = { 4'b0100, 6'b100010, implied   , aluInS   , aluInp };  // BA TSX
  assign opcodeInfoTable[8'hBB] = { 4'b1101, 6'b100010, readAbsY  , aluInST  , aluInp };  // BB iLAS abs,y
  assign opcodeInfoTable[8'hBC] = { 4'b0010, 6'b100010, readAbsX  , aluInT   , aluInp };  // BC LDY abs,x
  assign opcodeInfoTable[8'hBD] = { 4'b1000, 6'b100010, readAbsX  , aluInT   , aluInp };  // BD LDA abs,x
  assign opcodeInfoTable[8'hBE] = { 4'b0100, 6'b100010, readAbsY  , aluInT   , aluInp };  // BE LDX abs,y
  assign opcodeInfoTable[8'hBF] = { 4'b1100, 6'b100010, readAbsY  , aluInT   , aluInp };  // BF iLAX abs,y
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'hC0] = { 4'b0000, 6'b100011, immediate , aluInT   , aluCpy };  // C0 CPY imm
  assign opcodeInfoTable[8'hC1] = { 4'b0000, 6'b100011, readIndX  , aluInT   , aluCmp };  // C1 CMP (zp,x)
  assign opcodeInfoTable[8'hC2] = { 4'b0000, 6'b000000, immediate , aluInXXX , aluXXX };  // C2 iNOP imm
  assign opcodeInfoTable[8'hC3] = { 4'b0000, 6'b100011, rmwIndX   , aluInT   , aluDcp };  // C3 iDCP (zp,x)
  assign opcodeInfoTable[8'hC4] = { 4'b0000, 6'b100011, readZp    , aluInT   , aluCpy };  // C4 CPY zp
  assign opcodeInfoTable[8'hC5] = { 4'b0000, 6'b100011, readZp    , aluInT   , aluCmp };  // C5 CMP zp
  assign opcodeInfoTable[8'hC6] = { 4'b0000, 6'b100010, rmwZp     , aluInT   , aluDec };  // C6 DEC zp
  assign opcodeInfoTable[8'hC7] = { 4'b0000, 6'b100011, rmwZp     , aluInT   , aluDcp };  // C7 iDCP zp
  assign opcodeInfoTable[8'hC8] = { 4'b0010, 6'b100010, implied   , aluInY   , aluInc };  // C8 INY
  assign opcodeInfoTable[8'hC9] = { 4'b0000, 6'b100011, immediate , aluInT   , aluCmp };  // C9 CMP imm
  assign opcodeInfoTable[8'hCA] = { 4'b0100, 6'b100010, implied   , aluInX   , aluDec };  // CA DEX
  assign opcodeInfoTable[8'hCB] = { 4'b0100, 6'b100011, immediate , aluInT   , aluSbx };  // CB SBX imm
  assign opcodeInfoTable[8'hCC] = { 4'b0000, 6'b100011, readAbs   , aluInT   , aluCpy };  // CC CPY abs
  assign opcodeInfoTable[8'hCD] = { 4'b0000, 6'b100011, readAbs   , aluInT   , aluCmp };  // CD CMP abs
  assign opcodeInfoTable[8'hCE] = { 4'b0000, 6'b100010, rmwAbs    , aluInT   , aluDec };  // CE DEC abs
  assign opcodeInfoTable[8'hCF] = { 4'b0000, 6'b100011, rmwAbs    , aluInT   , aluDcp };  // CF iDCP abs
  assign opcodeInfoTable[8'hD0] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // D0 BNE
  assign opcodeInfoTable[8'hD1] = { 4'b0000, 6'b100011, readIndY  , aluInT   , aluCmp };  // D1 CMP (zp),y
  assign opcodeInfoTable[8'hD2] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // D2 *** JAM ***
  assign opcodeInfoTable[8'hD3] = { 4'b0000, 6'b100011, rmwIndY   , aluInT   , aluDcp };  // D3 iDCP (zp),y
  assign opcodeInfoTable[8'hD4] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // D4 iNOP zp,x
  assign opcodeInfoTable[8'hD5] = { 4'b0000, 6'b100011, readZpX   , aluInT   , aluCmp };  // D5 CMP zp,x
  assign opcodeInfoTable[8'hD6] = { 4'b0000, 6'b100010, rmwZpX    , aluInT   , aluDec };  // D6 DEC zp,x
  assign opcodeInfoTable[8'hD7] = { 4'b0000, 6'b100011, rmwZpX    , aluInT   , aluDcp };  // D7 iDCP zp,x
  assign opcodeInfoTable[8'hD8] = { 4'b0000, 6'b001000, implied   , aluInClr , aluXXX };  // D8 CLD
  assign opcodeInfoTable[8'hD9] = { 4'b0000, 6'b100011, readAbsY  , aluInT   , aluCmp };  // D9 CMP abs,y
  assign opcodeInfoTable[8'hDA] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // DA iNOP implied
  assign opcodeInfoTable[8'hDB] = { 4'b0000, 6'b100011, rmwAbsY   , aluInT   , aluDcp };  // DB iDCP abs,y
  assign opcodeInfoTable[8'hDC] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // DC iNOP abs,x
  assign opcodeInfoTable[8'hDD] = { 4'b0000, 6'b100011, readAbsX  , aluInT   , aluCmp };  // DD CMP abs,x
  assign opcodeInfoTable[8'hDE] = { 4'b0000, 6'b100010, rmwAbsX   , aluInT   , aluDec };  // DE DEC abs,x
  assign opcodeInfoTable[8'hDF] = { 4'b0000, 6'b100011, rmwAbsX   , aluInT   , aluDcp };  // DF iDCP abs,x
  //                                // AXYS     NVDIZC  addressing  aluInput   aluMode
  assign opcodeInfoTable[8'hE0] = { 4'b0000, 6'b100011, immediate , aluInT   , aluCpx };  // E0 CPX imm
  assign opcodeInfoTable[8'hE1] = { 4'b1000, 6'b110011, readIndX  , aluInT   , aluSbc };  // E1 SBC (zp,x)
  assign opcodeInfoTable[8'hE2] = { 4'b0000, 6'b000000, immediate , aluInXXX , aluXXX };  // E2 iNOP imm
  assign opcodeInfoTable[8'hE3] = { 4'b1000, 6'b110011, rmwIndX   , aluInT   , aluIsc };  // E3 iISC (zp,x)
  assign opcodeInfoTable[8'hE4] = { 4'b0000, 6'b100011, readZp    , aluInT   , aluCpx };  // E4 CPX zp
  assign opcodeInfoTable[8'hE5] = { 4'b1000, 6'b110011, readZp    , aluInT   , aluSbc };  // E5 SBC zp
  assign opcodeInfoTable[8'hE6] = { 4'b0000, 6'b100010, rmwZp     , aluInT   , aluInc };  // E6 INC zp
  assign opcodeInfoTable[8'hE7] = { 4'b1000, 6'b110011, rmwZp     , aluInT   , aluIsc };  // E7 iISC zp
  assign opcodeInfoTable[8'hE8] = { 4'b0100, 6'b100010, implied   , aluInX   , aluInc };  // E8 INX
  assign opcodeInfoTable[8'hE9] = { 4'b1000, 6'b110011, immediate , aluInT   , aluSbc };  // E9 SBC imm
  assign opcodeInfoTable[8'hEA] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // EA NOP
  assign opcodeInfoTable[8'hEB] = { 4'b1000, 6'b110011, immediate , aluInT   , aluSbc };  // EB SBC imm (illegal opc)
  assign opcodeInfoTable[8'hEC] = { 4'b0000, 6'b100011, readAbs   , aluInT   , aluCpx };  // EC CPX abs
  assign opcodeInfoTable[8'hED] = { 4'b1000, 6'b110011, readAbs   , aluInT   , aluSbc };  // ED SBC abs
  assign opcodeInfoTable[8'hEE] = { 4'b0000, 6'b100010, rmwAbs    , aluInT   , aluInc };  // EE INC abs
  assign opcodeInfoTable[8'hEF] = { 4'b1000, 6'b110011, rmwAbs    , aluInT   , aluIsc };  // EF iISC abs
  assign opcodeInfoTable[8'hF0] = { 4'b0000, 6'b000000, relative  , aluInXXX , aluXXX };  // F0 BEQ
  assign opcodeInfoTable[8'hF1] = { 4'b1000, 6'b110011, readIndY  , aluInT   , aluSbc };  // F1 SBC (zp),y
  assign opcodeInfoTable[8'hF2] = { 4'bxxxx, 6'bxxxxxx, xxxxxxxx  , aluInXXX , aluXXX };  // F2 *** JAM ***
  assign opcodeInfoTable[8'hF3] = { 4'b1000, 6'b110011, rmwIndY   , aluInT   , aluIsc };  // F3 iISC (zp),y
  assign opcodeInfoTable[8'hF4] = { 4'b0000, 6'b000000, readZpX   , aluInXXX , aluXXX };  // F4 iNOP zp,x
  assign opcodeInfoTable[8'hF5] = { 4'b1000, 6'b110011, readZpX   , aluInT   , aluSbc };  // F5 SBC zp,x
  assign opcodeInfoTable[8'hF6] = { 4'b0000, 6'b100010, rmwZpX    , aluInT   , aluInc };  // F6 INC zp,x
  assign opcodeInfoTable[8'hF7] = { 4'b1000, 6'b110011, rmwZpX    , aluInT   , aluIsc };  // F7 iISC zp,x
  assign opcodeInfoTable[8'hF8] = { 4'b0000, 6'b001000, implied   , aluInSet , aluXXX };  // F8 SED
  assign opcodeInfoTable[8'hF9] = { 4'b1000, 6'b110011, readAbsY  , aluInT   , aluSbc };  // F9 SBC abs,y
  assign opcodeInfoTable[8'hFA] = { 4'b0000, 6'b000000, implied   , aluInXXX , aluXXX };  // FA iNOP implied
  assign opcodeInfoTable[8'hFB] = { 4'b1000, 6'b110011, rmwAbsY   , aluInT   , aluIsc };  // FB iISC abs,y
  assign opcodeInfoTable[8'hFC] = { 4'b0000, 6'b000000, readAbsX  , aluInXXX , aluXXX };  // FC iNOP abs,x
  assign opcodeInfoTable[8'hFD] = { 4'b1000, 6'b110011, readAbsX  , aluInT   , aluSbc };  // FD SBC abs,x
  assign opcodeInfoTable[8'hFE] = { 4'b0000, 6'b100010, rmwAbsX   , aluInT   , aluInc };  // FE INC abs,x
  assign opcodeInfoTable[8'hFF] = { 4'b1000, 6'b110011, rmwAbsX   , aluInT   , aluIsc };  // FF iISC abs,x

  reg  [43:0] opcInfo;
  wire [43:0] nextOpcInfo;     // Next opcode (decoded)
  reg  [43:0] nextOpcInfoReg;  // Next opcode (decoded) pipelined
  reg  [ 7:0] theOpcode;
  reg  [ 7:0] nextOpcode;

  reg  [15:0] PC;              // Program counter

// Address generation
// type nextAddrDef is
localparam [3:0]
  nextAddrHold       = 4'b0000,
  nextAddrIncr       = 4'b0001,
  nextAddrIncrL      = 4'b0010, // Increment low bits only (zeropage accesses)
  nextAddrIncrH      = 4'b0011, // Increment high bits only (page-boundary)
  nextAddrDecrH      = 4'b0100, // Decrement high bits (branch backwards)
  nextAddrPc         = 4'b0101,
  nextAddrIrq        = 4'b0110,
  nextAddrReset      = 4'b0111,
  nextAddrAbs        = 4'b1000,
  nextAddrAbsIndexed = 4'b1001,
  nextAddrZeroPage   = 4'b1010,
  nextAddrZPIndexed  = 4'b1011,
  nextAddrStack      = 4'b1100,
  nextAddrRelative   = 4'b1101;

  reg   [3:0] nextAddr;
  reg  [15:0] myAddr;
  wire [15:0] myAddrIncr;
  wire  [7:0] myAddrIncrH;
  wire  [7:0] myAddrDecrH;
  reg         theWe;

  reg         irqActive;

  // Output register
  reg   [7:0] doReg;

  // Buffer register
  reg   [7:0] T;

  // General registers
  reg   [7:0] A; // Accumulator
  reg   [7:0] X; // Index X
  reg   [7:0] Y; // Index Y
  reg   [7:0] S; // stack pointer

  // Status register
  reg         C; // Carry
  reg         Z; // Zero flag
  reg         I; // Interrupt flag
  reg         D; // Decimal mode
  reg         V; // Overflow
  reg         N; // Negative

  // ALU
  // ALU input
  wire  [7:0] aluInput;
  wire  [7:0] aluCmpInput;
  // ALU output
  wire  [7:0] aluRegisterOut;
  wire  [7:0] aluRmwOut;
  wire        aluC;
  wire        aluZ;
  wire        aluV;
  wire        aluN;
  // Pipeline registers
  reg   [7:0] aluInputReg;
  reg   [7:0] aluCmpInputReg;
  reg   [7:0] aluRmwReg;
  reg   [7:0] aluNineReg;
  reg         aluCReg;
  reg         aluZReg;
  reg         aluVReg;
  reg         aluNReg;

  // Indexing
  reg   [8:0] indexOut;

  // Internals
  wire  [7:0] aluTemp;
  wire  [7:0] aluTemp0;
  wire  [7:0] aluTemp1;
  wire  [7:0] aluTemp2;
  wire  [7:0] aluTemp3;
  wire  [7:0] aluTemp4;
  wire  [7:0] aluTemp5;
  wire  [7:0] aluTemp6;

  wire  [7:0] cmpTemp;
  wire  [7:0] cmpTemp0;
  wire  [7:0] cmpTemp1;
  wire  [7:0] cmpTemp2;

  wire  [5:0] lowBits;

  wire  [8:0] nineBits;
  wire  [8:0] nineBits0;
  wire  [8:0] nineBits1;

  wire  [8:0] rmwBits;

  wire        varC;
  wire        varC0;

  wire        varZ;

  wire        varV;
  wire        varV0;
  wire        varV1;

  wire        varN;

  wire  [3:0] aluMode1;
  wire  [2:0] aluMode2;

  wire  [7:0] myNextOpcode;

  reg   [7:0] sIncDec;
  reg         updateFlag;

  // processAluInput
  assign aluTemp0 =                        8'hFF;
  assign aluTemp1 = opcInfo[`opcInA]     ? (aluTemp0 & A)           : aluTemp0;
  assign aluTemp2 = opcInfo[`opcInE]     ? (aluTemp1 & (A | 8'hEE)) : aluTemp1;
  assign aluTemp3 = opcInfo[`opcInX]     ? (aluTemp2 & X)           : aluTemp2;
  assign aluTemp4 = opcInfo[`opcInY]     ? (aluTemp3 & Y)           : aluTemp3;
  assign aluTemp5 = opcInfo[`opcInS]     ? (aluTemp4 & S)           : aluTemp4;
  assign aluTemp6 = opcInfo[`opcInT]     ? (aluTemp5 & T)           : aluTemp5;
  assign aluTemp  = opcInfo[`opcInClear] ? 8'h00                    : aluTemp6;
  always @(posedge clk)
  begin
    aluInputReg <= aluTemp;
  end
  assign aluInput = pipelineAluMux ? aluInputReg : aluTemp;

  // processCmpInput
  assign cmpTemp0 =                      8'hFF;
  assign cmpTemp1 = opcInfo[`opcInCmp] ? (cmpTemp0 & A) : cmpTemp0;
  assign cmpTemp2 = opcInfo[`opcInCpx] ? (cmpTemp1 & X) : cmpTemp1;
  assign cmpTemp  = opcInfo[`opcInCpy] ? (cmpTemp2 & Y) : cmpTemp2;
  always @(posedge clk)
  begin
    aluCmpInputReg <= cmpTemp;
  end
  assign aluCmpInput = pipelineAluMux ? aluCmpInputReg : cmpTemp;

  // processAlu
  assign varV0 = aluInput[6];

  assign aluMode1 = opcInfo[`aluMode1From:`aluMode1To];
  assign rmwBits = (aluMode1 == aluModeInp) ? {C, aluInput} :
                   (aluMode1 == aluModeP  ) ? {C, N, V, 1'b1, ~irqActive, D, I, Z, C} :
                   (aluMode1 == aluModeInc) ? {C, aluInput + 8'd1} :
                   (aluMode1 == aluModeDec) ? {C, aluInput - 8'd1} :
                   (aluMode1 == aluModeAsl) ? {aluInput, 1'b0} :
                   (aluMode1 == aluModeFlg) ? {aluInput[0], aluInput} :
                   (aluMode1 == aluModeLsr) ? {aluInput[0], 1'b0, aluInput[7:1]} :
                   (aluMode1 == aluModeRol) ? {aluInput, C} :
                   (aluMode1 == aluModeRor) ? {aluInput[0], C, aluInput[7:1]} :
                   (aluMode1 == aluModeAnc) ? {aluInput[7] & A[7], aluInput} :
                   {C, aluInput};

  assign aluMode2 = opcInfo[`aluMode2From:`aluMode2To];
  assign lowBits = (aluMode2 == aluModeAdc) ? {1'b0, A[3:0], rmwBits[8]} + {1'b0, rmwBits[3:0], 1'b1} :
                   (aluMode2 == aluModeSbc) ? {1'b0, A[3:0], rmwBits[8]} + {1'b0, ~rmwBits[3:0], 1'b1} :
                   {6'b111111};

  assign nineBits0 = (aluMode2 == aluModeAdc) ? {1'b0, A} + {1'b0, rmwBits[7:0]} + {8'b00000000, rmwBits[8]} :
                     (aluMode2 == aluModeSbc) ? {1'b0, A} + {1'b0, ~rmwBits[7:0]} + {8'b00000000, rmwBits[8]} :
                     (aluMode2 == aluModeCmp) ? {1'b0, aluCmpInput} + {1'b0, ~rmwBits[7:0]} + 9'd1 :
                     (aluMode2 == aluModeAnd) ? {rmwBits[8], A & rmwBits[7:0]} :
                     (aluMode2 == aluModeEor) ? {rmwBits[8], A ^ rmwBits[7:0]} :
                     (aluMode2 == aluModeOra) ? {rmwBits[8], A | rmwBits[7:0]} :
                     rmwBits;

  assign varZ = (aluMode1 == aluModeFlg) ? rmwBits[1] :
                (nineBits0[7:0] == 8'd0) ? 1'b1 :
                1'b0;

  assign nineBits1[3:0] = (aluMode2 == aluModeAdc) & D & (lowBits[5:1] > 5'd9)
                          ? nineBits0[3:0] + 4'd6 : nineBits0[3:0];
  assign nineBits1[8:4] = (aluMode2 == aluModeAdc) & D & (lowBits[5:1] > 5'd9)
                          & ~lowBits[5]
                          ? nineBits0[8:4] + 5'd1 : nineBits0[8:4];

  assign varN = (aluMode1 == aluModeBit) || (aluMode1 == aluModeFlg) ? rmwBits[7] : nineBits1[7];

  assign varC0 = (aluMode2 == aluModeArr) ? aluInput[7] : nineBits1[8];

  assign varV1 = (aluMode2 == aluModeArr) ? aluInput[7] ^ aluInput[6] : varV0;

  assign varV = (aluMode2 == aluModeAdc) ? (A[7] ^ nineBits1[7]) & (rmwBits[7] ^ nineBits1[7]) :
                (aluMode2 == aluModeSbc) ? (A[7] ^ nineBits1[7]) & (~rmwBits[7] ^ nineBits1[7]) :
                varV1;

  assign nineBits[8:4] = (aluMode2 == aluModeAdc) & D & (nineBits1[8:4] > 5'd9) ? nineBits1[8:4] + 5'd6 :
                         (aluMode2 == aluModeSbc) & D & ~nineBits1[8] ? nineBits1[8:4] - 5'd6 :
                         (aluMode2 == aluModeArr) & D & (({1'b0, aluInput[7:4]} + {4'd0, aluInput[4]}) > 5'd5) ? nineBits1[8:4] + 5'd6 :
                         nineBits1[8:4];

  assign nineBits[3:0] = (aluMode2 == aluModeSbc) & D & ~lowBits[5] ? nineBits1[3:0] - 4'd6 :
                         (aluMode2 == aluModeArr) & D & (({1'b0, aluInput[3:0]} + {4'd0, aluInput[0]}) > 5'd5) ? nineBits1[3:0] + 4'd6 :
                         nineBits1[3:0];

  assign varC = (aluMode2 == aluModeAdc) & D & (nineBits1[8:4] > 5'd9) ? 1'b1 :
                (aluMode2 == aluModeArr) & D & (({1'b0, aluInput[7:4]} + {4'd0, aluInput[4]}) > 5'd5) ? 1'b1 :
                (aluMode2 == aluModeArr) & D ? 1'b0 :
                varC0;

  always @(posedge clk)
  begin
    aluRmwReg <= rmwBits[7:0];
    aluNineReg <= nineBits[7:0];
    aluCReg <= varC;
    aluZReg <= varZ;
    aluVReg <= varV;
    aluNReg <= varN;
  end

  assign aluRmwOut = pipelineAluOut ? aluRmwReg : rmwBits[7:0];
  assign aluRegisterOut = pipelineAluOut ? aluNineReg : nineBits[7:0];
  assign aluC = pipelineAluOut ? aluCReg : varC;
  assign aluZ = pipelineAluOut ? aluZReg : varZ;
  assign aluV = pipelineAluOut ? aluVReg : varV;
  assign aluN = pipelineAluOut ? aluNReg : varN;

  // calcInterrupt: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      if ((theCpuCycle == cycleStack4) || reset) begin
        nmiReg <= 1'b1;
      end

      if ((nextCpuCycle != cycleBranchTaken) && (nextCpuCycle != opcodeFetch)) begin
        irqReg <= irq_n;
        nmiEdge <= nmi_n;
        if (nmiEdge && !nmi_n) begin
          nmiReg <= 1'b0;
        end
      end
      // The 'or opcInfo(opcSetI)' prevents NMI immediately after BRK or IRQ.
      // Presumably this is done in the real 6502/6510 to prevent a double IRQ.
      processIrq <= !((nmiReg && (irqReg || I)) || opcInfo[`opcIRQ]);
    end
  end

  // calcNextOpcode: process(clk, di, reset, processIrq)
  assign myNextOpcode = reset ? 8'h4C :
                        processIrq ? 8'h00 :
                        din;

  assign nextOpcode = myNextOpcode;

  assign nextOpcInfo = opcodeInfoTable[nextOpcode];
  always @(posedge clk)
  begin
    nextOpcInfoReg <= nextOpcInfo;
  end

  // Read bits and flags from opcodeInfoTable and store in opcInfo.
  // This info is used to control the execution of the opcode.
  // calcOpcInfo: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      if (reset || (theCpuCycle == opcodeFetch)) begin
        opcInfo <= nextOpcInfo;
        if (pipelineOpcode) begin
          opcInfo <= nextOpcInfoReg;
        end
      end
    end
  end

  // calcTheOpcode:  process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      if (theCpuCycle == opcodeFetch) begin
        irqActive <= 1'b0;
        if (processIrq) begin
          irqActive <= 1'b1;
        end
        // Fetch opcode
        theOpcode <= nextOpcode;
      end
    end
  end

  // -----------------------------------------------------------------------
  // State machine
  // -----------------------------------------------------------------------
  // process(enable, theCpuCycle, opcInfo)
  always @(enable or theCpuCycle or opcInfo)
  begin
    updateRegisters = 1'b0;
    if (enable) begin
      if (opcInfo[`opcRti]) begin
        if (theCpuCycle == cycleRead) begin
          updateRegisters = 1'b1;
        end
      end else if (theCpuCycle == opcodeFetch) begin
        updateRegisters = 1'b1;
      end
    end
  end

  assign debugOpcode = theOpcode;

  // process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      theCpuCycle <= nextCpuCycle;
    end
    if (reset) begin
      theCpuCycle <= cycle2;
    end
  end

  // Determine the next cpu cycle. After the last cycle we always
  // go to opcodeFetch to get the next opcode.
  // calcNextCpuCycle: process(theCpuCycle, opcInfo, theOpcode, indexOut, T, N, V, C, Z)
  always @(theCpuCycle or opcInfo or theOpcode or indexOut or T or N or V or C or Z)
  begin
    nextCpuCycle = opcodeFetch;

    case (theCpuCycle)
      opcodeFetch : begin
        nextCpuCycle = cycle2;
      end
      cycle2 : begin
        if (opcInfo[`opcBranch]) begin
          if ( ((N == theOpcode[5]) && (theOpcode[7:6] == 2'b00))
            || ((V == theOpcode[5]) && (theOpcode[7:6] == 2'b01))
            || ((C == theOpcode[5]) && (theOpcode[7:6] == 2'b10))
            || ((Z == theOpcode[5]) && (theOpcode[7:6] == 2'b11)) ) begin
            // Branch condition is true
            nextCpuCycle = cycleBranchTaken;
          end
        end else if (opcInfo[`opcStackUp]) begin
          nextCpuCycle = cycleStack1;
        end else if (opcInfo[`opcStackAddr] && opcInfo[`opcStackData]) begin
          nextCpuCycle = cycleStack2;
        end else if (opcInfo[`opcStackAddr]) begin
          nextCpuCycle = cycleStack1;
        end else if (opcInfo[`opcStackData]) begin
          nextCpuCycle = cycleWrite;
        end else if (opcInfo[`opcAbsolute]) begin
          nextCpuCycle = cycle3;
        end else if (opcInfo[`opcIndirect]) begin
          if (opcInfo[`indexX]) begin
            nextCpuCycle = cyclePreIndirect;
          end else begin
            nextCpuCycle = cycleIndirect;
          end
        end else if (opcInfo[`opcZeroPage]) begin
          if (opcInfo[`opcWrite]) begin
            if (opcInfo[`indexX] || opcInfo[`indexY]) begin
              nextCpuCycle = cyclePreWrite;
            end else begin
              nextCpuCycle = cycleWrite;
            end
          end else begin
            if (opcInfo[`indexX] || opcInfo[`indexY]) begin
              nextCpuCycle = cyclePreRead;
            end else begin
              nextCpuCycle = cycleRead2;
            end
          end
        end else if (opcInfo[`opcJump]) begin
          nextCpuCycle = cycleJump;
        end
      end
      cycle3 : begin
        nextCpuCycle = cycleRead;
        if (opcInfo[`opcWrite]) begin
          if (opcInfo[`indexX] || opcInfo[`indexY]) begin
            nextCpuCycle = cyclePreWrite;
          end else begin
            nextCpuCycle = cycleWrite;
          end
        end
        if (opcInfo[`opcIndirect] && opcInfo[`indexX]) begin
          if (opcInfo[`opcWrite]) begin
            nextCpuCycle = cycleWrite;
          end else begin
            nextCpuCycle = cycleRead2;
          end
        end
      end
      cyclePreIndirect : begin
        nextCpuCycle = cycleIndirect;
      end
      cycleIndirect : begin
        nextCpuCycle = cycle3;
      end
      cycleBranchTaken : begin
        if (indexOut[8] != T[7]) begin
          // Page boundary crossing during branch.
          nextCpuCycle = cycleBranchPage;
        end
      end
      cyclePreRead : begin
        if (opcInfo[`opcZeroPage]) begin
          nextCpuCycle = cycleRead2;
        end
      end
      cycleRead : begin
        if (opcInfo[`opcJump]) begin
          nextCpuCycle = cycleJump;
        end else if (indexOut[8]) begin
          // Page boundary crossing while indexed addressing.
          nextCpuCycle = cycleRead2;
        end else if (opcInfo[`opcRmw]) begin
          nextCpuCycle = cycleRmw;
          if (opcInfo[`indexX] || opcInfo[`indexY]) begin
            // 6510 needs extra cycle for indexed addressing
            // combined with RMW indexing
            nextCpuCycle = cycleRead2;
          end
        end
      end
      cycleRead2 : begin
        if (opcInfo[`opcRmw]) begin
          nextCpuCycle = cycleRmw;
        end
      end
      cycleRmw : begin
         nextCpuCycle = cycleWrite;
      end
      cyclePreWrite : begin
        nextCpuCycle = cycleWrite;
      end
      cycleStack1 : begin
        nextCpuCycle = cycleRead;
        if (opcInfo[`opcStackAddr]) begin
          nextCpuCycle = cycleStack2;
        end
      end
      cycleStack2 : begin
        nextCpuCycle = cycleStack3;
        if (opcInfo[`opcRti]) begin
          nextCpuCycle = cycleRead;
        end
        if (!opcInfo[`opcStackData] && opcInfo[`opcStackUp]) begin
          nextCpuCycle = cycleJump;
        end
      end
      cycleStack3 : begin
        nextCpuCycle = cycleRead;
        if (!opcInfo[`opcStackData] || opcInfo[`opcStackUp]) begin
          nextCpuCycle = cycleJump;
        end else if (opcInfo[`opcStackAddr]) begin
          nextCpuCycle = cycleStack4;
        end
      end
      cycleStack4 : begin
        nextCpuCycle = cycleRead;
      end
      cycleJump : begin
        if (opcInfo[`opcIncrAfter]) begin
          // Insert extra cycle
          nextCpuCycle = cycleEnd;
        end
      end
      default : begin
      end
    endcase
  end

  // -----------------------------------------------------------------------
  // T register
  // -----------------------------------------------------------------------
  // calcT: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      case (theCpuCycle)
        cycle2 : begin
          T <= din;
        end
        cycleStack1, cycleStack2 : begin
          if (opcInfo[`opcStackUp]) begin
            // Read from stack
            T <= din;
          end
        end
        cycleIndirect, cycleRead, cycleRead2 : begin
          T <= din;
        end
        default : begin
        end
      endcase
    end
  end

  // -----------------------------------------------------------------------
  // A register
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateA]) begin
        A <= aluRegisterOut;
      end
    end
  end

  // -----------------------------------------------------------------------
  // X register
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateX]) begin
        X <= aluRegisterOut;
      end
    end
  end

  // -----------------------------------------------------------------------
  // Y register
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateY]) begin
        Y <= aluRegisterOut;
      end
    end
  end

  // -----------------------------------------------------------------------
  // C flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
  if (updateRegisters) begin
      if (opcInfo[`opcUpdateC]) begin
        C <= aluC;
      end
    end
  end

  // -----------------------------------------------------------------------
  // Z flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateZ]) begin
        Z <= aluZ;
      end
    end
  end

  // -----------------------------------------------------------------------
  // I flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateI]) begin
        I <= aluInput[2];
      end
    end
  end

  // -----------------------------------------------------------------------
  // D flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateD]) begin
        D <= aluInput[3];
      end
    end
  end

  // -----------------------------------------------------------------------
  // V flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateV]) begin
        V <= aluV;
      end
    end
    if (enable) begin
      if (soReg && !so_n) begin
        V <= 1'b1;
      end
      soReg <= so_n;
    end
  end


  // -----------------------------------------------------------------------
  // N flag
  // -----------------------------------------------------------------------
  always @(posedge clk)
  begin
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateN]) begin
        N <= aluN;
      end
    end
  end

  // -----------------------------------------------------------------------
  // Stack pointer
  // -----------------------------------------------------------------------
  always @(nextCpuCycle or opcInfo)
  begin
    if (opcInfo[`opcStackUp]) begin
      sIncDec = S + 1;
    end else begin
      sIncDec = S - 1;
    end

    updateFlag = 1'b0;

    case (nextCpuCycle)
      cycleStack1 : begin
        if (opcInfo[`opcStackUp] || opcInfo[`opcStackData]) begin
          updateFlag = 1'b1;
        end
      end
      cycleStack2, cycleStack3, cycleStack4 : begin
        updateFlag = 1'b1;
      end
      cycleRead : begin
        if (opcInfo[`opcRti]) begin
          updateFlag = 1'b1;
        end
      end
      cycleWrite : begin
        if (opcInfo[`opcStackData]) begin
          updateFlag = 1'b1;
        end
      end
      default : begin
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (enable) begin
      if (updateFlag) begin
        S <= sIncDec;
      end
    end
    if (updateRegisters) begin
      if (opcInfo[`opcUpdateS]) begin
        S <= aluRegisterOut;
      end
    end
  end

  // -----------------------------------------------------------------------
  // Data out
  // -----------------------------------------------------------------------
  // calcDo: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      doReg <= aluRmwOut;
      if (opcInfo[`opcInH]) begin
        // For illegal opcodes SHA, SHX, SHY, SHS
        doReg <= aluRmwOut & myAddrIncrH;
      end

      case (nextCpuCycle)
        cycleStack2 : begin
          if (opcInfo[`opcIRQ] && !irqActive) begin
            doReg <= myAddrIncr[15:8];
          end else begin
            doReg <= PC[15:8];
          end
        end
        cycleStack3 : begin
          doReg <= PC[7:0];
        end
        cycleRmw : begin
          doReg <= din; // Read-modify-write write old value first.
        end
        default : begin
        end
      endcase
    end
  end
  assign dout = doReg;

  // -----------------------------------------------------------------------
  // Write enable
  // -----------------------------------------------------------------------
  // calcWe: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      theWe <= 1'b0;
      case (nextCpuCycle)
        cycleStack1 : begin
          if (!opcInfo[`opcStackUp]
              && (!opcInfo[`opcStackAddr] || opcInfo[`opcStackData])) begin
             theWe <= 1'b1;
          end
        end
        cycleStack2, cycleStack3, cycleStack4 : begin
          if (!opcInfo[`opcStackUp]) begin
            theWe <= 1'b1;
          end
        end
        cycleRmw, cycleWrite : begin
          theWe <= 1'b1;
        end
        default : begin
        end
      endcase
    end
  end
  assign we = theWe;

  // -----------------------------------------------------------------------
  // Program counter
  // -----------------------------------------------------------------------
  // calcPC: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      case (theCpuCycle)
        opcodeFetch : begin
          PC <= myAddr;
        end
        cycle2 :  begin
          if (!irqActive) begin
            if (opcInfo[`opcSecondByte]) begin
              PC <= myAddrIncr;
             end else begin
              PC <= myAddr;
            end
          end
        end
        cycle3 : begin
          if (opcInfo[`opcAbsolute]) begin
            PC <= myAddrIncr;
          end
        end
        default: begin
        end
      endcase
    end
  end
  assign debugPc = PC;

  // -----------------------------------------------------------------------
  // Address generation
  // -----------------------------------------------------------------------
  // calcNextAddr: process(theCpuCycle, opcInfo, indexOut, T, reset)
  always @(theCpuCycle or opcInfo or indexOut or reset)
  begin
    nextAddr = nextAddrIncr;
    case (theCpuCycle)
      cycle2 : begin
        if (opcInfo[`opcStackAddr] || opcInfo[`opcStackData]) begin
          nextAddr = nextAddrStack;
        end else if (opcInfo[`opcAbsolute]) begin
          nextAddr = nextAddrIncr;
        end else if (opcInfo[`opcZeroPage]) begin
          nextAddr = nextAddrZeroPage;
        end else if (opcInfo[`opcIndirect]) begin
          nextAddr = nextAddrZeroPage;
        end else if (opcInfo[`opcSecondByte]) begin
          nextAddr = nextAddrIncr;
        end else begin
          nextAddr = nextAddrHold;
        end
      end
      cycle3 : begin
        if (opcInfo[`opcIndirect] && opcInfo[`indexX]) begin
          nextAddr = nextAddrAbs;
        end else begin
          nextAddr = nextAddrAbsIndexed;
        end
      end
      cyclePreIndirect : begin
        nextAddr = nextAddrZPIndexed;
      end
      cycleIndirect : begin
         nextAddr = nextAddrIncrL;
      end
      cycleBranchTaken : begin
        nextAddr = nextAddrRelative;
      end
      cycleBranchPage : begin
        if (!T[7]) begin
          nextAddr = nextAddrIncrH;
        end else begin
          nextAddr = nextAddrDecrH;
        end
      end
      cyclePreRead : begin
        nextAddr = nextAddrZPIndexed;
      end
      cycleRead : begin
        nextAddr = nextAddrPc;
        if (opcInfo[`opcJump]) begin
          // Emulate 6510 bug, jmp(xxFF) fetches from same page.
          // Replace with nextAddrIncr if emulating 65C02 or later cpu.
          nextAddr = nextAddrIncrL;
        end else if (indexOut[8]) begin
          nextAddr = nextAddrIncrH;
        end else if (opcInfo[`opcRmw]) begin
          nextAddr = nextAddrHold;
        end
      end
      cycleRead2 : begin
        nextAddr = nextAddrPc;
        if (opcInfo[`opcRmw]) begin
          nextAddr = nextAddrHold;
        end
      end
      cycleRmw : begin
        nextAddr = nextAddrHold;
      end
      cyclePreWrite : begin
        nextAddr = nextAddrHold;
        if (opcInfo[`opcZeroPage]) begin
          nextAddr = nextAddrZPIndexed;
        end else if (indexOut[8]) begin
          nextAddr = nextAddrIncrH;
        end
      end
      cycleWrite : begin
        nextAddr = nextAddrPc;
      end
      cycleStack1, cycleStack2 : begin
        nextAddr = nextAddrStack;
      end
      cycleStack3 : begin
        nextAddr = nextAddrStack;
        if (!opcInfo[`opcStackData]) begin
          nextAddr = nextAddrPc;
        end
      end
      cycleStack4 : begin
        nextAddr = nextAddrIrq;
      end
      cycleJump : begin
        nextAddr = nextAddrAbs;
      end
      default : begin
      end
    endcase
    if (reset) begin
      nextAddr = nextAddrReset;
    end
  end

  // indexAlu: process(opcInfo, myAddr, T, X, Y)
  always @(opcInfo or myAddr or T or X or Y)
  begin
    if (opcInfo[`indexX]) begin
      indexOut = {1'b0, T} + {1'b0, X};
    end else if (opcInfo[`indexY]) begin
      indexOut = {1'b0, T} + {1'b0, Y};
    end else if (opcInfo[`opcBranch]) begin
      indexOut = {1'b0, T} + {1'b0, myAddr[7:0]};
    end else begin
      indexOut = {1'b0, T};
    end
  end

  // calcAddr: process(clk)
  always @(posedge clk)
  begin
    if (enable) begin
      case (nextAddr)
        nextAddrIncr : begin
          myAddr <= myAddrIncr;
        end
        nextAddrIncrL : begin
          myAddr[7:0] <= myAddrIncr[7:0];
        end
        nextAddrIncrH : begin
          myAddr[15:8] <= myAddrIncrH;
        end
        nextAddrDecrH : begin
          myAddr[15:8] <= myAddrDecrH;
        end
        nextAddrPc : begin
          myAddr <= PC;
        end
        nextAddrIrq : begin
          myAddr <= 16'hFFFE;
          if (!nmiReg) begin
            myAddr <= 16'hFFFA;
          end
        end
        nextAddrReset : begin
          myAddr <= 16'hFFFC;
        end
        nextAddrAbs : begin
          myAddr <= {din, T};
        end
        nextAddrAbsIndexed : begin
         myAddr <= {din, indexOut[7:0]};
        end
        nextAddrZeroPage : begin
          myAddr <= {8'd0, din};
        end
        nextAddrZPIndexed : begin
          myAddr <= {8'd0, indexOut[7:0]};
        end
        nextAddrStack : begin
          myAddr <= {8'd1, S};
        end
        nextAddrRelative : begin
          myAddr[7:0] <= indexOut[7:0];
        end
        default : begin
        end
      endcase
    end
  end

  assign myAddrIncr = myAddr + 1'b1;
  assign myAddrIncrH = myAddr[15:8] + 1'b1;
  assign myAddrDecrH = myAddr[15:8] - 1'b1;

  assign addr = myAddr;

  assign debugA = A;
  assign debugX = X;
  assign debugY = Y;
  assign debugS = S;

endmodule
