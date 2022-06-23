//============================================================================
// 
//  SD card ROM loader and ROM selector for MISTer.
//  Copyright (C) 2019, 2020 Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

// Rom layout for R-Type
// 0x000000 - 0x00FFFF rt_r-h0-b.1b
// 0x010000 - 0x01FFFF rt_r-l0-b.3b
// 0x020000 - 0x02FFFF rt_r-h1-b.1c
// 0x030000 - 0x03FFFF rt_r-l1-b.3c

module download_selector
(
	input logic [24:0] ioctl_addr,
	output logic h0_cs, h1_cs, l0_cs, l1_cs,
	output logic [3:0] gfx_a_cs,
	output logic [3:0] gfx_b_cs,
	output logic [7:0] sprite_cs
);

	always_comb begin
		{h0_cs, h1_cs, l0_cs, l1_cs} = 0;
		gfx_a_cs = 0;
		gfx_b_cs = 0;
		sprite_cs = 0;

		if(ioctl_addr < 'h10000)
			h0_cs = 1;
		else if(ioctl_addr < 'h20000)
			l0_cs = 1;
		else if(ioctl_addr < 'h30000)
			h1_cs = 1;
		else if(ioctl_addr < 'h40000)
			l1_cs = 1;
		else if(ioctl_addr < 'h48000)
			gfx_a_cs[0] = 1;
		else if(ioctl_addr < 'h50000)
			gfx_a_cs[1] = 1;
		else if(ioctl_addr < 'h58000)
			gfx_a_cs[2] = 1;
		else if(ioctl_addr < 'h60000)
			gfx_a_cs[3] = 1;
		else if(ioctl_addr < 'h68000)
			gfx_b_cs[0] = 1;
		else if(ioctl_addr < 'h70000)
			gfx_b_cs[1] = 1;
		else if(ioctl_addr < 'h78000)
			gfx_b_cs[2] = 1;
		else if(ioctl_addr < 'h80000)
			gfx_b_cs[3] = 1;
		else if(ioctl_addr < 'h90000)
			sprite_cs[0] = 1;
		else if(ioctl_addr < 'h98000)
			sprite_cs[1] = 1;
		else if(ioctl_addr < 'ha8000)
			sprite_cs[2] = 1;
		else if(ioctl_addr < 'hb0000)
			sprite_cs[3] = 1;
		else if(ioctl_addr < 'hc0000)
			sprite_cs[4] = 1;
		else if(ioctl_addr < 'hc8000)
			sprite_cs[5] = 1;
		else if(ioctl_addr < 'hd8000)
			sprite_cs[6] = 1;
		else if(ioctl_addr < 'he0000)
			sprite_cs[7] = 1;

	end
endmodule

module eprom_64
(
	input logic        clk,
	input logic [15:0] addr,
	output logic [7:0] data,


	input logic        clk_in,
	input logic [15:0] addr_in,
	input logic [7:0]  data_in,
	input logic        cs_in,
	input logic        wr_in
);
	dpramv #(.widthad_a(16)) eprom_64
	(
		.clock_a(clk),
		.address_a(addr),
		.q_a(data),
        .wren_a(0),
        .data_a(),

		.clock_b(clk_in),
		.address_b(addr_in),
		.data_b(data_in),
		.wren_b(wr_in & cs_in),
        .q_b()
	);
endmodule

module eprom_32
(
	input logic        clk,
	input logic [14:0] addr,
	output logic [7:0] data,


	input logic        clk_in,
	input logic [14:0] addr_in,
	input logic [7:0]  data_in,
	input logic        cs_in,
	input logic        wr_in
);
	dpramv #(.widthad_a(15)) eprom_64
	(
		.clock_a(clk),
		.address_a(addr),
		.q_a(data),
        .wren_a(0),
        .data_a(),

		.clock_b(clk_in),
		.address_b(addr_in),
		.data_b(data_in),
		.wren_b(wr_in & cs_in),
        .q_b()
	);
endmodule

module eprom_32_32
(
	input logic        clk,
	input logic [14:0] addr,
	output logic [31:0] data,


	input logic        clk_in,
	input logic [16:0] addr_in,
	input logic [7:0]  data_in,
	input logic        cs_in,
	input logic        wr_in
);
	reg [31:0] buffer;
	reg buffer_wr;

	always @(posedge clk_in) begin
		buffer_wr <= 0;
		if (wr_in & cs_in) begin
			case (addr_in[1:0])
			0: buffer[7:0] <= data_in;
			1: buffer[15:8] <= data_in;
			2: buffer[23:16] <= data_in;
			3: begin
				buffer[31:24] <= data_in;
				buffer_wr <= 1;
			end
			endcase
		end
	end

	dpramv #(.widthad_a(15), .width_a(32)) eprom_32_32
	(
		.clock_a(clk),
		.address_a(addr),
		.q_a(data),
        .wren_a(0),
        .data_a(),

		.clock_b(clk_in),
		.address_b(addr_in[16:2]),
		.data_b(buffer),
		.wren_b(buffer_wr),
        .q_b()
	);
endmodule
