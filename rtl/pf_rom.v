//
// playfield roms
//

module pf_rom1(input clk,
	       input 	    reset,
	       input [10:0] a,
	       output [7:0] d);
   
   reg [7:0] q;

   always @(posedge clk)
//      always @(a)
`include "../roms/extract/rom_hj7_case.v"

   assign d = q;
endmodule

module pf_rom0(input clk,
	       input 	    reset,
	       input [10:0] a,
	       output [7:0] d);

   reg [7:0] q;

   always @(posedge clk)
//      always @(a)
`include "../roms/extract/rom_f7_case.v"

   assign d = q;
endmodule
