//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

wire en_layer_a = ~status[64];
wire en_layer_b = ~status[65];
wire en_sprites = ~status[66];
wire en_layer_palette = ~status[67];
wire en_sprite_palette = ~status[68];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"M72;;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen2,[ARC1],[ARC2];",
	"-;",
	"DIP;",
	"-;",
	"O[64],Layer A,On,Off;",
	"O[65],Layer B,On,Off;",
	"O[66],Sprites,On,Off;",
	"O[67],Layer Palette,On,Off;",
	"O[68],Sprite Palette,On,Off;",
	"O[69],Sprite Freeze,Off,On;",
	"-;",
	"T[0],Reset;",
	"R[0],Reset and close OSD;",
	"DEFMRA,/_Arcade/r-type.mra;",
	"V,v",`BUILD_DATE 
};

wire        forced_scandoubler;
wire  [1:0] buttons;
wire [128:0] status;
wire [10:0] ps2_key;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req = 0;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din = 0;
wire        ioctl_wait;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;
wire        direct_video;

wire clk_sys = CLK_32M;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.ps2_key(ps2_key)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire CLK_32M;
wire CLK_96M;
wire pll_locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(CLK_96M),
	.outclk_1(CLK_32M),
	.locked(pll_locked)
);

wire reset = RESET | status[0] | buttons[1] | ioctl_download;

///////////////////////////////////////////////////////////////////////
// SDRAM
///////////////////////////////////////////////////////////////////////
wire [1:0] sdr_wr_sel1, sdr_wr_sel2;
wire [15:0] sdr_din1, sdr_din2, sdr_dout1, sdr_dout2;
wire [24:1] sdr_addr1, sdr_addr2;
wire sdr_req1, sdr_req2, sdr_ack1, sdr_ack2;

sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(CLK_96M),

	.addr0(ioctl_addr[24:1]),
	.din0({ioctl_dout[7:0],ioctl_dout[7:0]}),
	.dout0(),
	.wrl0(~ioctl_addr[0]),
	.wrh0(ioctl_addr[0]),
	.req0(ioctl_rom_wr),
	.ack0(ioctl_rom_wrack),

	.addr1(sdr_addr1),
	.din1(sdr_din1),
	.dout1(sdr_dout1),
	.wrl1(sdr_wr_sel1[0]),
	.wrh1(sdr_wr_sel1[1]),
	.req1(sdr_req1),
	.ack1(sdr_ack1),

	.addr2(sdr_addr2),
	.din2(sdr_din2),
	.dout2(sdr_dout2),
	.wrl2(sdr_wr_sel2[0]),
	.wrh2(sdr_wr_sel2[1]),
	.req2(sdr_req2),
	.ack2(sdr_ack2)
);

reg  ioctl_rom_wr = 0;
wire ioctl_rom_wrack;
always @(posedge clk_sys) begin
	reg old_reset;
	old_reset <= reset;

	if(~old_reset && reset) ioctl_wait <= 0;

	if (ioctl_wr && !ioctl_index) begin
		ioctl_wait <= 1;
		ioctl_rom_wr <= ~ioctl_rom_wr;
	end else if(ioctl_wait && (ioctl_rom_wr == ioctl_rom_wrack)) begin
		ioctl_wait <= 0;
	end
end





///////////////////         Keyboard           //////////////////
reg btn_up       = 0;
reg btn_down     = 0;
reg btn_left     = 0;
reg btn_right    = 0;
reg btn_a        = 0;
reg btn_b        = 0;
reg btn_coin1    = 0;
reg btn_coin2    = 0;
reg btn_1p_start = 0;
reg btn_2p_start = 0;
reg btn_pause    = 0;
reg btn_service  = 0;

wire pressed = ps2_key[9];
wire [7:0] code = ps2_key[7:0];
always @(posedge CLK_32M) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h16: btn_1p_start <= pressed; // 1
			'h1E: btn_2p_start <= pressed; // 2
			'h2E: btn_coin1    <= pressed; // 5
			'h36: btn_coin2    <= pressed; // 6
			'h46: btn_service  <= pressed; // 9
			'h4D: btn_pause    <= pressed; // P

			'h75: btn_up      <= pressed; // up
			'h72: btn_down    <= pressed; // down
			'h6B: btn_left    <= pressed; // left
			'h74: btn_right   <= pressed; // right
			'h14: btn_a       <= pressed; // ctrl						
			'h11: btn_b       <= pressed; // alt						
		endcase
	end
end

// DIP SWITCHES
reg [7:0] dip_sw[8];	// Active-LOW
always @(posedge CLK_32M) begin
	if(ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3])
		dip_sw[ioctl_addr[2:0]] <= ioctl_dout;
end


//////////////////  Arcade Buttons/Interfaces   ///////////////////////////

//Player 1
wire m_up1      = btn_up      | joystick_0[3];
wire m_down1    = btn_down    | joystick_0[2];
wire m_left1    = btn_left    | joystick_0[1];
wire m_right1   = btn_right   | joystick_0[0];
wire m_btna1    = btn_a       | joystick_0[4];
wire m_btnb1    = btn_b       | joystick_0[5];
wire m_btnx1    = joystick_0[6];
wire m_btny1    = joystick_0[7];

//Player 2
wire m_up2      = btn_up      | joystick_1[3];
wire m_down2    = btn_down    | joystick_1[2];
wire m_left2    = btn_left    | joystick_1[1];
wire m_right2   = btn_right   | joystick_1[0];
wire m_btna2    = btn_a       | joystick_1[4];
wire m_btnb2    = btn_b       | joystick_1[5];
wire m_btnx2    = joystick_1[6];
wire m_btny2    = joystick_1[7];

//Start/coin
wire m_start1   = btn_1p_start | joy[6];
wire m_start2   = btn_2p_start | joy[8];
wire m_coin1    = btn_coin1    | joy[7];
wire m_coin2    = btn_coin2;
wire m_pause    = btn_pause    | joy[9];

//////////////////////////////////////////////////////////////////

wire VGA_HB, VGA_VB;

m72 m72(
	.CLK_32M(CLK_32M),
	.CLK_96M(CLK_96M),
	.ce_pix(CE_PIXEL),
	.reset_n(~reset),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_HB(VGA_HB),
	.VGA_VB(VGA_VB),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.AUDIO_L(AUDIO_L),
	.AUDIO_R(AUDIO_R),

	.coin({~m_coin2, ~m_coin1}),
	
	.start_buttons({~m_start2, ~m_start1}),
	
	.p1_joystick({~m_up1, ~m_down1, ~m_left1, ~m_right1}),
	.p2_joystick({~m_up2, ~m_down2, ~m_left2, ~m_right2}),
	.p1_buttons({~m_btna1, ~m_btnb1, ~m_btnx1, ~m_btny1}),
	.p2_buttons({~m_btna2, ~m_btnb2, ~m_btnx2, ~m_btny2}),
	
//	.btn_service(~btn_service),

	.dip_sw({~dip_sw[1], ~dip_sw[0]}),

	.sys_clk(CLK_32M),
	.ioctl_wr(ioctl_wr && !ioctl_index),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.sdr_wr_sel1(sdr_wr_sel1),
	.sdr_din1(sdr_din1),
	.sdr_dout1(sdr_dout1),
	.sdr_addr1(sdr_addr1),
	.sdr_req1(sdr_req1),
	.sdr_ack1(sdr_ack1),

	.sdr_wr_sel2(sdr_wr_sel2),
	.sdr_din2(sdr_din2),
	.sdr_dout2(sdr_dout2),
	.sdr_addr2(sdr_addr2),
	.sdr_req2(sdr_req2),
	.sdr_ack2(sdr_ack2),

	.en_layer_a(en_layer_a),
	.en_layer_b(en_layer_b),
	.en_sprites(en_sprites),
	.en_layer_palette(en_layer_palette),
	.en_sprite_palette(en_sprite_palette),

	.sprite_freeze(status[69])
);

assign CLK_VIDEO = CLK_32M;

assign VGA_DE = ~(VGA_HB | VGA_VB);

reg  [26:0] act_cnt;
always @(posedge CLK_32M) act_cnt <= act_cnt + 1'd1; 
assign LED_USER    = act_cnt[26]  ? act_cnt[25:18]  > act_cnt[7:0]  : act_cnt[25:18]  <= act_cnt[7:0];

endmodule
