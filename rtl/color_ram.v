//
// dp ram 16x4
//

module color_ram (input        clk_a,
		  input        clk_b,
		  input        reset,
		  input [3:0]  addr_a,
		  output [3:0] dout_a,
		  input [3:0]  din_a,
		  input        we_n_a,

		  input [3:0]  addr_b,
		  output [3:0] dout_b);


   reg [3:0] ram[0:15];
   reg [3:0] d_a, d_b;

`ifdef SIMULATION
   integer    j;
   
   initial
     begin
	for (j = 0; j < 16; j = j + 1)
	  ram[j] = 0;
     end
`endif

   assign dout_a = d_a;
   
   always @(posedge clk_a)
     if (reset)
       d_a <= 0;
     else
       d_a <= ram[addr_a];

   always @(posedge clk_a)
     if (~we_n_a)
       ram[addr_a] <= din_a;

   //
   assign dout_b = d_b;

   always @(posedge clk_b)
     if (reset)
       d_b <= 0;
     else
       d_b <= ram[addr_b];

   
endmodule

