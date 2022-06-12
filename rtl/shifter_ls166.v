`timescale 1 ns / 1 ns

module shifter_ls166 (
	input clock,
	
	input load_n,
	
	input [7:0] par_in_1,
	
	output reg ser_out_1,
	output reg ser_out_2
);


reg [7:0] shift_reg_1;
reg [7:0] shift_reg_2;

always @(posedge clock)
if (!load_n) begin
	shift_reg_1 <= par_in_1;
	shift_reg_2 <= {par_in_1[0],par_in_1[1],par_in_1[2],par_in_1[3],par_in_1[4],par_in_1[5],par_in_1[6],par_in_1[7]};
end
else begin
	shift_reg_1 <= {shift_reg_1[6:0],1'b0};	// Shift out, MSB first.
	shift_reg_2 <= {shift_reg_2[6:0],1'b0};	// Shift out, MSB first.
end

assign ser_out_1 = shift_reg_1[7];
assign ser_out_2 = shift_reg_2[7];

endmodule
