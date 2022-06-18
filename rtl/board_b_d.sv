module board_b_d (
    input sys_clk,
    input ioctl_wr,
	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,

    input [3:0] gfx_a_cs,
    input [3:0] gfx_b_cs,

    input CLK_32M,
    input DCLK,

    output [15:0] DOUT,
    output DOUT_VALID,

    input [15:0] DIN,
    input [19:1] A,
    input [1:0]  BYTE_SEL,
    input MRD,
    input MWR,
    input IORD,
    input IOWR,
    input CHARA,
    input CHARA_P,
    input NL,

    input [8:0] VE,
    input [9:0] HE,

    output [7:0] RED,
    output [7:0] GREEN,
    output [7:0] BLUE
);

// M72-B-D 1/8
// Didn't implement WAIT signal
wire WRA = MWR & CHARA & ~A[15];
wire WRB = MWR & CHARA & A[15];
wire RDA = MRD & CHARA & ~A[15];
wire RDB = MRD & CHARA & A[15];

wire VSCKA = IOWR & (A[7:6] == 2'b10) & (A[3:1] == 3'b000);
wire HSCKA = IOWR & (A[7:6] == 2'b10) & (A[3:1] == 3'b001);
wire VSCKB = IOWR & (A[7:6] == 2'b10) & (A[3:1] == 3'b010);
wire HSCKB = IOWR & (A[7:6] == 2'b10) & (A[3:1] == 3'b011);

wire [3:0] BITA;
wire [3:0] BITB;
wire [3:0] COLA;
wire [3:0] COLB;

wire [15:0] DOUT_A, DOUT_B;

assign DOUT = pal_dout_valid ? pal_dout : RDA ? DOUT_A : DOUT_B;
assign DOUT_VALID = RDA | RDB | pal_dout_valid;

board_b_d_layer layer_a(
    .sys_clk(sys_clk),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),

    .gfx_cs(gfx_a_cs),

    .CLK_32M(CLK_32M),
    .DCLK(DCLK),

    .DOUT(DOUT_A),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDA),
    .WR(WRA),

    .VSCK(VSCKA),
    .HSCK(HSCKA),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITA),
    .COL(COLA)
);

board_b_d_layer layer_b(
    .sys_clk(sys_clk),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),

    .gfx_cs(gfx_b_cs),

    .CLK_32M(CLK_32M),
    .DCLK(DCLK),

    .DOUT(DOUT_B),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDB),
    .WR(WRB),

    .VSCK(VSCKB),
    .HSCK(HSCKB),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITB),
    .COL(COLB)
);

wire [4:0] r_out, g_out, b_out;
wire [15:0] pal_dout;
wire pal_dout_valid;

wire S = BITA != 4'b0000;

kna91h014 kna91h014(
    .DCLK(DCLK),
    .CLK_32M(CLK_32M),

    .G(CHARA_P),
    .SELECT(S),
    .CA({COLA, BITA}),
    .CB({COLB, BITB}),

    .E1_N(), // TODO
    .E2_N(), // TODO
	
	.MWR(MWR),
	.MRD(MRD),

	.DIN(DIN),
    .DOUT(pal_dout),
    .DOUT_VALID(pal_dout_valid),
    .A(A),

    .RED(r_out),
    .GRN(g_out),
    .BLU(b_out)
);

assign RED = { r_out, r_out[4:2] };
assign GREEN = { g_out, g_out[4:2] };
assign BLUE = { b_out, b_out[4:2] };

//assign GREEN = { BITB, BITB };
//assign BLUE = { BITA, BITA };
//assign BLUE = 0;

endmodule



