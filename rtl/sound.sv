module sound (
	input CLK_32M,

	input [15:0] DIN,
	output [15:0] DOUT,
	output DOUT_VALID,
	
	input [19:0] A,
    input [1:0] BYTE_SEL,

	input [7:0] IO_A,
	input [7:0] IO_DIN,

    input SDBEN,
    input MRD,
    input MWR,
	input SOUND,
	input SND,
	input BRQ,

	input pause,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R
);



wire CE_AUDIO, CE_AUDIO_P1;
jtframe_frac_cen #(2) jt51_cen
(
	.clk(CLK_32M),
	.n(10'd50),
	.m(10'd447),
	.cen({CE_AUDIO_P1, CE_AUDIO})
);


wire [7:0] ram_dout;

assign DOUT = { ram_dout, ram_dout };
assign DOUT_VALID = MRD & SDBEN;


dpramv #(.widthad_a(16)) sound_ram
(
	.clock_a(CLK_32M),
	.address_a(ram_addr[15:0]),
	.q_a(ram_dout),
	.wren_a(((MWR & SDBEN) | (~z80_MREQ_n & ~z80_WR_n))),
	.data_a(ram_data),

	.clock_b(),
	.address_b(),
	.data_b(),
	.wren_b(0),
	.q_b()
);

wire [7:0] SD_IN = z80_dout;
wire [7:0] SD_OUT;

wire SA0 = z80_addr[0];
wire SCS = ~z80_IORQ_n && (z80_addr[2:1] == 2'b00);
wire SIRQ_N;
wire SRESET;
wire SWR_N = z80_WR_n;

wire M1_n;
wire [15:0] z80_addr;
wire z80_IORQ_n, z80_RD_n, z80_WR_n, z80_MREQ_n, z80_M1_n;

wire [15:0] ram_addr = BRQ ? A[15:0] : z80_addr;
wire [7:0] ram_data = BRQ ? DIN[7:0] : z80_dout;
wire [7:0] z80_din = ( ~z80_M1_n & ~z80_IORQ_n ) ? {2'b11, ~snd_latch_ready, SIRQ_N, 4'b1111} :
                     ( ~z80_RD_n & ~z80_IORQ_n & (z80_addr[2:1] == 2'b01)) ? snd_latch :
                     ( ~z80_RD_n & SCS ) ? SD_OUT :
                     ( ~z80_RD_n ) ? ram_dout : 8'hff;
wire [7:0] z80_dout;

T80s z80(
	.RESET_n(~BRQ),
	.CLK(CLK_32M),
	.CEN(CE_AUDIO & ~pause),
	.INT_n(~(~SIRQ_N | snd_latch_ready)),
	.BUSRQ_n(~BRQ),
	.M1_n(z80_M1_n),
	.MREQ_n(z80_MREQ_n),
	.IORQ_n(z80_IORQ_n),
	.RD_n(z80_RD_n),
	.WR_n(z80_WR_n),
	.A(z80_addr),
	.DI(z80_din),
	.DO(z80_dout)
);

jt51 ym2151(
	.rst(BRQ),
	.clk(CLK_32M),
	.cen(CE_AUDIO & ~pause),
	.cen_p1(CE_AUDIO_P1 & ~pause),
	.cs_n(~SCS),
	.wr_n(SWR_N),
	.a0(SA0),
	.din(SD_IN),
	.dout(SD_OUT),
	.irq_n(SIRQ_N),
	.xleft(AUDIO_L),
	.xright(AUDIO_R)
);

reg [7:0] snd_latch;
reg snd_latch_ready = 0;

always @(posedge CLK_32M) begin
	if (SND & ~IO_A[0]) begin
		snd_latch <= IO_DIN[7:0];
		snd_latch_ready <= 1;
	end

	if (~z80_IORQ_n & ~z80_WR_n & z80_addr[2:1] == 2'b11) snd_latch_ready <= 0;

end


endmodule