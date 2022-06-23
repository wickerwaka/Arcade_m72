module sprite (
	input CLK_32M,
    input CE_PIX,

	input [15:0] DIN,
	output [15:0] DOUT,
	output DOUT_VALID,
	
	input [19:1] A,
    input [1:0] BYTE_SEL,

    input BUFDBEN,
    input MRD,
    input MWR,

    input HBLK,
    input [8:0] VE,
    input NL,

    input DMA_ON,
    output reg TNSL,

    output [7:0] pix_test,

    input sys_clk,
    input ioctl_wr,
	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,

    input [7:0] sprite_cs,

    output [1:0] sdr_wr_sel,
	output [15:0] sdr_din,
	input [15:0] sdr_dout,
	output [24:1] sdr_addr,
	output sdr_req,
	input sdr_ack
);

assign sdr_wr_sel = 2'b00;
assign sdr_din = 0;

wire [7:0] dout_h, dout_l;

assign DOUT = { dout_h, dout_l };
assign DOUT_VALID = MRD & BUFDBEN;

dpramv #(.widthad_a(9)) ram_h
(
	.clock_a(CLK_32M),
	.address_a(A[9:1]),
	.q_a(dout_h),
	.wren_a(MWR & BUFDBEN & BYTE_SEL[1]),
	.data_a(DIN[15:8]),

	.clock_b(CLK_32M),
	.address_b(dma_rd_addr),
	.data_b(),
	.wren_b(0),
	.q_b(dma_h)
);

dpramv #(.widthad_a(9)) ram_l
(
	.clock_a(CLK_32M),
	.address_a(A[9:1]),
	.q_a(dout_l),
	.wren_a(MWR & BUFDBEN & BYTE_SEL[0]),
	.data_a(DIN[7:0]),

	.clock_b(CLK_32M),
	.address_b(dma_rd_addr),
	.data_b(),
	.wren_b(0),
	.q_b(dma_l)
);

dpramv #(.widthad_a(9), .width_a(16)) objram
(
	.clock_a(CLK_32M),
	.address_a(dma_wr_addr),
	.q_a(),
	.wren_a(~TNSL),
	.data_a(dma_word),

	.clock_b(CLK_32M),
	.address_b(obj_addr),
	.data_b(),
	.wren_b(0),
	.q_b(obj_data)
);

reg [7:0] dma_l, dma_h;
wire [15:0] dma_word = { dma_h, dma_l };
reg [9:0] dma_counter;
wire [9:0] dma_rd_addr = dma_counter + 10'd1;
wire [9:0] dma_wr_addr = dma_counter;

always_ff @(posedge CLK_32M) begin
    if (DMA_ON & TNSL) begin
        TNSL <= 0;
        dma_counter <= 10'h3ff;
    end

    if (~TNSL) begin
        dma_counter <= dma_counter + 10'd1;
        if (dma_counter == 10'h1ff) TNSL <= 1;
    end
end

wire S = code[11];

wire [15:0] rom_read_addr64 = { code[10:0], rx, ry[3:0] };
wire [14:0] rom_read_addr32 = { code[9:0], rx, ry[3:0] };
wire [7:0] rom_read_1h, rom_read_1j, rom_read_1k, rom_read_1l, rom_read_3h, rom_read_3j, rom_read_3k, rom_read_3l;

wire [7:0] RD3 = S ? rom_read_1j : rom_read_1h;
wire [7:0] RD2 = RD3; //S ? rom_read_1l : rom_read_1k;
wire [7:0] RD1 = RD3; //S ? rom_read_3j : rom_read_3h;
wire [7:0] RD0 = RD3; //S ? rom_read_3l : rom_read_3k;

reg [15:0] obj_fetch[4];
wire [8:0] obj_addr = obj_cycle[10:2];
wire [15:0] obj_data;
reg [10:0] obj_cycle;

reg [8:0] sy;
reg [15:0] code;
reg [3:0] color;
reg flipx;
reg flipy;
reg [1:0] height;
reg [1:0] width;
reg [9:0] sx;

reg [8:0] ry;
reg rx;
reg [8:0] width_px, height_px;

reg [9:0] sprite_x;
reg [9:0] scan_x;
reg visible;

reg pix_a_valid, pix_b_valid;
reg [7:0] pix_a, pix_b;
wire [7:0] pix_out_v0, pix_out_v1;

line_buffer line_buffer_v0(
    .CLK(CLK_32M),
    .CE_PIX(CE_PIX),
    .WR(~VE[0]),

    .X(~VE[0] ? sprite_x : scan_x),
    
    .DIN0_EN(pix_a_valid),
    .DIN0(pix_a),
    .DIN1_EN(pix_b_valid),
    .DIN1(pix_b),

    .DOUT(pix_out_v0)
);

line_buffer line_buffer_v1(
    .CLK(CLK_32M),
    .CE_PIX(CE_PIX),
    .WR(VE[0]),

    .X(VE[0] ? sprite_x : scan_x),
    
    .DIN0_EN(pix_a_valid),
    .DIN0(pix_a),
    .DIN1_EN(pix_b_valid),
    .DIN1(pix_b),

    .DOUT(pix_out_v1)
);

assign pix_test = VE[0] ? pix_out_v0 : pix_out_v1;

reg old_v0;
reg [31:0] pix_shift;
reg [15:0] obj_code;

always_ff @(posedge CLK_32M) begin
    if (old_v0 != VE[0])
        obj_cycle <= 0;
    else
        obj_cycle <= obj_cycle + 11'd1;
        
    old_v0 <= VE[0];

    if (obj_cycle[1:0] == 2'b10) obj_fetch[obj_cycle[3:2]] <= obj_data;

    pix_a_valid <= 0;
    pix_b_valid <= 0;

    if (obj_cycle[3:0] == 0) begin
        visible <= (ry < height_px) && (obj_code != 0);
        code <= obj_code + ry[8:4];
    end else if (obj_cycle[2:0] == 1) begin
        // wait
    end else if (obj_cycle[2:0] == 2) begin
        pix_shift <= { RD3[0], RD2[0], RD1[0], RD0[0],
                RD3[1], RD2[1], RD1[1], RD0[1],
                RD3[2], RD2[2], RD1[2], RD0[2],
                RD3[3], RD2[3], RD1[3], RD0[3],
                RD3[4], RD2[4], RD1[4], RD0[4],
                RD3[5], RD2[5], RD1[5], RD0[5],
                RD3[6], RD2[6], RD1[6], RD0[6],
                RD3[7], RD2[7], RD1[7], RD0[7] };
        rx <= 1;
    end else if (obj_cycle[2:0] == 3) begin
        pix_a_valid <= visible & |pix_shift[3:0];
        pix_b_valid <= visible & |pix_shift[7:4];
        pix_a <= { color, pix_shift[3:0] };
        pix_b <= { color, pix_shift[7:4] };
        pix_shift <= {8'd0, pix_shift[31:8]};
    end else if (obj_cycle[2:0] < 7) begin
        pix_a_valid <= visible & |pix_shift[3:0];
        pix_b_valid <= visible & |pix_shift[7:4];
        pix_a <= { color, pix_shift[3:0] };
        pix_b <= { color, pix_shift[7:4] };
        pix_shift <= {8'd0, pix_shift[31:8]};
        sprite_x <= sprite_x + 10'd2;
    end


    if (obj_cycle[3:0] == 15) begin
        rx <= 0;
        if (width_px == 0) begin
            sy <= 512 - obj_fetch[0][8:0];
            ry <= VE - obj_fetch[0][8:0];
            obj_code <= obj_fetch[1];
            color <= obj_fetch[2][3:0];
            flipy <= obj_fetch[2][10];
            flipx <= obj_fetch[2][11];
            height <= obj_fetch[2][13:12];
            width <= obj_fetch[2][15:14];
            width_px <= (16 << obj_fetch[2][15:14]) - 16;
            height_px <= 16 << obj_fetch[2][13:12];
            sprite_x <= obj_fetch[3][9:0];
        end else begin
            width_px <= width_px - 9'd16;
            obj_code <= obj_code + 8;
            sprite_x <= sprite_x + 10'd2;
        end
    end
end

always_ff @(posedge CLK_32M) begin
    if (CE_PIX) begin
        scan_x <= scan_x + 1;
        if (HBLK) scan_x <= 256;
    end
end

/*
reg cached_code = 0;
reg cached_width = 0;
reg fetched_width = 0;
reg [31:0] cached_words[2 * 16];

always_ff @(posedge CLK_32M) begin
    if (code != cached_code ||)
    if (sdr_ack != sdr_req) begin
    end
*/



eprom_64 rom_1h(
	.clk(CLK_32M),
	.addr(rom_read_addr64),
	.data(rom_read_1h),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[15:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[0])
);


eprom_32 rom_1j(
	.clk(CLK_32M),
	.addr(rom_read_addr32),
	.data(rom_read_1j),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[1])
);

/*eprom_64 rom_1k(
	.clk(CLK_32M),
	.addr(rom_read_addr64),
	.data(rom_read_1k),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[15:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[2])
);*/

/*
eprom_32 rom_1l(
	.clk(CLK_32M),
	.addr(rom_read_addr32),
	.data(rom_read_1l),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[3])
);*/

/*eprom_64 rom_3h(
	.clk(CLK_32M),
	.addr(rom_read_addr64),
	.data(rom_read_3h),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[15:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[4])
);*/

/*eprom_32 rom_3j(
	.clk(CLK_32M),
	.addr(rom_read_addr32),
	.data(rom_read_3j),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[5])
);*/
/*
eprom_64 rom_3k(
	.clk(CLK_32M),
	.addr(rom_read_addr64),
	.data(rom_read_3k),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[15:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[6])
);*/

/*
eprom_32 rom_3l(
	.clk(CLK_32M),
	.addr(rom_read_addr32),
	.data(rom_read_3l),

	.clk_in(sys_clk),
	.addr_in(ioctl_addr[14:0]),
	.data_in(ioctl_dout),
	.wr_in(ioctl_wr),
	.cs_in(sprite_cs[7])
);*/


endmodule

module line_buffer(
    input CLK,
    input CE_PIX,
    input WR,

    input [9:0] X,
    
    input DIN0_EN,
    input DIN1_EN,
    input [7:0] DIN0,
    input [7:0] DIN1,

    output reg [7:0] DOUT
);

reg [7:0] odd[512];
reg [7:0] even[512];

wire [9:0] next_x = X + 10'd1;
wire [9:0] prev_x = X - 10'd1;

always_ff @(posedge CLK) begin
    if (WR) begin
        if (X[0]) begin
            if (DIN0_EN) odd[X[9:1]] <= DIN0;
            if (DIN1_EN) even[next_x[9:1]] <= DIN1;
        end else begin
            if (DIN0_EN) even[X[9:1]] <= DIN0;
            if (DIN1_EN) odd[next_x[9:1]] <= DIN1;
        end
    end else if (CE_PIX) begin
        if (X[0]) begin
            DOUT <= odd[X[9:1]];
            even[prev_x[9:1]] <= 8'd0;
        end else begin
            DOUT <= even[X[9:1]];
            odd[prev_x[9:1]] <= 8'd0;
        end
    end
end

endmodule
