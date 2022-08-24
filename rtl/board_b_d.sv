module board_b_d (
    input CLK_32M,
    input CLK_96M,
    input CE_PIX,

    output [15:0] DOUT,
    output DOUT_VALID,

    input [15:0] DIN,
    input [19:0] A,
    input [1:0]  BYTE_SEL,

    input [7:0] IO_A,
    input [7:0] IO_DIN,

    input MRD,
    input MWR,
    input IORD,
    input IOWR,
    input CHARA,
    input CHARA_P,
    input NL,

    input [8:0] VE,
    input [8:0] HE,

    output [4:0] RED,
    output [4:0] GREEN,
    output [4:0] BLUE,
    output P1L,

    input [63:0] sdr_data,
    output [24:1] sdr_addr,
    output sdr_req,
    input sdr_rdy,

    input paused,
    
       input en_layer_a,
       input en_layer_b,
       input en_palette
);

// M72-B-D 1/8
// Didn't implement WAIT signal
wire WRA = MWR & CHARA & ~A[15];
wire WRB = MWR & CHARA & A[15];
wire RDA = MRD & CHARA & ~A[15];
wire RDB = MRD & CHARA & A[15];

wire VSCKA = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b000);
wire HSCKA = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b001);
wire VSCKB = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b010);
wire HSCKB = IOWR & (IO_A[7:6] == 2'b10) & (IO_A[3:1] == 3'b011);

wire [3:0] BITA;
wire [3:0] BITB;
wire [3:0] COLA;
wire [3:0] COLB;
wire CP15A, CP15B, CP8A, CP8B;

wire [15:0] DOUT_A, DOUT_B;

assign DOUT = pal_dout_valid ? pal_dout : RDA ? DOUT_A : DOUT_B;
assign DOUT_VALID = RDA | RDB | pal_dout_valid;

wire [19:0] addr_a, addr_b;
wire [31:0] data_a, data_b;
wire req_a, req_b;
wire rdy_a, rdy_b;

board_b_d_sdram board_b_d_sdram(
    .clk_ram(CLK_96M),
    .clk(CLK_32M),

    .addr_a(addr_a),
    .data_a(data_a),
    .req_a(req_a),
    .rdy_a(rdy_a),

    .addr_b(addr_b),
    .data_b(data_b),
    .req_b(req_b),
    .rdy_b(rdy_b),

    .sdr_addr(sdr_addr),
    .sdr_data(sdr_data),
    .sdr_req(sdr_req),
    .sdr_rdy(sdr_rdy)
);

board_b_d_layer layer_a(
    .CLK_32M(CLK_32M),
    .CE_PIX(CE_PIX),

    .DOUT(DOUT_A),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDA),
    .WR(WRA),

    .IO_DIN(IO_DIN),
    .IO_A(IO_A),

    .VSCK(VSCKA),
    .HSCK(HSCKA),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITA),
    .COL(COLA),
    .CP15(CP15A),
    .CP8(CP8A),

    .sdr_addr(addr_a),
    .sdr_data(data_a),
    .sdr_req(req_a),
    .sdr_rdy(rdy_a),

    .enabled(en_layer_a),
    .paused(paused)
);


board_b_d_layer layer_b(
    .CLK_32M(CLK_32M),
    .CE_PIX(CE_PIX),

    .DOUT(DOUT_B),
    .DIN(DIN),
    .A(A),
    .BYTE_SEL(BYTE_SEL),
    .RD(RDB),
    .WR(WRB),

    .IO_DIN(IO_DIN),
    .IO_A(IO_A),

    .VSCK(VSCKB),
    .HSCK(HSCKB),
    .NL(NL),

    .VE(VE),
    .HE(HE),

    .BIT(BITB),
    .COL(COLB),
    .CP15(CP15B),
    .CP8(CP8B),

    .sdr_addr(addr_b),
    .sdr_data(data_b),
    .sdr_req(req_b),
    .sdr_rdy(rdy_b),

    .enabled(en_layer_b),
    .paused(paused)
);


wire [4:0] r_out, g_out, b_out;
wire [15:0] pal_dout;
wire pal_dout_valid;

wire a_opaque = (BITA != 4'b0000);
wire b_opaque = (BITB != 4'b0000);

wire S = a_opaque;

assign P1L = ~(CP15A & a_opaque) & ~(CP15B & b_opaque) & ~(CP8A & BITA[3]) & ~(CP8B & BITB[3]);

kna91h014 kna91h014(
    .CLK_32M(CLK_32M),

    .G(CHARA_P),
    .SELECT(S),
    .CA({COLA, BITA}),
    .CB({COLB, BITB}),

    .E1_N(), // TODO
    .E2_N(), // TODO
    
    .MWR(MWR & BYTE_SEL[0]),
    .MRD(MRD),

    .DIN(DIN),
    .DOUT(pal_dout),
    .DOUT_VALID(pal_dout_valid),
    .A(A),

    .RED(r_out),
    .GRN(g_out),
    .BLU(b_out)
);

assign RED = en_palette ? r_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };
assign GREEN = en_palette ? g_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };
assign BLUE = en_palette ? b_out : b_opaque ? { BITB, BITB[3] } : { BITA, BITA[3] };

endmodule



