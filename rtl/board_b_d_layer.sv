module board_b_d_layer(
    input sys_clk,
    input ioctl_wr,

	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,
    input [3:0] gfx_cs,

    input CLK_32M,
    input CE_PIX,

    input [15:0] DIN,
    output [15:0] DOUT,
    input [19:0] A,
    input [1:0]  BYTE_SEL,
    input RD,
    input WR,

    input [7:0] IO_A,
	input [7:0] IO_DIN,

    input VSCK,
    input HSCK,
    input NL,

    input [8:0] VE,
    input [8:0] HE,

    output [3:0] BIT,
    output [3:0] COL,
    output CP15,
    output CP8,

    input enabled
);

assign DOUT = { dout_h, dout_l };

wire [7:0] dout_h, dout_l;

dpramv #(.widthad_a(13)) ram_l
(
	.clock_a(CLK_32M),
	.address_a(A[13:1]),
	.q_a(dout_l),
	.wren_a(WR & BYTE_SEL[0]),
	.data_a(DIN[7:0]),

	.clock_b(CLK_32M),
	.address_b({SV[8:3], SH[8:2]}),
	.data_b(),
	.wren_b(0),
	.q_b(ram_l_dout)
);

dpramv #(.widthad_a(13)) ram_h
(
	.clock_a(CLK_32M),
	.address_a(A[13:1]),
	.q_a(dout_h),
	.wren_a(WR & BYTE_SEL[1]),
	.data_a(DIN[15:8]),

	.clock_b(CLK_32M),
	.address_b({SV[8:3], SH[8:2]}),
	.data_b(),
	.wren_b(0),
	.q_b(ram_h_dout)
);

wire [31:0] dout;

eprom_32_32 rom(
	.clk(CLK_32M),
	.addr({COD[11:0], RV[2:0]}),
	.data(dout),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[16:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(|gfx_cs)
);

wire [3:0] BITF, BITR;

kna6034201 kna6034201(
    .clock(CLK_32M),
    .CE_PIXEL(CE_PIX),
    .LOAD(SH[2:0] == 3'b111),
    .byte_1(enabled ? dout[7:0] : 8'h00),
    .byte_2(enabled ? dout[15:8] : 8'h00),
    .byte_3(enabled ? dout[23:16] : 8'h00),
    .byte_4(enabled ? dout[31:24] : 8'h00),
    .bit_1(BITF[0]),
    .bit_2(BITF[1]),
    .bit_3(BITF[2]),
    .bit_4(BITF[3]),
    .bit_1r(BITR[0]),
    .bit_2r(BITR[1]),
    .bit_3r(BITR[2]),
    .bit_4r(BITR[3])
);

wire [8:0] SV = VE + adj_v;
wire [8:0] SH = HE + adj_h;

reg [8:0] adj_v;
reg [8:0] adj_h;

reg HREV, VREV;
reg [13:0] COD;
reg [7:0] row_data1, row_data;

wire [2:0] RV = SV[2:0] ^ {3{VREV}};

wire [7:0] ram_h_dout, ram_l_dout;

assign COL = row_data[3:0];
assign CP15 = row_data[7];
assign CP8 = row_data[6];

assign BIT = HREV ? BITR : BITF;

always @(posedge CLK_32M) begin // TODO need to handle IO?
    if (VSCK & ~IO_A[0]) adj_v[7:0] <= IO_DIN[7:0];
    if (HSCK & ~IO_A[0]) adj_h[7:0] <= IO_DIN[7:0];
    if (VSCK & IO_A[0])  adj_v[8]   <= IO_DIN[0];
    if (HSCK & IO_A[0])  adj_h[8]   <= IO_DIN[0];
end

always @(posedge CLK_32M) begin
    if (CE_PIX) begin
        if (SH[2:0] == 2'b011) { VREV, HREV, COD } <= { ram_h_dout, ram_l_dout };
        if (SH[2:0] == 3'b101) row_data1 <= ram_l_dout;
        if (SH[2:0] == 3'b111) row_data <= row_data1;
    end
end

// TODO SLDA ?


endmodule