//
// playfield ram
//  synchronous dual port, addressed as 32bit words with byte enables for 4x lanes
//  port a: r/w, 8 bit (i.e. only one enable asserted per cycle)
//  port b: r/o, 32 bit (any enable honored)
//

//`define simple
`define old_style
//`define sync_rd

`ifdef simple
module ram_256x8dp (input reset,
		    input 	 clk_a,
		    input 	 clk_b,
		    input [7:0]  addr_a,
		    input [7:0]  din_a,
		    output [7:0] dout_a,
		    input 	 ce_a,
		    input 	 we_a,

		    input [7:0]  addr_b,
		    output [7:0] dout_b,
		    input 	 ce_b);

   reg [7:0] ram[0:255];
   reg [7:0] d_a;
   wire [7:0] d_b;

   //
   // port a - r/w, 8 bits
   //
   always @(posedge clk_a)
     if (reset)
       d_a <= 0;
     else
       if (~ce_a | ~we_a)
	 begin
	    if (~we_a)
	      ram[addr_a] <= din_a;
	    d_a <= ram[addr_a];
	 end

   assign dout_a = d_a;

   //
   // port b - read only, 32 bits
   //
   assign dout_b = ram[addr_b];

endmodule 


module pf_ram_dp (
		  input 	clk_a,
		  input 	clk_b,
		  input 	reset,
		  input [7:0] 	addr_a,
		  input [7:0] 	din_a,
		  output [7:0] 	dout_a,
		  input [3:0] 	ce_a,
		  input [3:0] 	we_a,

		  input [7:0] 	addr_b,
		  output [31:0] dout_b,
		  input [3:0] 	ce_b
		  );

   wire [7:0] d_a3, d_a2, d_a1, d_a0;
   wire [7:0] d_b3, d_b2, d_b1, d_b0;

   assign dout_a =
	     ~ce_a[3] ? d_a3 :
	     ~ce_a[2] ? d_a2 :
	     ~ce_a[1] ? d_a1 :
	     ~ce_a[0] ? d_a0 :
		  8'b0;

   assign dout_b = { d_b3, d_b2, d_b1, d_b0 };

   ram_256x8dp ram0(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		    .din_a(din_a), .dout_a(d_a0), .ce_a(ce_a[0]), .we_a(we_a[0]),
		    .addr_b(addr_b), .dout_b(d_b0),.ce_b(ce_b[0]));

   ram_256x8dp ram1(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		    .din_a(din_a), .dout_a(d_a1), .ce_a(ce_a[1]), .we_a(we_a[1]),
		    .addr_b(addr_b), .dout_b(d_b1),.ce_b(ce_b[1]));

   ram_256x8dp ram2(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		    .din_a(din_a), .dout_a(d_a2), .ce_a(ce_a[2]), .we_a(we_a[2]),
		    .addr_b(addr_b), .dout_b(d_b2),.ce_b(ce_b[2]));

   ram_256x8dp ram3(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		    .din_a(din_a), .dout_a(d_a3), .ce_a(ce_a[3]), .we_a(we_a[3]),
		    .addr_b(addr_b), .dout_b(d_b3),.ce_b(ce_b[3]));

endmodule
`endif //  `ifdef simple

`ifdef old_style

module pf_ram_dp (
		  input 	clk_a,
		  input 	clk_b,
		  input 	reset,
		  input [7:0] 	addr_a,
		  input [7:0] 	din_a,
		  output [7:0] 	dout_a,
		  input [3:0] 	ce_a,
		  input [3:0] 	we_a,

		  input [7:0] 	addr_b,
		  output [31:0] dout_b,
		  input [3:0] 	ce_b
		  );

   reg [7:0] ram3[0:255];
   reg [7:0] ram2[0:255];
   reg [7:0] ram1[0:255];
   reg [7:0] ram0[0:255];
   reg [7:0] d_a;
   reg [7:0] d_a0, d_a1, d_a2, d_a3;
`ifdef sync_rd
   reg [7:0] d_b3, d_b2, d_b1, d_b0;
`else
   wire [7:0] d_b3, d_b2, d_b1, d_b0;
`endif

`ifdef SIMULATION
   integer    j;
   integer    data_file, f_a, f_d, r;
   reg [11:0]  b_a;
   reg [7:0]  r_a;
   reg [3:0]  r_w;
   
   initial
     begin
	for (j = 0; j < 256; j = j + 1)
	  begin
	     //ram[j] = j & 8'h3f;
	     ram3[j] = 0;
	     ram2[j] = 0;
	     ram1[j] = 0;
	     ram0[j] = 0;
	  end

 `ifdef __CVER__
      	data_file = $fopen("dump.txt", "r");
	if (!data_file) begin
	   $display("can't find dump.txt");
	   $finish;
	end

	while ($fscanf(data_file, "%x %x\n", f_a, f_d) != -1) begin
	   b_a = f_a;
	   r_a = { b_a[9:6], b_a[3:0] };
	   if (b_a[5:4] == 2'b00) r_w = 4'b1110;
	   if (b_a[5:4] == 2'b01) r_w = 4'b1101;
	   if (b_a[5:4] == 2'b10) r_w = 4'b1011;
	   if (b_a[5:4] == 2'b11) r_w = 4'b0111;

	   $display("%x %x -> %x %b", f_a, f_d, r_a, r_w);

	   if (~r_w[3])
	     ram3[r_a] = f_d;
	   else
	     if (~r_w[2])
	       ram2[r_a] = f_d;
	     else
	       if (~r_w[1])
		 ram1[r_a] = f_d;
	       else
		 if (~r_w[0])
		   ram0[r_a] = f_d;
	end
 `endif
     end
`endif

   wire ram_read_a, ram_read_b;

   //
   // port a - r/w, 8 bits
   //
   assign ram_read_a = ce_a != 4'b1111 & we_a == 4'b1111;
	     
   assign dout_a =
	     ~ce_a[3] ? d_a3 :
	     ~ce_a[2] ? d_a2 :
	     ~ce_a[1] ? d_a1 :
	     ~ce_a[0] ? d_a0 :
		  8'b0;

   always @(posedge clk_a)
//   always @(negedge clk_a)
     begin
	if (~ce_a[3] | ~we_a[3])
	  begin
	     if (~we_a[3])
	       ram3[addr_a] <= din_a;
	     else
	       d_a3 <= ram3[addr_a];
	  end

	if (~ce_a[2] | ~we_a[2])
	  begin
	     if (~we_a[2])
	       ram2[addr_a] <= din_a;
	     else
	       d_a2 <= ram2[addr_a];
	  end

	if (~ce_a[1] | ~we_a[1])
	  begin
	     if (~we_a[1])
	       ram1[addr_a] <= din_a;
	     else
	       d_a1 <= ram1[addr_a];
	  end

	if (~ce_a[0] | ~we_a[0])
	  begin
	     if (~we_a[0])
	       ram0[addr_a] <= din_a;
	     else
	       d_a0 <= ram0[addr_a];
	  end
     end

//   always @(posedge clk_a)
//     begin
//	if (~we_a[3])
//	  ram3[addr_a] <= din_a;
//	else
//	  if (~we_a[2])
//	    ram2[addr_a] <= din_a;
//	  else
//	    if (~we_a[1])
//	      ram1[addr_a] <= din_a;
//	    else
//	      if (~we_a[0])
//		ram0[addr_a] <= din_a;
//     end
//
//   assign dout_a = d_a;
//   
//   always @(posedge clk_a)
//     if (reset)
//       d_a <= 0;
//     else
//       if (ram_read_a)
//	 begin
//	    if (~ce_a[3])
//	      d_a <= ram3[addr_a];
//	    else
//	      if (~ce_a[2])
//		d_a <= ram2[addr_a];
//	      else
//		if (~ce_a[1])
//		  d_a <= ram1[addr_a];
//		else
//		  if (~ce_a[0])
//		    d_a <= ram0[addr_a];
//	    //$display("pf_ram_dp: rd a addr %x (ce %b) -> %x", addr_a, ce_a, d_a);
//	 end

   //
   // port b - read only, 32 bits
   //
   assign ram_read_b = ce_b != 4'b1111;

   assign dout_b = { d_b3, d_b2, d_b1, d_b0 };
   
`ifdef sync_rd
   always @(posedge clk_b)
     if (reset)
       begin
	    d_b3 <= 8'b0;
	    d_b2 <= 8'b0;
	    d_b1 <= 8'b0;
	    d_b0 <= 8'b0;
       end
     else
       if (ram_read_b)
	 begin
	    d_b3 <= ram3[addr_b];
	    d_b2 <= ram2[addr_b];
	    d_b1 <= ram1[addr_b];
	    d_b0 <= ram0[addr_b];
	    //$display("pf_ram_dp: rd b addr %x -> %x", addr_b, {d_b3,d_b2,d_b1,d_b0});
	 end
`else
//   always @(addr_b or ram_read_b)
//     if (ram_read_b)
//       begin
//	  d_b3 = ram3[addr_b];
//	  d_b2 = ram2[addr_b];
//	  d_b1 = ram1[addr_b];
//	  d_b0 = ram0[addr_b];
//       end

   assign d_b3 = ram3[addr_b];
   assign d_b2 = ram2[addr_b];
   assign d_b1 = ram1[addr_b];
   assign d_b0 = ram0[addr_b];
`endif

   
endmodule // pf_ram_dp
`endif
