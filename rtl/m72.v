`timescale 1 ns / 1 ns

module m72 (
	input CLK_32M,
	input sys_clk,
	input reset_n,
	output ce_pix,
	
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
	input sdr_ack2
);

// Divide 32Mhz clock by 4 for pixel clock
reg [1:0] clk_div;
always @(posedge CLK_32M) clk_div <= clk_div + 2'd1;
assign ce_pix = clk_div == 2'b01;

wire clock = CLK_32M;


/* Global signals from schematics */
wire M_IO = ~cpu_iorq; // high = memory low = IO
wire IOWR = cpu_iorq & cpu_we & stb; // IO Write
wire IORD = cpu_iorq & ~cpu_we & stb; // IO Read
wire MWR = ~cpu_iorq & cpu_we & stb; // Mem Write
wire MRD = ~cpu_iorq & ~cpu_we & stb; // Mem Read

wire TNSL;

reg wb_ack_o = 0;
wire stb, cyc;
reg [19:0] pc;

wire [15:0] cpu_dout;
wire [19:1] cpu_addr;
wire [1:0] cpu_sel;
wire cpu_we;
wire cpu_iorq;
wire cpu_nmi;
wire cpu_nmi_ack;
wire cpu_int_rq;
wire cpu_int_ack;

// add 1 cycle wait to acknowledge
reg wb_ack_wait = 0;
reg [15:0] rom_ram_data = 0;

always @(posedge CLK_32M or negedge reset_n)
begin
	if (!reset_n) begin
		wb_ack_o <= 0;
		wb_ack_wait <= 0;
	end else begin
		if (stb) begin
			if (wb_ack_o) begin
				wb_ack_o <= 0;
				wb_ack_wait <= 0;
			end else begin
				if (ls245_en) begin // sdram request
					if (wb_ack_wait) begin
						wb_ack_o <= (sdr_ack1 == sdr_req1);
						wb_ack_wait <= ~(sdr_ack1 == sdr_req1);
						rom_ram_data <= sdr_dout1;
					end else begin
						wb_ack_wait <= 1;
						sdr_addr1 <= rom0_ce ? { 2'b00, cpu_addr[16:1] } :
							rom1_ce ? { 2'b01, cpu_addr[16:1] } :
							{ 2'b10, cpu_addr[16:1] };
						sdr_wr_sel1 <= ( cpu_we & ram_cs2 ) ? cpu_sel : 2'b00;
						sdr_req1 <= ~sdr_ack1;
						sdr_din1 <= cpu_dout;
					end
				end else begin
					wb_ack_wait <= 1;
					wb_ack_o <= wb_ack_wait;
				end
			end
		end
	end
end

zet zet_inst (
	.pc (pc),	// output [19:0]

	// Wishbone master interface
	.wb_clk_i ( CLK_32M ),		// input wb_clk_i
	.wb_rst_i ( !reset_n ),		// input wb_rst_i
	.wb_dat_i ( cpu_din ),		// input [15:0] wb_dat_i
	.wb_dat_o ( cpu_dout ),		// output [15:0] wb_dat_o
	.wb_adr_o ( cpu_addr ),			// output [19:1] wb_adr_o
	.wb_we_o  ( cpu_we ),			// output wb_we_o
	.wb_tga_o ( cpu_iorq ),		// output wb_tga_o
	.wb_sel_o ( cpu_sel ),		// output [1:0] wb_sel_o
	.wb_stb_o ( stb ),			// output wb_stb_o
	.wb_cyc_o ( cyc ),			// output wb_cyc_o
	.wb_ack_i ( wb_ack_o ),		// input wb_ack_i
	.wb_tgc_i ( cpu_int_rq ),			// input wb_tgc_i
	.wb_tgc_o ( cpu_int_ack ),			// output wb_tgc_o
	.nmi      ( cpu_nmi ),			// input nmi
	.nmia     ( cpu_nmi_ack )			// output nmia
);

wire ioctl_h0_cs, ioctl_h1_cs, ioctl_l0_cs, ioctl_l1_cs;
wire [3:0] ioctl_gfx_a_cs;
wire [3:0] ioctl_gfx_b_cs;
wire [7:0] ioctl_sprite_cs;

wire ls245_en, rom0_ce, rom1_ce, ram_cs2;


reg [15:0] pic;

wire [15:0] switches = { p2_buttons, p2_joystick, p1_buttons, p1_joystick };
wire [15:0] flags = { 8'hff, TNSL, 1'b1, 1'b1 /*TEST*/, 1'b1 /*R*/, coin, start_buttons };

wire [15:0] cpu_din =
	(vblank_trig && cpu_int_ack) ? 16'h0020 :
	(hint_trig && cpu_int_ack) ? 16'h0022 :
	b_d_dout_valid ? b_d_dout :
	obj_pal_dout_valid ? obj_pal_dout :
	sound_dout_valid ? sound_dout :
	sprite_dout_valid ? sprite_dout :
	ls245_en ? rom_ram_data : 
	SW ? switches :
	FLAG ? flags :
	DSW ? dip_sw :
	INTCS ? pic : // TODO PIC
	16'hffff;

always @(posedge clock or negedge reset_n) begin
	if (~reset_n) begin
		pic <= 0;
	end else begin
		if (cpu_we) begin
			if (INTCS)
				pic <= cpu_dout;
		end
	end
end

pal_3a pal_3a(
	.a(cpu_addr),
	.bank(),
	.dben(~stb),
	.m_io(~cpu_iorq),
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
    .M_IO(M_IO),
    .IOWR(IOWR),
    .IORD(IORD),
	.A(cpu_addr),
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
	.A(cpu_addr),
    .M_IO(~cpu_iorq),
    .DBEN(~stb),
    .TNSL(1), // TODO
    .BRQ(), // TODO

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


/*
pic pic_inst (
	.clk( clock ),					// input clk
	.reset( !reset_n ),				// input reset
	.cs( pic_cs ),					// input cs
	.data_m_data_in( dat_o ),		// input [15:0] data_m_data_in
	.data_m_data_out( pic_dout ),	// output [15:0] data_m_data_out
	.data_m_bytesel( sel ),			// input [1:0] data_m_bytesel
	.data_m_wr_en( we ),			// input data_m_wr_en
	.data_m_access( stb ),			// input data_m_access
	.data_m_ack( pic_data_ack ),	// output data_m_ack
	.intr_in( pic_intr_in ),		// input [7:0] intr_in
	.irq( pic_irq_vec ),			// output [7:0] irq
	.intr( intr ),					// output intr
	.inta( inta )					// input inta
);
*/

reg vblank_trig;
reg hint_trig;
reg old_vblk, old_hint;
assign cpu_int_rq = (vblank_trig | hint_trig);
always @(posedge clock or negedge reset_n) begin
	if (!reset_n) begin
		vblank_trig <= 1'b0;
		hint_trig <= 1'b0;
		old_vblk <= 1'b0;
		old_hint <= 1'b0;
	end
	else begin
		old_vblk <= VBLK;
		old_hint <= HINT;

		if (VBLK & ~old_vblk) vblank_trig <= 1'b1;
		if (HINT & ~old_hint) hint_trig <= 1'b1;
		if (vblank_trig && cpu_int_ack) vblank_trig <= 1'b0;
		if (hint_trig && cpu_int_ack) hint_trig <= 1'b0;
	
	end
end


/*wire [15:0] wb_dat_i = (vblank_trig && inta) ? 16'h0020 :
					     (hint_trig && inta) ? 16'h0022 :
											   dat_i;*/

/*
wire [15:0] z80_addr;
wire [7:0] z80_di = sound_ram[ z80_addr ];
wire [7:0] z80_do;

wire [7:0] z80_dinst = 8'h00;	// M1 vector fetch?
wire [6:0] z80_mc;
wire [6:0] z80_ts;

wire z80_cen = 1'b1;
wire z80_wait_n = 1'b1;
wire z80_int_n = 1'b1;
wire z80_nmi_n = 1'b1;
wire z80_busrq_n = 1'b1;


tv80_core tv80_core_inst (
  // Inputs
  .reset_n( z80_reset_n ),
  .clk( clock ),				// Change to sound clock later!
  
  .cen( z80_cen ),
  .wait_n( z80_wait_n ),
  .int_n( z80_int_n ),
  .nmi_n( z80_nmi_n ),
  .busrq_n( z80_busrq_n ),	
  .dinst( z80_dinst ),			// input [7:0] M1 vector fetch?
  .di( z80_di ),				// input [7:0] di

  .m1_n( z80_m1_n ),
  .iorq( z80_iorq ),
  .no_read( z80_no_read ),
  .write( z80_write ), 
  .rfsh_n( z80_rfsh_n ),
  .halt_n( z80_halt_n ),
  .busak_n( z80_busak_n ),
  .A( z80_addr ),
  .dout( z80_do ),
  .mc( z80_mc ),				// output [6:0] mc.
  .ts( z80_ts ),				// output [6:0] ts.
  .intcycle_n( z80_intcycle_n ),
  .IntE( z80_IntE ),
  .stop( z80_stop )
);

reg [7:0] sound_ram [0:65535];

// Change to sound clock later!
always @(posedge clock or negedge z80_reset_n)
begin
	if (!z80_reset_n) begin

	end
	else begin
		if (!z80_m1_n & z80_write) sound_ram[ z80_addr ] <= z80_do;
	end
end
*/

wire [8:0] VE, V;
wire [9:0] HE, H;
wire HBLK, VBLK, HS, VS;
wire INT_D, HINT;

assign VGA_HS = HS;
assign VGA_HB = HBLK;
assign VGA_VS = VS;
assign VGA_VB = VBLK;

kna70h015 kna70h015(
	.CLK_32M(CLK_32M),

	.DCLK(ce_pix),
	.D(cpu_dout),
	.ISET(ISET),
	.NL(0),
	.S24H(0),

	.CLD_UNKNOWN(),
	.CPBLK(),

	.VE(VE),
	.V(V),
	.HE(HE),
	.H(H),

	.HBLK(HBLK),
	.VBLK(VBLK),
	.INT_D(INT_D),
	.HINT(HINT),

	.HS(HS),
	.VS(VS)
);

wire [15:0] b_d_dout;
wire b_d_dout_valid;

board_b_d board_b_d(
	.CLK_32M(CLK_32M),

    .sys_clk(sys_clk),
    .ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

    .gfx_a_cs(ioctl_gfx_a_cs),
    .gfx_b_cs(ioctl_gfx_b_cs),

    .DCLK(ce_pix),

    .DOUT(b_d_dout),
	.DOUT_VALID(b_d_dout_valid),

    .DIN(cpu_dout),
    .A(cpu_addr),
    .BYTE_SEL(cpu_sel),
    .MRD(MRD),
    .MWR(MWR),
    .IORD(IORD),
    .IOWR(IOWR),
    .CHARA(CHARA),
	.CHARA_P(CHARA_P),
    .NL(),

    .VE(VE),
    .HE(HE),


	//.RED(VGA_R),
	.GREEN(VGA_G),
	.BLUE(VGA_B),

	.RED(),
//	.GREEN(),
//	.BLUE()
);


wire [15:0] sound_dout;
wire sound_dout_valid;

sound sound(
	.CLK_32M(CLK_32M),
	.DIN(cpu_dout),
	.DOUT(sound_dout),
	.DOUT_VALID(sound_dout_valid),
	
	.A(cpu_addr),
    .BYTE_SEL(cpu_sel),

    .SDBEN(SDBEN),
    .MRD(MRD),
    .MWR(MWR)
);

// Temp A-C board palette
wire [15:0] obj_pal_dout;
wire obj_pal_dout_valid;


wire [4:0] obj_r, obj_g, obj_b;
kna91h014 obj_pal(
    .DCLK(ce_pix),
    .CLK_32M(CLK_32M),

    .G(OBJ_P),
    .SELECT(0),
    .CA(pix_test),
    .CB(pix_test),

    .E1_N(), // TODO
    .E2_N(), // TODO
	
	.MWR(MWR),
	.MRD(MRD),

	.DIN(cpu_dout),
    .DOUT(obj_pal_dout),
    .DOUT_VALID(obj_pal_dout_valid),
    .A(cpu_addr),

    .RED(obj_r),
    .GRN(obj_g),
    .BLU(obj_b)
);

//assign VGA_R = {obj_r[4:0], obj_r[4:2]};
//assign VGA_G = {obj_g[4:0], obj_g[4:2]};
//assign VGA_B = {obj_b[4:0], obj_b[4:2]};

assign VGA_R = {pix_test[3:0], pix_test[3:0]};
//assign VGA_G = {pix_test[3:0], pix_test[3:0]};
//assign VGA_B = {pix_test[3:0], pix_test[3:0]};

wire [15:0] sprite_dout;
wire sprite_dout_valid;

wire [7:0] pix_test;

//assign VGA_R = pix_test;

sprite sprite(
	.CLK_32M(CLK_32M),
	.CE_PIX(ce_pix),

	.DIN(cpu_dout),
	.DOUT(sprite_dout),
	.DOUT_VALID(sprite_dout_valid),
	
	.A(cpu_addr),
    .BYTE_SEL(cpu_sel),

    .BUFDBEN(BUFDBEN),
    .MRD(MRD),
    .MWR(MWR),

	.VE(VE),
	.NL(0),
	.HBLK(HBLK),
	.pix_test(pix_test),

	.TNSL(TNSL),
	.DMA_ON(DMA_ON),

	.sys_clk(sys_clk),
    .ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
    .sprite_cs(ioctl_sprite_cs),

	.sdr_wr_sel(sdr_wr_sel2),
	.sdr_din(sdr_din2),
	.sdr_dout(sdr_dout2),
	.sdr_addr(sdr_addr2),
	.sdr_req(sdr_req2),
	.sdr_ack(sdr_ack2)
);


endmodule
