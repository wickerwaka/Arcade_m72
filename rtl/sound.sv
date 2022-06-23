module sound (
	input CLK_32M,

	input [15:0] DIN,
	output [15:0] DOUT,
	output DOUT_VALID,
	
	input [19:1] A,
    input [1:0] BYTE_SEL,

    input SDBEN,
    input MRD,
    input MWR
);

wire [7:0] dout_h, dout_l;

assign DOUT = { dout_h, dout_l };
assign DOUT_VALID = MRD & SDBEN;

/*
dpramv #(.widthad_a(15)) ram_h
(
	.clock_a(CLK_32M),
	.address_a(A[15:1]),
	.q_a(dout_h),
	.wren_a(MWR & SDBEN & BYTE_SEL[1]),
	.data_a(DIN[15:8]),

	.clock_b(),
	.address_b(),
	.data_b(),
	.wren_b(0),
	.q_b()
);

dpramv #(.widthad_a(15)) ram_l
(
	.clock_a(CLK_32M),
	.address_a(A[15:1]),
	.q_a(dout_l),
	.wren_a(MWR & SDBEN & BYTE_SEL[0]),
	.data_a(DIN[7:0]),

	.clock_b(),
	.address_b(),
	.data_b(),
	.wren_b(0),
	.q_b()
);
*/

endmodule