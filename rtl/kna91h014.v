module kna91h014 (
	input CLK_32M,

	input [7:0] CB,	// Pins 3-10.
	input [7:0] CA,	// Pins 11-18.
	
	input SELECT,	// Pin 50. "S"
	
	input E1_N,		// Pin 52.
	input E2_N,		// Pin 51. CBLK.

	input DCLK,	// Pixel clock A input. Pin 48 (or 49?)
		
	input G,		// Pin 30. G_N.
	
	input MWR,	// Pin 29.
	input MRD,	// Pin 28.

	input [15:0] DIN,	// Pins 25, 22-19 (split to input for Verilog).
	output [15:0] DOUT,	// Pins 25, 22-19 (split to output for Verilog).
	output DOUT_VALID,
	
	input [19:1] A,	// Pins 53-60

	output reg [4:0] RED,	// Pins 47-43.
	output reg [4:0] GRN,	// Pins 42-40, 37-36.
	output reg [4:0] BLU	// Pins 35-31.
);

wire [7:0] A_IN = A[8:1];
wire A_L = A[10];
wire A_H = A[11];

// Col (CA / CB) input mux...
wire [7:0] col_mux = (SELECT) ? CA : CB;		// Choose CA input when SELECT (S) is High. 

// Addr mux...
wire [7:0] addr_mux = G ? A_IN : col_mux;	// Use CPU address when G_N is Low, else use col_mux as the address.

// Palette RAMs...
reg [4:0] ram_a [0:255];
reg [4:0] ram_b [0:255];
reg [4:0] ram_c [0:255];

// RAM Addr decoding...
wire ram_a_cs = {A_H, A_L}==2'd0 | {A_H, A_L}==2'd3;
wire ram_b_cs = {A_H, A_L}==2'd1;
wire ram_c_cs = {A_H, A_L}==2'd2;

// Write enable, and addr decoding for RAM writes.
wire wr_ena = G & MWR;
wire rd_ena = G & MRD;

wire ram_wr_a = ram_a_cs & wr_ena;
wire ram_wr_b = ram_b_cs & wr_ena;
wire ram_wr_c = ram_c_cs & wr_ena;

always @(posedge CLK_32M) begin
	if (ram_wr_a) ram_a[addr_mux] <= DIN[4:0];
	if (ram_wr_b) ram_b[addr_mux] <= DIN[4:0];
	if (ram_wr_c) ram_c[addr_mux] <= DIN[4:0];
end

// DOUT read driver...
assign DOUT = { 11'd0,
	(ram_a_cs & rd_ena) ? ram_a[addr_mux] :
	(ram_b_cs & rd_ena) ? ram_b[addr_mux] :
	(ram_c_cs & rd_ena) ? ram_c[addr_mux] : 5'h00 };
assign DOUT_VALID = rd_ena;

// Latch RAM outputs...
reg [4:0] red_lat;
reg [4:0] grn_lat;
reg [4:0] blu_lat;
always @(posedge DCLK) red_lat <= ram_a[addr_mux];
always @(posedge DCLK) grn_lat <= ram_b[addr_mux];
always @(posedge DCLK) blu_lat <= ram_c[addr_mux];

// Output drivers to RGB DACs...
wire blank = 1'b0;	// Todo.
assign RED = (!blank) ? red_lat : 5'h00;
assign GRN = (!blank) ? grn_lat : 5'h00;
assign BLU = (!blank) ? blu_lat : 5'h00;

//assign BLU = col_mux[4:0];

endmodule
