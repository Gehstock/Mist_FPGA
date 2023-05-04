//
// sd_card.v
//
// This file implelents a sd card for the MIST board since on the board
// the SD card is connected to the ARM IO controller and the FPGA has no
// direct connection to the SD card. This file provides a SD card like
// interface to the IO controller easing porting of cores that expect
// a direct interface to the SD card.
//
// Copyright (c) 2014 Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// http://elm-chan.org/docs/mmc/mmc_e.html

module sd_card (
    input         clk_sys,
    // link to user_io for io controller
    output reg[31:0] sd_lba,
    output reg    sd_rd,
    output reg    sd_wr,
    input         sd_ack,
    input         sd_ack_conf,
    output        sd_conf,
    output        sd_sdhc,

    input         img_mounted,
    input  [63:0] img_size,

    output reg    sd_busy = 0,
    // data coming in from io controller
    input   [7:0] sd_buff_dout,
    input         sd_buff_wr,

    // data going out to io controller
    output  [7:0] sd_buff_din,

    input   [8:0] sd_buff_addr,

    // configuration input
    // in case of a VHD file, this will determine the SD Card type returned to the SPI master
    // in case of a pass-through, the firmware will display a warning if SDHC is not allowed,
    // but the card inserted is SDHC
    input         allow_sdhc,

    input         sd_cs,
    input         sd_sck,
    input         sd_sdi,
    output reg    sd_sdo
);

wire [31:0] OCR = { 1'b1, sdhc, 6'h0, 9'h1f, 15'h0 };  // bit31 = finished powerup
                                                       // bit30 = 1 -> high capaciry card (sdhc)
                                                       // 15-23 supported voltage range
wire [7:0] READ_DATA_TOKEN = 8'hfe;

// number of bytes to wait after a command before sending the reply
localparam NCR=4;

localparam RD_STATE_IDLE       = 3'd0;
localparam RD_STATE_WAIT_BUSY  = 3'd1;
localparam RD_STATE_WAIT_IO    = 3'd2;
localparam RD_STATE_SEND_TOKEN = 3'd3;
localparam RD_STATE_SEND_DATA  = 3'd4;
localparam RD_STATE_DELAY      = 3'd5;
reg [2:0] read_state = RD_STATE_IDLE;

localparam WR_STATE_IDLE       = 3'd0;
localparam WR_STATE_EXP_DTOKEN = 3'd1;
localparam WR_STATE_RECV_DATA  = 3'd2;
localparam WR_STATE_RECV_CRC0  = 3'd3;
localparam WR_STATE_RECV_CRC1  = 3'd4;
localparam WR_STATE_SEND_DRESP = 3'd5;
localparam WR_STATE_WRITE      = 3'd6;
localparam WR_STATE_BUSY       = 3'd7;
reg [2:0] write_state = WR_STATE_IDLE;

reg card_is_reset = 1'b0;    // flag that card has received a reset command
reg [6:0] sbuf;
reg cmd55;
reg terminate_cmd = 1'b0;
reg [7:0] cmd = 8'h00;
reg [2:0] bit_cnt = 3'd0;    // counts bits 0-7 0-7 ...
reg [3:0] byte_cnt= 4'd15;   // counts bytes
reg [4:0] delay_cnt;
reg       wr_first;

reg [39:0] args;

reg [7:0] reply;
reg [7:0] reply0, reply1, reply2, reply3;
reg [3:0] reply_len;

// ------------------------- SECTOR BUFFER -----------------------

// the buffer itself. Can hold two sectors
reg  [9:0] buffer_ptr;
wire [7:0] buffer_dout;
reg  [7:0] buffer_din;
reg        buffer_write_strobe;
reg        sd_buff_sel;

sd_card_dpram #(8, 10) buffer_dpram
(
    .clock_a      (clk_sys),
    .address_a    ({sd_buff_sel, sd_buff_addr}),
    .data_a       (sd_buff_dout),
    .wren_a       (sd_buff_wr & sd_ack & read_state != RD_STATE_IDLE),
    .q_a          (sd_buff_din),

    .clock_b      (clk_sys),
    .address_b    (buffer_ptr),
    .data_b       (buffer_din),
    .wren_b       (buffer_write_strobe),
    .q_b          (buffer_dout)
);

wire [7:0] WRITE_DATA_RESPONSE = 8'h05;

// ------------------------- CSD/CID BUFFER ----------------------
reg  [7:0] conf;
assign     sd_conf = sd_configuring;

reg        sd_configuring = 1;
reg  [4:0] conf_buff_ptr;
reg  [7:0] conf_byte_orig;
reg[255:0] csdcid;

reg        vhd = 0;
reg [40:0] vhd_size;

// conf[0]==1 -> io controller is using an sdhc card
wire sd_has_sdhc = conf[0];
assign sd_sdhc = (allow_sdhc & sd_has_sdhc) | vhd; // report to user_io
wire sdhc = allow_sdhc & (sd_has_sdhc | vhd);      // used internally

always @(posedge clk_sys) begin
    reg old_mounted;

    if (sd_buff_wr & sd_ack_conf) begin
        if (sd_buff_addr == 32) begin
            conf <= sd_buff_dout;
            sd_configuring <= 0;
        end
        else csdcid[(31-sd_buff_addr) << 3 +:8] <= sd_buff_dout;
    end
    conf_byte_orig <= csdcid[(31-conf_buff_ptr) << 3 +:8];

    old_mounted <= img_mounted;
    if (~old_mounted & img_mounted) begin
        vhd <= |img_size;
        vhd_size <= img_size[40:0];
    end
end

// CSD V1.0 no. of blocks = c_size ** (c_size_mult + 2)
wire [127:0] csd_sd = {
    8'h00,                  // CSD_STRUCTURE + reserved
    8'h2d,                  // TAAC
    8'd0,                   // NSAC
    8'h32,                  // TRAN_SPEED
    12'h5b5,                // CCC
    4'h9,                   // READ_BL_LEN
    1'b1, 1'b0, 1'b0, 1'b0, // READ_BL_PARTIAL, WRITE_BLK_MISALIGN, READ_BLK_MISALIGN, DSR_IMP
    2'd0, vhd_size[29:18],  // reserved + C_SIZE
    3'b111,                 // VDD_R_CURR_MIN
    3'b110,                 // VDD_R_CURR_MAX
    3'b111,                 // VDD_W_CURR_MIN
    3'b110,                 // VDD_W_CURR_MAX
    3'd7,                   // C_SIZE_MULT
    1'b1,                   // ERASE_BLK_EN
    7'd127,                 // SECTOR_SIZE
    7'd0,                   // WP_GRP_SIZE
    1'b0,                   // WP_GRP_ENABLE,
    2'b00,                  // reserved,
    3'd5,                   // R2W_FACTOR,
    4'h9,                   // WRITE_BL_LEN,
    1'b0,                   // WRITE_BL_PARTIAL,
    5'd0,                   // reserved,
    8'd0,
    7'h67,                  // CRC (wrong, but usually not checked)
    1'b1 };

// CSD V2.0 size = (c_size + 1) * 512K
wire [127:0] csd_sdhc = {
    8'h40,                  // CSD_STRUCTURE + reserved
    8'h0e,                  // TAAC
    8'd0,                   // NSAC
    8'h32,                  // TRAN_SPEED
    12'h5b5,                // CCC
    4'h9,                   // READ_BL_LEN
    1'b0, 1'b0, 1'b0, 1'b0, // READ_BL_PARTIAL, WRITE_BLK_MISALIGN, READ_BLK_MISALIGN, DSR_IMP
    6'd0,                   // reserved
    vhd_size[40:19] - 1'd1, // C_SIZE
    1'b0,                   // reserved
    1'b1,                   // ERASE_BLK_EN
    7'd127,                 // SECTOR_SIZE
    7'd0,                   // WP_GRP_SIZE
    1'b0,                   // WP_GRP_ENABLE,
    2'b00,                  // reserved,
    3'd2,                   // R2W_FACTOR,
    4'h9,                   // WRITE_BL_LEN,
    1'b0,                   // WRITE_BL_PARTIAL,
    5'd0,                   // reserved,
    8'd0,
    7'h78,                  // CRC (wrong, but usually not checked)
    1'b1 };

wire [7:0] conf_byte = (!conf_buff_ptr[4] | !vhd) ? conf_byte_orig : // CID or CSD if not VHD
                                             sdhc ? csd_sdhc[(15-conf_buff_ptr[3:0]) << 3 +:8] :
                                                      csd_sd[(15-conf_buff_ptr[3:0]) << 3 +:8];

always@(posedge clk_sys) begin

    reg       old_sd_sck;
    reg [5:0] ack;

    ack <= {ack[4:0], sd_ack};
    if(ack[5:4] == 'b01) { sd_rd, sd_wr } <= 2'b00;
    if(ack[5:4] == 'b10) sd_busy <= 0;

    buffer_write_strobe <= 0;
    if (buffer_write_strobe) buffer_ptr <= buffer_ptr + 1'd1;

    old_sd_sck <= sd_sck;

    // advance transmitter state machine on falling sck edge, so data is valid on the 
    // rising edge
    // ----------------- spi transmitter --------------------
    if(sd_cs == 0 && old_sd_sck && ~sd_sck) begin

        sd_sdo <= 1'b1;    // default: send 1's (busy/wait)

        if(byte_cnt == 5+NCR) begin
            sd_sdo <= reply[~bit_cnt];

            if(bit_cnt == 7) begin
                // these three commands all have a reply_len of 0 and will thus
                // not send more than a single reply byte

                // CMD9: SEND_CSD
                // CMD10: SEND_CID
                if((cmd == 8'h49)||(cmd == 8'h4a))
                    read_state <= RD_STATE_SEND_TOKEN;      // jump directly to data transmission

                // CMD17: READ_SINGLE_BLOCK
                // CMD18: READ_MULTIPLE_BLOCK
                if((cmd == 8'h51 || cmd == 8'h52) && !terminate_cmd)
                    read_state <= RD_STATE_WAIT_BUSY; // start waiting for data from io controller

            end
        end
        else if((reply_len > 0) && (byte_cnt == 5+NCR+1))
            sd_sdo <= reply0[~bit_cnt];
        else if((reply_len > 1) && (byte_cnt == 5+NCR+2))
            sd_sdo <= reply1[~bit_cnt];
        else if((reply_len > 2) && (byte_cnt == 5+NCR+3))
            sd_sdo <= reply2[~bit_cnt];
        else if((reply_len > 3) && (byte_cnt == 5+NCR+4))
            sd_sdo <= reply3[~bit_cnt];

        // ---------- read state machine processing -------------

        case(read_state)
        RD_STATE_IDLE: ;
        // don't do anything

        // wait until the IO controller is free and issue a read
        RD_STATE_WAIT_BUSY:
        if (~sd_busy) begin
            sd_buff_sel <= 0;
            sd_lba <= sdhc?args[39:8]:{9'd0, args[39:17]};
            sd_rd <= 1;                      // trigger request to io controller
            sd_busy <= 1;
            read_state <= RD_STATE_WAIT_IO;
        end

        // waiting for io controller to return data
        RD_STATE_WAIT_IO: begin
            buffer_ptr <= 0;
            if(~sd_busy) begin
                if (terminate_cmd) begin
                    cmd <= 0;
                    read_state <= RD_STATE_IDLE;
                end else if (bit_cnt == 7)
                    read_state <= RD_STATE_SEND_TOKEN;
            end
        end

        // send data token
        RD_STATE_SEND_TOKEN: begin
            if(~sd_busy) begin
                sd_sdo <= READ_DATA_TOKEN[~bit_cnt];

                if(bit_cnt == 7) begin
                    read_state <= RD_STATE_SEND_DATA;   // next: send data
                    conf_buff_ptr <= (cmd == 8'h4a) ? 5'h0 : 5'h10;
                end
            end
        end

        // send data
        RD_STATE_SEND_DATA: begin
            if(cmd == 8'h51 || (cmd == 8'h52 && !terminate_cmd)) // CMD17: READ_SINGLE_BLOCK, CMD18: READ_MULTIPLE_BLOCK
                sd_sdo <= buffer_dout[~bit_cnt];
            else if(cmd == 8'h49 || cmd == 8'h4a)   // CMD9: SEND_CSD, CMD10: SEND CID
                sd_sdo <= conf_byte[~bit_cnt];

            if(bit_cnt == 7) begin

                // sent 512 sector data bytes?
                if((cmd == 8'h51) && &buffer_ptr[8:0])
                    read_state <= RD_STATE_IDLE;   // next: send crc. It's ignored so return to idle state

                if (cmd == 8'h52) begin
                    if (terminate_cmd) begin
                        read_state <= RD_STATE_IDLE;
                        cmd <= 0;
                    end else if (buffer_ptr[8:0] == 10) begin
                        // prefetch the next sector into the other buffer
                        sd_lba <= sd_lba + 1'd1;
                        sd_rd <= 1;
                        sd_busy <= 1;
                        sd_buff_sel <= !sd_buff_sel;
                    end else if (&buffer_ptr[8:0]) begin
                        delay_cnt <= 20;
                        read_state <= RD_STATE_DELAY;
                    end
                end

                // sent 16 cid/csd data bytes?
                if(((cmd == 8'h49)||(cmd == 8'h4a)) && conf_buff_ptr[3:0] == 4'h0f) // && (buffer_rptr == 16))
                    read_state <= RD_STATE_IDLE;   // return to idle state

                buffer_ptr <= buffer_ptr + 1'd1;
                conf_buff_ptr<= conf_buff_ptr+ 1'd1;
            end
        end

        RD_STATE_DELAY:
            if(bit_cnt == 7) begin
                if (terminate_cmd) begin
                    read_state <= RD_STATE_IDLE;
                    cmd <= 0;
                end else if (delay_cnt == 0) begin
                    read_state <= RD_STATE_SEND_TOKEN;
                end else begin
                    delay_cnt <= delay_cnt - 1'd1;
                end
            end

        endcase

        // ------------------ write support ----------------------
        // send write data response
        if(write_state == WR_STATE_SEND_DRESP) 
            sd_sdo <= WRITE_DATA_RESPONSE[~bit_cnt];

        // busy after write until the io controller sends ack
        if(write_state == WR_STATE_WRITE || write_state == WR_STATE_BUSY)
            sd_sdo <= 1'b0;
    end

    // spi receiver
    // cs is active low
    if(sd_cs == 1) begin
        bit_cnt <= 3'd0;
        terminate_cmd <= 0;
        cmd <= 0;
        read_state <= RD_STATE_IDLE;
        reply_len <= 0;
    end else if (~old_sd_sck & sd_sck) begin
        bit_cnt <= bit_cnt + 3'd1;

        // assemble byte
        if(bit_cnt != 7)
            sbuf[6:0] <= { sbuf[5:0], sd_sdi };
        else begin
            // finished reading one byte
            // byte counter runs against 15 byte boundary
            if(byte_cnt != 15)
                byte_cnt <= byte_cnt + 4'd1;

            // byte_cnt > 6 -> complete command received
            // first byte of valid command is 01xxxxxx
            // don't accept new commands (except STOP TRANSMISSION) once a write or read command has been accepted
            if((byte_cnt > (reply_len == 0 ? 5 : (5+NCR+reply_len))) && 
               (write_state == WR_STATE_IDLE) && 
               (read_state == RD_STATE_IDLE || (read_state != RD_STATE_IDLE && { sbuf, sd_sdi} == 8'h4c)) &&
               sbuf[6:5] == 2'b01)
            begin
                byte_cnt <= 4'd0;
                terminate_cmd <= 0;
                if ({ sbuf, sd_sdi } == 8'h4c) begin
                    terminate_cmd <= 1;
                end else
                    cmd <= { sbuf, sd_sdi};
            end

            // parse additional command bytes
            if(byte_cnt == 0) args[39:32] <= { sbuf, sd_sdi};
            if(byte_cnt == 1) args[31:24] <= { sbuf, sd_sdi};
            if(byte_cnt == 2) args[23:16] <= { sbuf, sd_sdi};
            if(byte_cnt == 3) args[15:8]  <= { sbuf, sd_sdi};
            if(byte_cnt == 4) args[7:0]   <= { sbuf, sd_sdi};

            // last byte received, evaluate
            if(byte_cnt == 5) begin

                // default:
                reply <= 8'h04;     // illegal command
                reply_len <= 4'd0;  // no extra reply bytes
                cmd55 <= 0;

                // CMD0: GO_IDLE_STATE
                if(cmd == 8'h40) begin
                    card_is_reset <= 1'b1;
                    reply <= 8'h01;    // ok, busy
                end

                // every other command is only accepted after a reset
                else if(card_is_reset) begin
                    // CMD12: STOP_TRANSMISSION
                    if (terminate_cmd)
                        reply <= 8'h00;    // ok
                    else case(cmd)
                    // CMD1: SEND_OP_COND
                    8'h41: reply <= 8'h00;    // ok, not busy

                    // CMD8: SEND_IF_COND (V2 only)
                    8'h48: begin
                        reply <= 8'h01;    // ok, busy
                        reply0 <= 8'h00;
                        reply1 <= 8'h00;
                        reply2 <= { 4'b0, args[19:16] };
                        reply3 <= args[15:8];
                        reply_len <= 4'd4;
                    end

                    // CMD9: SEND_CSD
                    8'h49: reply <= 8'h00;    // ok

                    // CMD10: SEND_CID
                    8'h4a: reply <= 8'h00;    // ok

                    // CMD13: SEND_STATUS
                    8'h4d: begin
                      reply <= 8'h00;    // ok
                      reply0 <=8'h00;
                      reply_len <= 4'd1;
                    end

                    // CMD16: SET_BLOCKLEN
                    8'h50:
                        // we only support a block size of 512
                        if(args[39:8] == 32'd512)
                            reply <= 8'h00;    // ok
                        else
                            reply <= 8'h40;    // parmeter error

                    // CMD17: READ_SINGLE_BLOCK
                    8'h51: reply <= 8'h00;    // ok

                    // CMD18: READ_MULTIPLE_BLOCK
                    8'h52: reply <= 8'h00;    // ok

                    // CMD24: WRITE_BLOCK
                    // CMD25: WRITE_MULTIPLE_BLOCKS
                    8'h58, 8'h59: begin
                        reply <= 8'h00;    // ok
                        buffer_ptr <= 0;
                        wr_first <= 1;
                        write_state <= WR_STATE_EXP_DTOKEN;  // expect data token
                    end

                    // ACMD41: APP_SEND_OP_COND
                    8'h69: if(cmd55) begin
                        reply <= 8'h00;    // ok, not busy
                    end

                    // CMD55: APP_COND
                    8'h77: begin
                        reply <= 8'h01;    // ok, busy
                        cmd55 <= 1;
                    end

                    // CMD58: READ_OCR
                    8'h7a: begin
                        reply <= 8'h00;    // ok

                        reply0 <= OCR[31:24];   // bit 30 = 1 -> high capacity card 
                        reply1 <= OCR[23:16];
                        reply2 <= OCR[15:8];
                        reply3 <= OCR[7:0];
                        reply_len <= 4'd4;
                    end

                    // CMD59: CRC_ON_OFF
                    8'h7b: reply <= 0;     // ok

                    endcase
                end
            end
        end
    end

    // ---------- handle write -----------
    case(write_state)
        // don't do anything in idle state
        WR_STATE_IDLE: ;

        // waiting for data token
        WR_STATE_EXP_DTOKEN:
        if (sd_cs) write_state <= WR_STATE_IDLE;
        else if (~old_sd_sck && sd_sck && bit_cnt == 7) begin
            if({ sbuf, sd_sdi} == 8'hfd && cmd == 8'h59)
                // stop multiple write (and wait until the last write finishes)
                write_state <= WR_STATE_BUSY;
            else
            if({ sbuf, sd_sdi} == ((cmd == 8'h59) ? 8'hfc : 8'hfe))
                write_state <= WR_STATE_RECV_DATA;
        end

        // transfer 512 bytes
        WR_STATE_RECV_DATA:
        if (sd_cs) write_state <= WR_STATE_IDLE;
        else if (~old_sd_sck && sd_sck && bit_cnt == 7) begin
            // push one byte into local buffer
            buffer_write_strobe <= 1'b1;
            buffer_din <= { sbuf, sd_sdi };

            // all bytes written?
            if(&buffer_ptr[8:0])
                write_state <= WR_STATE_RECV_CRC0;
        end

        // transfer 1st crc byte
        WR_STATE_RECV_CRC0:
        if (sd_cs) write_state <= WR_STATE_IDLE;
        else if (~old_sd_sck && sd_sck && bit_cnt == 7) write_state <= WR_STATE_RECV_CRC1;

        // transfer 2nd crc byte
        WR_STATE_RECV_CRC1:
        if (sd_cs) write_state <= WR_STATE_IDLE;
        else if (~old_sd_sck && sd_sck && bit_cnt == 7) write_state <= WR_STATE_SEND_DRESP;

        // send data response
        WR_STATE_SEND_DRESP:
        if (sd_cs) write_state <= WR_STATE_IDLE;
        else if (~old_sd_sck && sd_sck && bit_cnt == 7) write_state <= WR_STATE_WRITE;

        WR_STATE_WRITE:
        if (~sd_busy) begin
            if (wr_first) begin
                sd_buff_sel <= 0;
                sd_lba <= sdhc?args[39:8]:{9'd0, args[39:17]};
                wr_first <= 0;
            end else begin
                sd_buff_sel <= !sd_buff_sel;
                sd_lba <= sd_lba + 1'd1;
            end
            sd_wr <= 1;               // trigger write request to io controller
            sd_busy <= 1;

            if (sd_cs || cmd == 8'h58)
                write_state <= WR_STATE_BUSY;
            else
                write_state <= WR_STATE_EXP_DTOKEN; // multi-sector writes

        end

        WR_STATE_BUSY:
        if (~sd_busy) write_state <= WR_STATE_IDLE;

        default: ;
    endcase
end

endmodule

module sd_card_dpram #(parameter DATAWIDTH=8, ADDRWIDTH=9)
(
    input                   clock_a,
    input   [ADDRWIDTH-1:0] address_a,
    input   [DATAWIDTH-1:0] data_a,
    input                   wren_a,
    output reg [DATAWIDTH-1:0] q_a,

    input                   clock_b,
    input   [ADDRWIDTH-1:0] address_b,
    input   [DATAWIDTH-1:0] data_b,
    input                   wren_b,
    output reg [DATAWIDTH-1:0] q_b
);

reg [DATAWIDTH-1:0] ram[0:(1<<ADDRWIDTH)-1];

always @(posedge clock_a) begin
    q_a <= ram[address_a];
    if(wren_a) begin
        q_a <= data_a;
        ram[address_a] <= data_a;
    end
end

always @(posedge clock_b) begin
    q_b <= ram[address_b];
    if(wren_b) begin
        q_b <= data_b;
        ram[address_b] <= data_b;
    end
end

endmodule
