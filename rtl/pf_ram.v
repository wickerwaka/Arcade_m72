
module pf_ram(input [7:0] a,
	      input [7:0]  din,
	      output [7:0] dout,
	      input 	   ce,
	      input 	   we);

   parameter which = 0;
   
   reg [7:0] ram[0:255];
   reg [7:0] d;

   integer    j;
   reg [31:0] jj;
   
`ifdef SIMULATION
   initial
     begin
	for (j = 0; j < 256; j = j + 1)
	  begin
`ifdef verilator	  
	     jj = which+(j*4);
	     ram[j] = { 2'b0, jj[5:0] };
`else
	     //ram[j] = j & 8'h3f;
	     ram[j] = 0;
`endif
	  end
     end
`endif

   wire ram_read, ram_write;
   assign ram_read = ~ce & we;
   assign ram_write = ~we;

   assign dout = d;
   
   always @(a or ram_read)
     if (ram_read)
       d = ram[a];

   always @(a or ram_write or din)
     if (ram_write)
       ram[a] = din;

endmodule // pf_ram
