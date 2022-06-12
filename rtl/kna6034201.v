`timescale 1 ns / 1 ns

module kna6034201 (
	input clock,			// Pin 18.
	
	input load_n,			// Pin 17.
	
	input [7:0] par_in_1,	// Pins 8-1.
	input [7:0] par_in_2,	// Pins 16-10.
	input [7:0] par_in_3,	// Pins 32-39.
	
	output ser_out_1,		// Pin 31.
	output ser_out_2,		// Pin 30.
	
	output ser_out_3,		// Pin 29.
	output ser_out_4,		// Pin 28.
	
	output ser_out_5,		// Pin 27.
	output ser_out_6		// Pin 26.
);


reg [7:0] shift_reg_1;	// Eagle - IC1.
reg [7:0] shift_reg_2;	// Eagle - IC2.
reg [7:0] shift_reg_3;	// Eagle - IC3.
reg [7:0] shift_reg_4;	// Eagle - IC4.
reg [7:0] shift_reg_5;	// Eagle - IC5.
reg [7:0] shift_reg_6;	// Eagle - IC6.

always @(posedge clock)
if (!load_n) begin
	shift_reg_1 <= par_in_1;
	shift_reg_2 <= {par_in_1[0],par_in_1[1],par_in_1[2],par_in_1[3],par_in_1[4],par_in_1[5],par_in_1[6],par_in_1[7]};

	shift_reg_3 <= par_in_2;
	shift_reg_4 <= {par_in_2[0],par_in_2[1],par_in_2[2],par_in_2[3],par_in_2[4],par_in_2[5],par_in_2[6],par_in_2[7]};

	shift_reg_5 <= par_in_3;
	shift_reg_6 <= {par_in_2[0],par_in_3[1],par_in_3[2],par_in_3[3],par_in_3[4],par_in_3[5],par_in_3[6],par_in_3[7]};
end
else begin
	shift_reg_1 <= {shift_reg_1[6:0],1'b0};	// Shift out, MSB first.
	shift_reg_2 <= {shift_reg_2[6:0],1'b0};	// Shift out, MSB first.
	
	shift_reg_3 <= {shift_reg_3[6:0],1'b0};	// Shift out, MSB first.
	shift_reg_4 <= {shift_reg_4[6:0],1'b0};	// Shift out, MSB first.
	
	shift_reg_5 <= {shift_reg_5[6:0],1'b0};	// Shift out, MSB first.
	shift_reg_6 <= {shift_reg_6[6:0],1'b0};	// Shift out, MSB first.
end

assign ser_out_1 = shift_reg_1[7];
assign ser_out_2 = shift_reg_2[7];
assign ser_out_3 = shift_reg_3[7];
assign ser_out_4 = shift_reg_4[7];
assign ser_out_5 = shift_reg_5[7];
assign ser_out_6 = shift_reg_6[7];

endmodule
