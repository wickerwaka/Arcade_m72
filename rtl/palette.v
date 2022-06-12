`timescale 1 ns / 1 ns

module palette (
	input dclk,
	input reset_n,
	
	input ah,
	input al,
	input [7:0] cpu_addr,
	inout [4:0] cpu_data,
	
	input pal_cs_n,
	input pal_wr_n,
	input pal_rd_n,
	
	input [7:0] ca,
	input [7:0] cb,
	
	input s,
	input e1_n,
	input e2_n,

	output reg [4:0] r_out,
	output reg [4:0] g_out,
	output reg [4:0] b_out	
);

reg [4:0] pal_ram [0:767];	// 0x000 to 0x2FF. 768 entries total.


// BYTE addresses for palette RAM entries...
//
// 0x000-0x0FF = Red.
// 0x100-0x1FF = Green.
// 0x200-0x2FF = Blue.
//
//
// On R-Type, the CPU address bits are mapped to the Palette chip like this...
//
// { ah, al, offset } = A11, A10, A[8:1].
//
// CPU address bit A1 is connected to Palette address bit A0,
// so from the CPU's point-of-view, the lower 5 bits of each 16-bit WORD contain a palette entry. 
//
// CPU address bit A9 is also skipped, so the CPU sees the above RGB ranges get mapped like this.
// (BYTE addressing).
//
// 0x000-1FF = Red.
// 0x200-3FF = Red (mirror).
//
// 0x400-5FF = Green.
// 0x600-7FF = Green (mirror).
//
// 0x800-9FF = Blue.
// 0xA00-BFF = Blue (mirror).
//
//
//

assign cpu_data = (!pal_cs_n & !pal_rd_n) ? pal_ram[cpu_addr] : 5'bzzzzz;

always @(posedge dclk or negedge reset_n)
if (!reset_n) begin

end
else begin
	if (!pal_cs_n & !pal_wr_n) pal_ram[ {ah,al,cpu_addr] <= cpu_data;
	
	if (!s) begin	// Not confirmed if the S bit works like this yet, but probably?
		r_out <= pal_ram[ {2'b00, ca} ];
		g_out <= pal_ram[ {2'b01, ca} ];
		b_out <= pal_ram[ {2'b10, ca} ];
	end
	else begin
		r_out <= pal_ram[ {2'b00, cb} ];
		g_out <= pal_ram[ {2'b01, cb} ];
		b_out <= pal_ram[ {2'b10, cb} ];
	end
end


endmodule
