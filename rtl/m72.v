`timescale 1 ns / 1 ns

module sim_m72 (
	input clock,
	input reset_n,

	output [19:0] pc,	// For debugging.
	
    input  [15:0] dat_i,
    output [15:0] dat_o,
    output [19:1] adr,
    output        we,
    output        io_mem,
    output [ 1:0] sel,
    output        stb,
    output        cyc,
    //input         ack,
    //input         intr,
    //output        inta,
    input         nmi,
    output        nmia,
	
	input [7:0] pic_intr_in,
	
	output reg wb_ack_o,
	
	input pixel_clock,
	//input pixel_load_n,
	
	output wire [14:0] bg_tile_rom_addr,
	output wire [14:0] fg_tile_rom_addr,
	
	input [7:0] tile_rom_a0_data,	// IC21, C.
	input [7:0] tile_rom_a1_data,	// IC22, D.
	input [7:0] tile_rom_a2_data,	// IC20, B.
	input [7:0] tile_rom_a3_data,	// IC23, E.
	
	input [7:0] tile_rom_b0_data,	// IC26, J.
	input [7:0] tile_rom_b1_data,	// IC27, K.
	input [7:0] tile_rom_b2_data,	// IC25, H.
	input [7:0] tile_rom_b3_data,	// IC24, F.
	
	input bg_flip,
	input fg_flip,
	
	input [11:0] bg_tile_index,
	input [11:0] fg_tile_index,
	
	output wire bg_out_pin_4,
	output wire bg_out_pin_12,
	output wire bg_out_pin_9,
	output wire bg_out_pin_7,
	
	output wire fg_out_pin_4,
	output wire fg_out_pin_12,
	output wire fg_out_pin_9,
	output wire fg_out_pin_7,
	
	input z80_reset_n
);

reg [8:0] h_count;
reg [8:0] v_count;

always @(posedge pixel_clock or negedge reset_n)
if (!reset_n) begin
	h_count <= 9'd0;
	v_count <= 9'd0;
end
else begin
	h_count <= h_count + 1;	// h_count from 0 to 511.

	if (v_count==9'd283) v_count <= 0;
	else if (h_count==9'd0) v_count <= v_count + 1;
end


wire pixel_load_n = !(h_count[2:0]==7);


assign bg_tile_rom_addr = {bg_tile_index, v_count[2:0]};

// IC3.
kna6034201 kna6034201_bg (
	.clock( pixel_clock ),		// input clock. Pin 18.
	
	.load_n( pixel_load_n ),	// input load_n. Pin 17.
	
	.par_in_1( tile_rom_a0_data ),	// input [7:0] par_in_1. Pins 8-1.
	.par_in_2( tile_rom_a1_data ),	// input [7:0] par_in_2. Pins 16-10.
	.par_in_3( tile_rom_a2_data ),	// input [7:0] par_in_3. Pins 32-39.
	
	.ser_out_1( ser_out_1 ),	// output ser_out_1. Pin 31.
	.ser_out_2( ser_out_2 ),	// output ser_out_2. Pin 30.
	
	.ser_out_3( ser_out_3 ),	// output ser_out_3. Pin 29.
	.ser_out_4( ser_out_4 ),	// output ser_out_4. Pin 28.
	
	.ser_out_5( ser_out_5 ),	// output ser_out_5. Pin 27.
	.ser_out_6( ser_out_6 )		// output ser_out_6. Pin 26.
);

wire ser_out_1;
wire ser_out_2;
wire ser_out_3;
wire ser_out_4;
wire ser_out_5;
wire ser_out_6;


// IC13 and IC5.
shifter_ls166 shifter_ls166_bg (
	.clock( pixel_clock ),		// input clock.
	
	.load_n( pixel_load_n ),	// input load_n.
	
	.par_in_1( tile_rom_a3_data ),	// input [7:0] par_in_1.

	.ser_out_1( ser_out_7 ),	// output ser_out_1. IC13.
	.ser_out_2( ser_out_8 ) 	// output ser_out_2. IC5.
);

wire ser_out_7;
wire ser_out_8;


// LS157. IC12.
assign bg_out_pin_4 =  (!bg_flip) ? ser_out_1 : ser_out_2;
assign bg_out_pin_12 = (!bg_flip) ? ser_out_3 : ser_out_4;
assign bg_out_pin_9 =  (!bg_flip) ? ser_out_5 : ser_out_6;
assign bg_out_pin_7 =  (!bg_flip) ? ser_out_7 : ser_out_8;



assign fg_tile_rom_addr = {fg_tile_index, v_count[2:0]};

// IC3.
kna6034201 kna6034201_fg (
	.clock( pixel_clock ),		// input clock. Pin 18.
	
	.load_n( pixel_load_n ),	// input load_n. Pin 17.
	
	.par_in_1( tile_rom_b0_data ),	// input [7:0] par_in_1. Pins 8-1.
	.par_in_2( tile_rom_b1_data ),	// input [7:0] par_in_2. Pins 16-10.
	.par_in_3( tile_rom_b2_data ),	// input [7:0] par_in_3. Pins 32-39.
	
	.ser_out_1( ser_out_9 ),	// output ser_out_1. Pin 31.
	.ser_out_2( ser_out_10 ),	// output ser_out_2. Pin 30.
	
	.ser_out_3( ser_out_11 ),	// output ser_out_3. Pin 29.
	.ser_out_4( ser_out_12 ),	// output ser_out_4. Pin 28.
	
	.ser_out_5( ser_out_13 ),	// output ser_out_5. Pin 27.
	.ser_out_6( ser_out_14 )	// output ser_out_6. Pin 26.
);

wire ser_out_9;
wire ser_out_10;
wire ser_out_11;
wire ser_out_12;
wire ser_out_13;
wire ser_out_14;


// IC13 and IC5.
shifter_ls166 shifter_ls166_fg (
	.clock( pixel_clock ),		// input clock.
	
	.load_n( pixel_load_n ),	// input load_n.
	
	.par_in_1( tile_rom_a3_data ),	// input [7:0] par_in_1.

	.ser_out_1( ser_out_15 ),	// output ser_out_1. IC13.
	.ser_out_2( ser_out_16 ) 	// output ser_out_2. IC5.
);

wire ser_out_15;
wire ser_out_16;


// LS157. IC12.
assign fg_out_pin_7 =  (!fg_flip) ? ser_out_15 : ser_out_16;
assign fg_out_pin_9 =  (!fg_flip) ? ser_out_13 : ser_out_14;
assign fg_out_pin_12 = (!fg_flip) ? ser_out_11 : ser_out_12;
assign fg_out_pin_4 =  (!fg_flip) ? ser_out_9 : ser_out_10;



always @(posedge clock or negedge reset_n)
if (!reset_n) wb_ack_o <= 0;
else begin
	wb_ack_o <= stb & cyc;
end

/*
wire [15:0] ip;				// CPU Instrcution Pointer
wire [15:0] cs;				// CPU Control State
wire [ 2:0] state;			// CPU State
cpu cpu_inst (
	.ip         (ip),
	.cs         (cs),
	.state      (state),

	.dbg_block  (1'b0),

	.wb_clk_i ( clock ),		// input wb_clk_i
	.wb_rst_i ( !reset_n ),		// input wb_rst_i
	.wb_dat_i ( dat_i ),		// input [15:0] wb_dat_i
	.wb_dat_o ( dat_o ),		// output [15:0] wb_dat_o
	.wb_adr_o ( adr ),			// output [19:1] wb_adr_o
	.wb_we_o  ( we ),			// output wb_we_o
	.wb_tga_o ( io_mem ),		// output wb_tga_o
	.wb_sel_o ( sel ),			// output [1:0] wb_sel_o
	.wb_stb_o ( stb ),			// output wb_stb_o
	.wb_cyc_o ( cyc ),			// output wb_cyc_o
	.wb_ack_i ( wb_ack_o ),		// input wb_ack_i
	.wb_tgc_i ( intr ),			// input wb_tgc_i
	.wb_tgc_o ( inta ),			// output wb_tgc_o
);
*/


zet zet_inst (
	.pc (pc),	// output [19:0]

	// Wishbone master interface
	.wb_clk_i ( clock ),		// input wb_clk_i
	.wb_rst_i ( !reset_n ),		// input wb_rst_i
	.wb_dat_i ( wb_dat_i ),		// input [15:0] wb_dat_i
	.wb_dat_o ( dat_o ),		// output [15:0] wb_dat_o
	.wb_adr_o ( adr ),			// output [19:1] wb_adr_o
	.wb_we_o  ( we ),			// output wb_we_o
	.wb_tga_o ( io_mem ),		// output wb_tga_o
	.wb_sel_o ( sel ),			// output [1:0] wb_sel_o
	.wb_stb_o ( stb ),			// output wb_stb_o
	.wb_cyc_o ( cyc ),			// output wb_cyc_o
	.wb_ack_i ( wb_ack_o ),		// input wb_ack_i
	.wb_tgc_i ( intr ),			// input wb_tgc_i
	.wb_tgc_o ( inta ),			// output wb_tgc_o
	.nmi      ( nmi ),			// input nmi
	.nmia     ( nmia )			// output nmia
);

//wire [15:0] wb_dat_i = (inta) ? pic_irq_vec : dat_i;

wire intr;
wire inta;

wire [19:0] byte_addr = {adr, 1'b0};

wire pic_cs = (byte_addr[7:0]>=8'h40 && byte_addr[7:0]<=8'h43) && io_mem && cyc && stb;

wire [15:0] pic_dout;

wire [7:0] pic_irq_vec;

wire pic_data_ack;

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
always @(posedge clock or negedge reset_n)
if (!reset_n) begin
	//vblank_trig <= 1'b0;
	//hint_trig <= 1'b0;
end
else begin
	if (vblank_trig && inta) vblank_trig <= 1'b0;
	if (hint_trig && inta) hint_trig <= 1'b0;
	
	if (inta && stb) begin
		vblank_trig <= 1'b0;
		hint_trig <= 1'b0;
	end
end

assign intr = (vblank_trig || hint_trig);

wire [15:0] wb_dat_i = (vblank_trig && inta) ? 16'h0020 :
					     (hint_trig && inta) ? 16'h0022 :
											   dat_i;

/*
aopic aopic_inst (
	.clk( clock ),						// input clk
	.rst_n( reset_n ),					// input rst_n
	
	.io_address( adr[1] ),				// input io_address
	.io_read( pic_cs && !we ),			// input io_read
	.io_readdata( pic_dout ),			// output [7:0] io_readdata
	
	.io_write( pic_cs && we ),			// input io_write
	.io_writedata( dat_o[7:0] ),		// input [7:0] io_writedata
	
	.interrupt_input( pic_intr_in ),	// input [7:0] interrupt_input
	
	//.slave_active( ),					// output slave_active
	
	.interrupt_do( intr ),				// output interrupt_do
	.interrupt_vector( pic_irq_vec ),	// output [7:0] interrupt_vector
	.interrupt_done( inta )				// input interrupt_done
);
*/


// Sound...

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
if (!z80_reset_n) begin

end
else begin
	if (!z80_m1_n & z80_write) sound_ram[ z80_addr ] <= z80_do;
end


endmodule
