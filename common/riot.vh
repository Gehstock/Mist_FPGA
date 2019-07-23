/*  Atari on an FPGA
Masters of Engineering Project
Cornell University, 2007
Daniel Beer
    RIOT.h
Header file that contains useful definitions for the RIOT module.
*/
`define READ_RAM                        7'b01xxxxx
`define WRITE_RAM                       7'b00xxxxx
`define READ_DRA                        7'b11xx000
`define WRITE_DRA                       7'b10xx000
`define READ_DDRA                       7'b11xx001
`define WRITE_DDRA                      7'b10xx001
`define READ_DRB                        7'b11xx010
`define WRITE_DRB                       7'b10xx010
`define READ_DDRB                       7'b11xx011
`define WRITE_DDRB                      7'b10xx011
`define WRITE_TIMER                     7'b101x1xx
`define READ_TIMER                      7'b11xx1x0
`define READ_INT_FLAG                   7'b11xx1x1
`define WRITE_EDGE_DETECT               7'b100x1x0
`define NOP                             7'b0100000
`define TM_1    2'b00
`define TM_8    2'b01
`define TM_64   2'b10
`define TM_1024 2'b11