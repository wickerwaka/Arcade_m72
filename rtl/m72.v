`timescale 1 ns / 1 ns

module m72 (
	input CLK_32M,
	input CLK_96M,

	input sys_clk,
	input reset_n,
	output reg ce_pix,
	
	input z80_reset_n,

	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,

	output VGA_HS,
	output VGA_VS,
	output VGA_HB,
	output VGA_VB,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,

	input        ioctl_wr,
	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,

	input [1:0] coin,
	input [1:0] start_buttons,
	input [3:0] p1_joystick,
	input [3:0] p2_joystick,
	input [3:0] p1_buttons,
	input [3:0] p2_buttons,
	input service_button,
	input [15:0] dip_sw,

	output [1:0] sdr_wr_sel1,
	output [15:0] sdr_din1,
	input [15:0] sdr_dout1,
	output [24:1] sdr_addr1,
	output sdr_req1,
	input sdr_ack1,

	output [1:0] sdr_wr_sel2,
	output [15:0] sdr_din2,
	input [15:0] sdr_dout2,
	output [24:1] sdr_addr2,
	output sdr_req2,
	input sdr_ack2,

	input en_layer_a,
	input en_layer_b,
	input en_sprites,
	input en_layer_palette,
	input en_sprite_palette,

	input sprite_freeze
);

// Divide 32Mhz clock by 4 for pixel clock
reg [3:0] ce_counter;
reg [3:0] cpu_ce_counter;
reg ce_cpu, ce_4x_cpu;
always @(posedge CLK_32M) begin
	if (!reset_n) begin
		ce_pix <= 0;
		ce_cpu <= 0;
		ce_4x_cpu <= 0;
		cpu_ce_counter <= 0;
		ce_counter <= 0;
	end else begin
		ce_pix <= 0;
		ce_cpu <= 0;
		ce_4x_cpu <= 0;
			
		if (~ls245_en && (sdr_ack1 == sdr_req1)) begin
			cpu_ce_counter <= cpu_ce_counter + 4'd1;
			ce_4x_cpu <= 1;
			ce_cpu <= cpu_ce_counter[1:0] == 2'b11;
		end
		ce_counter <= ce_counter + 4'd1;

		ce_pix <= ce_counter[1:0] == 0;
	end
end

wire clock = CLK_32M;

/* Global signals from schematics */
wire M_IO = cpu_mem_read | cpu_mem_write; // high = memory low = IO
wire IOWR = cpu_io_write; // IO Write
wire IORD = cpu_io_read; // IO Read
wire MWR = cpu_mem_write; // Mem Write
wire MRD = cpu_mem_read; // Mem Read
wire DBEN = cpu_io_write | cpu_io_read | cpu_mem_read | cpu_mem_write;

wire TNSL;

wire [15:0] cpu_mem_out;
wire [19:0] cpu_mem_addr;
wire [1:0] cpu_mem_sel;
reg cpu_mem_read_lat, cpu_mem_write_lat;
wire cpu_mem_read_w, cpu_mem_write_w;
wire cpu_mem_read = cpu_mem_read_w | cpu_mem_read_lat;
wire cpu_mem_write = cpu_mem_write_w | cpu_mem_write_lat;

wire cpu_io_read, cpu_io_write;
wire [7:0] cpu_io_in;
wire [7:0] cpu_io_out;
wire [7:0] cpu_io_addr;

wire [15:0] cpu_mem_in;


wire [15:0] cpu_word_out = cpu_mem_addr[0] ? { cpu_mem_out[7:0], 8'h00 } : cpu_mem_out;
wire [19:0] cpu_word_addr = { cpu_mem_addr[19:1], 1'b0 };
wire [1:0] cpu_word_byte_sel = cpu_mem_addr[0] ? { cpu_mem_sel[0], 1'b0 } : cpu_mem_sel;

function [15:0] word_shuffle(input [19:0] addr, input [15:0] data);
	begin
		word_shuffle = addr[0] ? { 8'h00, data[15:8] } : data;
	end
endfunction

reg mem_rq_active = 0;
reg b_d_dout_valid_lat, obj_pal_dout_valid_lat, sound_dout_valid_lat, sprite_dout_valid_lat;

always @(posedge CLK_32M or negedge reset_n)
begin
	if (!reset_n) begin
		mem_rq_active <= 0;
		b_d_dout_valid_lat <= 0;
		obj_pal_dout_valid_lat <= 0;
		sound_dout_valid_lat <= 0;
		sprite_dout_valid_lat <= 0;
	end else begin
		cpu_mem_read_lat <= cpu_mem_read_w;
		cpu_mem_write_lat <= cpu_mem_write_w;

		b_d_dout_valid_lat <= b_d_dout_valid;
		obj_pal_dout_valid_lat <= obj_pal_dout_valid;
		sound_dout_valid_lat <= sound_dout_valid;
		sprite_dout_valid_lat <= sprite_dout_valid;

		if (ls245_en && ((cpu_mem_read_w & ~cpu_mem_read_lat) || (cpu_mem_write_w & ~cpu_mem_write_lat))) begin // sdram request
			sdr_addr1 <= rom0_ce ? { 2'b00, cpu_word_addr[16:1] } :
				rom1_ce ? { 2'b01, cpu_word_addr[16:1] } :
				{ 2'b10, cpu_word_addr[16:1] };
			sdr_wr_sel1 <= 2'b00;
			if (cpu_mem_write & ram_cs2 ) begin
				sdr_wr_sel1 <= cpu_word_byte_sel;
				sdr_din1 <= cpu_word_out;
			end
			sdr_req1 <= ~sdr_ack1;
			mem_rq_active <= 1;
		end else if ((sdr_ack1 == sdr_req1) && mem_rq_active) begin
			mem_rq_active <= 0;
		end
	end
end

assign cpu_mem_in = b_d_dout_valid_lat ? word_shuffle(cpu_mem_addr, b_d_dout) :
					obj_pal_dout_valid_lat ? word_shuffle(cpu_mem_addr, obj_pal_dout) :
					sound_dout_valid_lat ? word_shuffle(cpu_mem_addr, sound_dout) :
					sprite_dout_valid_lat ? word_shuffle(cpu_mem_addr, sprite_dout) :
					word_shuffle(cpu_mem_addr, sdr_dout1);

wire ioctl_h0_cs, ioctl_h1_cs, ioctl_l0_cs, ioctl_l1_cs;
wire [3:0] ioctl_gfx_a_cs;
wire [3:0] ioctl_gfx_b_cs;
wire [7:0] ioctl_sprite_cs;

wire ls245_en, rom0_ce, rom1_ce, ram_cs2;


wire [15:0] switches = { p2_buttons, p2_joystick, p1_buttons, p1_joystick };
wire [15:0] flags = { 8'hff, TNSL, 1'b1, 1'b1 /*TEST*/, 1'b1 /*R*/, coin, start_buttons };
wire IO_L = ~cpu_io_addr[0];
wire IO_H =  cpu_io_addr[0];

reg [7:0] sys_flags = 0;
wire BRQ = ~sys_flags[4];
// TODO BANK, CBLK, NL
always @(posedge CLK_32M) begin
	if (FSET & IO_L) sys_flags <= cpu_io_out[7:0];
end

assign cpu_io_in =  (SW & IO_L) ? switches[7:0] :
                    (SW & IO_H) ? switches[15:8] :
                    (FLAG & IO_L) ? flags[7:0] :
                    (FLAG & IO_H) ? flags[15:8] :
                    (DSW & IO_L) ? dip_sw[7:0] :
                    (DSW & IO_H) ? dip_sw[15:8] :
					8'hff;

reg irq_rq = 0;
reg [8:0] irq_addr;
wire irq_ack;

cpu v30(
	.clk(CLK_32M),
	.ce(ce_cpu), // TODO
	.ce_4x(ce_4x_cpu), // TODO
	.reset(~reset_n),
	.turbo(1),
	.SLOWTIMING(0),

	.cpu_idle(),
	.cpu_halt(),
	.cpu_irqrequest(),
	.cpu_prefix(),

	.dma_active(0),
	.sdma_request(0),
	.canSpeedup(),

	.bus_read(cpu_mem_read_w),
	.bus_write(cpu_mem_write_w),
	.bus_be(cpu_mem_sel),
	.bus_addr(cpu_mem_addr),
	.bus_datawrite(cpu_mem_out),
	.bus_dataread(cpu_mem_in),

	// TODO
	.irqrequest_in(irq_rq),
	.irqvector_in(irq_addr),
	.irqrequest_ack(irq_ack),

	.load_savestate(0),

	// TODO
	.cpu_done(),
	.cpu_export(),

	.RegBus_Din(cpu_io_out),
	.RegBus_Adr(cpu_io_addr),
	.RegBus_wren(cpu_io_write),
	.RegBus_rden(cpu_io_read),
	.RegBus_Dout(cpu_io_in),

	.sleep_savestate(0)
);

pal_3a pal_3a(
	.a(cpu_mem_addr),
	.bank(),
	.dben(~DBEN), // FIXME TODO
	.m_io(M_IO),
	.cod(),
	.ls245_en(ls245_en),
	.rom0_ce(rom0_ce),
	.rom1_ce(rom1_ce),
	.ram_cs2(ram_cs2),
	.s(),
	.n_s()
);

wire SW, FLAG, DSW, SND, FSET, DMA_ON, ISET, INTCS;

pal_4d pal_4d(
    .IOWR(IOWR),
    .IORD(IORD),
	.A(cpu_io_addr),
	.SW(SW),
	.FLAG(FLAG),
	.DSW(DSW),
	.SND(SND),
    .FSET(FSET),
    .DMA_ON(DMA_ON),
    .ISET(ISET),
    .INTCS(INTCS)
);

wire BUFDBEN, BUFCS, OBJ_P, CHARA_P, CHARA, SOUND, SDBEN;

pal_3d pal_3d(
	.A(cpu_mem_addr),
    .M_IO(M_IO),
    .DBEN(~DBEN),
    .TNSL(1), // TODO
    .BRQ(BRQ), // TODO

	.BUFDBEN(BUFDBEN),
	.BUFCS(BUFCS),
	.OBJ_P(OBJ_P),
	.CHARA_P(CHARA_P),
    .CHARA(CHARA),
    .SOUND(SOUND),
    .SDBEN(SDBEN)
);

download_selector download_selector(
	.ioctl_addr(ioctl_addr),
	.h0_cs(ioctl_h0_cs),
	.h1_cs(ioctl_h1_cs),
	.l0_cs(ioctl_l0_cs),
	.l1_cs(ioctl_l1_cs),
	.gfx_a_cs(ioctl_gfx_a_cs),
	.gfx_b_cs(ioctl_gfx_b_cs),
	.sprite_cs(ioctl_sprite_cs)
);


reg old_vblk, old_hint;
// assign cpu_int_rq = (vblank_trig | hint_trig); TODO
always @(posedge CLK_32M) begin
	if (irq_ack | ~irq_rq) begin
		old_vblk <= VBLK;
		old_hint <= HINT;

		irq_rq <= 0;

		if (VBLK & ~old_vblk) begin
			irq_rq <= 1;
			irq_addr <= 9'h80;
		end else if(HINT & ~old_hint) begin
			irq_rq <= 1;
			irq_addr <= 9'h88;
		end
	end
end

wire [8:0] VE, V;
wire [9:0] HE, H;
wire HBLK, VBLK, HS, VS;
wire HINT;

assign VGA_HS = HS;
assign VGA_HB = HBLK;
assign VGA_VS = VS;
assign VGA_VB = VBLK;

kna70h015 kna70h015(
	.CLK_32M(CLK_32M),

	.CE_PIX(ce_pix),
	.D(cpu_io_out),
	.A0(cpu_io_addr[0]),
	.ISET(ISET),
	.NL(0),
	.S24H(0),

	.CLD(),
	.CPBLK(),

	.VE(VE),
	.V(V),
	.HE(HE),
	.H(H),

	.HBLK(HBLK),
	.VBLK(VBLK),
	.HINT(HINT),

	.HS(HS),
	.VS(VS)
);

wire [15:0] b_d_dout;
wire b_d_dout_valid;

wire [4:0] char_r, char_g, char_b;
wire P1L;

board_b_d board_b_d(
	.CLK_32M(CLK_32M),

    .sys_clk(sys_clk),
    .ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

    .gfx_a_cs(ioctl_gfx_a_cs),
    .gfx_b_cs(ioctl_gfx_b_cs),

    .CE_PIX(ce_pix),

    .DOUT(b_d_dout),
	.DOUT_VALID(b_d_dout_valid),

    .DIN(M_IO ? cpu_word_out : { 8'h00, cpu_io_out }),
    .A(M_IO ? cpu_word_addr : { 8'h00, cpu_io_addr }),
    .BYTE_SEL(M_IO ? cpu_word_byte_sel : 2'b01 ),

    .MRD(MRD),
    .MWR(MWR),
    .IORD(IORD),
    .IOWR(IOWR),
    .CHARA(CHARA),
	.CHARA_P(CHARA_P),
    .NL(),

    .VE(VE),
    .HE({HE[9], HE[7:0]}),


	.RED(char_r),
	.GREEN(char_g),
	.BLUE(char_b),
	.P1L(P1L),

	.en_layer_a(en_layer_a),
	.en_layer_b(en_layer_b),
	.en_palette(en_layer_palette)
);


wire [15:0] sound_dout;
wire sound_dout_valid;

sound sound(
	.CLK_32M(CLK_32M),
	.DIN(cpu_mem_out),
	.DOUT(sound_dout),
	.DOUT_VALID(sound_dout_valid),
	
	.A(cpu_mem_addr),
    .BYTE_SEL(cpu_mem_sel),

	.IO_A(cpu_io_addr),
	.IO_DIN(cpu_io_out),

    .SDBEN(SDBEN),
	.SOUND(SOUND),
	.SND(SND),
	.BRQ(BRQ),
    .MRD(MRD),
    .MWR(MWR),

	.AUDIO_L(AUDIO_L),
	.AUDIO_R(AUDIO_R)
);

// Temp A-C board palette
wire [15:0] obj_pal_dout;
wire obj_pal_dout_valid;


wire [4:0] obj_pal_r, obj_pal_g, obj_pal_b;
kna91h014 obj_pal(
    .CLK_32M(CLK_32M),

    .G(OBJ_P),
    .SELECT(0),
    .CA(obj_pix),
    .CB(obj_pix),

    .E1_N(), // TODO
    .E2_N(), // TODO
	
	.MWR(MWR & cpu_word_byte_sel[0]),
	.MRD(MRD),

	.DIN(cpu_word_out),
    .DOUT(obj_pal_dout),
    .DOUT_VALID(obj_pal_dout_valid),
    .A(cpu_word_addr),

    .RED(obj_pal_r),
    .GRN(obj_pal_g),
    .BLU(obj_pal_b)
);

wire [4:0] obj_r = en_sprite_palette ? obj_pal_r : { obj_pix[3:0], 1'b0 };
wire [4:0] obj_g = en_sprite_palette ? obj_pal_g : { obj_pix[3:0], 1'b0 };
wire [4:0] obj_b = en_sprite_palette ? obj_pal_b : { obj_pix[3:0], 1'b0 };

wire P0L = (|obj_pix[3:0]) && en_sprites;

assign VGA_R = (P0L & P1L) ? {obj_r[4:0], obj_r[4:2]} : {char_r[4:0], char_r[4:2]};
assign VGA_G = (P0L & P1L) ? {obj_g[4:0], obj_g[4:2]} : {char_g[4:0], char_g[4:2]};
assign VGA_B = (P0L & P1L) ? {obj_b[4:0], obj_b[4:2]} : {char_b[4:0], char_b[4:2]};

wire [15:0] sprite_dout;
wire sprite_dout_valid;

wire [7:0] obj_pix;

sprite sprite(
	.CLK_32M(CLK_32M),
	.CLK_96M(CLK_96M),
	.CE_PIX(ce_pix),

	.DIN(cpu_word_out),
	.DOUT(sprite_dout),
	.DOUT_VALID(sprite_dout_valid),
	
	.A(cpu_word_addr),
    .BYTE_SEL(cpu_word_byte_sel),

    .BUFDBEN(BUFDBEN),
    .MRD(MRD),
    .MWR(MWR),

	.VE(VE),
	.NL(0),
	.HBLK(HBLK),
	.pix_test(obj_pix),

	.base_address('h80000),

	.TNSL(TNSL),
	.DMA_ON(DMA_ON & ~sprite_freeze),

	.sdr_wr_sel(sdr_wr_sel2),
	.sdr_din(sdr_din2),
	.sdr_dout(sdr_dout2),
	.sdr_addr(sdr_addr2),
	.sdr_req(sdr_req2),
	.sdr_ack(sdr_ack2)
);


endmodule
