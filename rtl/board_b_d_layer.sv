module board_b_d_layer(
    input sys_clk,
    input ioctl_wr,

	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,
    input [3:0] gfx_cs,

    input CLK_32M,
    input DCLK,

    input [15:0] DIN,
    output [15:0] DOUT,
    input [19:1] A,
    input [1:0]  BYTE_SEL,
    input RD,
    input WR,

    input VSCK,
    input HSCK,
    input NL,

    input [8:0] VE,
    input [9:0] HE,

    output [3:0] BIT,
    output [3:0] COL
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

	.clock_b(DCLK),
	.address_b({SV[8:3], SH[8:3], SH[1]}),
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

	.clock_b(DCLK),
	.address_b({SV[8:3], SH[8:3], SH[1]}),
	.data_b(),
	.wren_b(0),
	.q_b(ram_h_dout)
);

wire [7:0] dout_1, dout_2, dout_3, dout_4;

eprom_32 rom_1(
	.clk(DCLK), // faster clock
	.addr({COD[11:0], RV[2:0]}),
	.data(dout_1),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(gfx_cs[0])
);

eprom_32 rom_2(
	.clk(DCLK), // faster clock
	.addr({COD[11:0], RV[2:0]}),
	.data(dout_2),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(gfx_cs[1])
);

eprom_32 rom_3(
	.clk(DCLK), // faster clock
	.addr({COD[11:0], RV[2:0]}),
	.data(dout_3),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(gfx_cs[2])
);

eprom_32 rom_4(
	.clk(DCLK), // faster clock
	.addr({COD[11:0], RV[2:0]}),
	.data(dout_4),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(gfx_cs[3])
);

kna6034201 kna6034201(
    .clock(DCLK),
    .load(SH[2:0] == 3'b000),
    .byte_1(dout_1),
    .byte_2(dout_2),
    .byte_3(dout_3),
    .byte_4(dout_4),
    .bit_1(BIT[0]),
    .bit_2(BIT[1]),
    .bit_3(BIT[2]),
    .bit_4(BIT[3]),
    .bit_1r(),
    .bit_2r(),
    .bit_3r(),
    .bit_4r()
);

reg [8:0] SV;
reg [9:0] SH;

reg [8:0] adj_v;
reg [8:0] adj_h;

reg HREV, VREV;
reg [13:0] COD;
reg [7:0] row_data1, row_data;

wire [2:0] RV = SV[2:0] ^ {3{VREV}};

wire [7:0] ram_h_dout, ram_l_dout;

assign COL = row_data[3:0];

always @(posedge CLK_32M) begin // might need a faster clock
    if (VSCK & BYTE_SEL[0]) adj_v <= DIN[8:0];
    if (HSCK & BYTE_SEL[0]) adj_h <= DIN[8:0];
end

always @(posedge DCLK) begin
    reg [8:0] sh;

    //SH <= { HE[9], HE[7:0] } + adj_h;
    SV <= VE + adj_v;
    SH <= ( HE + adj_h ); // TODO ^ { 5'b0000, {3{NL}} };

    if (SH[2:0] == 3'b001) { HREV, VREV, COD } <= { ram_h_dout, ram_l_dout };
    //if (SH[2:1] == 2'b00) COD <= { SV[:3], SH[9:3] };

    if (SH[2:0] == 3'b100) row_data1 <= ram_l_dout;
    if (SH[2:0] == 3'b000) row_data <= row_data1;
end

// TODO SLDA ?


endmodule