
module hs_ram(
		input clk,
	    input [5:0]  a,
	    output [7:0] dout,
	    input [7:0]  din,
		
		input 	rclk,
	    input 	   c1,
	    input 	   c2,
	    input 	   cs1);
   
   integer STDERR = 32'h8000_0002;

   reg [7:0] d;
   assign dout = d;
   
   reg [7:0] mem[0:63];
  
`ifdef SIMULATION
   integer    j;
   initial
     begin
		for (j = 0; j < 64; j = j + 1)
		begin
	  		`include "../roms/extract/earom_code.v";
		end
     end
`endif

   always @(posedge clk)
   begin
     if (cs1 == 1'b1)
	 begin
		 if(c1==1'b0 && c2==1'b0)
		 begin
		 	$display("hs_write");
			mem[a] <= din;
		 end 
		 if(c1==1'b0 && c2==1'b1)
		 begin
		 	$display("hs_erase");
			mem[a] <= 8'h00;
		 end
	 end 
   end

   always @(posedge rclk)
   begin
	   if(cs1 == 1'b1 && c1 == 1'b1 && c2 == 1'b0)
	   begin
	   	d <= mem[a];
		$display("hs_read %b > %b", a, mem[a]);
	   end
   end

endmodule
