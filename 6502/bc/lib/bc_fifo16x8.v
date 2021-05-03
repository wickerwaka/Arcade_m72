/* ===============================================================
	(C) 2002 Bird Computer
	All rights reserved.

	bc_fifo16x8.v
		Please read the Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.

		FIFO ram with independent read and write ports. Really
	nothing more than a dual port LUT ram.
=============================================================== */
`timescale 1ns / 1ns

module bc_fifo16x8(clk, wr, wa, ra, di, do);
	input clk;
	input wr;
	input [3:0] wa, ra;
	input [7:0] di;
	output [7:0] do;
	
	reg [7:0] mem [15:0];

	always @(posedge clk) begin
		if (wr)
			mem[wa] <= di;
	end
	
	assign do = mem[ra];

endmodule
