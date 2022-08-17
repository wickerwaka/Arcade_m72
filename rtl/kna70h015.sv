module kna70h015 (
    input CLK_32M,

    input CE_PIX,

    input [15:0] D,
    input A0,
    input ISET,
    input NL,
    input S24H,
    
    output INT_D,
    output CLD,
    output CPBLK,
    output [8:0] VE,
    output [8:0] V,
    output [9:0] HE,
    output [9:0] H,

    // These are inputs from two PROMs on the original board, but combined into this module here
    output HBLK,
    output VBLK,
    output HINT,

    // Output from PROMs in original board
    output HS,
    output VS,

    input video_50hz
);


assign CLD = h_count == ( S24H ? 10'h33f : 10'h2ff );
assign CPBLK = HBLK | VBLK;
assign VE = V ^ {9{NL}};
assign HE = H ^ {10{NL}};
assign V = v_count;
assign H = h_count;
assign HINT = INT_D && (VE == h_int_line);
assign HBLK = q_ic75[0];
assign HS = ~q_ic75[1];
assign INT_D = q_ic75[2];
assign VBLK = q_ic66[0];
assign VS = ~q_ic66[1];

wire [3:0] q_ic75 = ic75[{S24H, h_count[9:3]}];
wire [3:0] q_ic66 = ic66[{S24H, v_count[8:2]}];


reg [8:0] v_count;
reg [8:0] h_int_line;
reg [9:0] h_count;

/* From MAME
Legend of Hero TONMA
(c)1989 Irem

M72 System
Horizontal Freq. = 15.625KHz
H.Period         = 64.0us (512)
H.Blank          = 16.0us (128)
H.Sync Pulse     = 5.0us (40)
Vertical Freq.   = 55.02Hz
V.Period         = 18.176ms (284)
V.Blank          = 1.792ms (28)
V.Sync Pulse     = 384us (6)

*/

always @(posedge CLK_32M) begin
    if (ISET) begin
        if (A0)
            h_int_line[8] <= D[0];
        else
            h_int_line[7:0] <= D[7:0];
    end

    if (CE_PIX) begin
        h_count <= h_count + 10'd1;
        if (CLD) begin
            h_count <= (S24H ? 10'h0c0 : 10'h100);
            v_count <= v_count + 9'd1;
        end

        if (v_count == (S24H ? 9'h1e1 : 9'h18d)) v_count <= (S24H ? 9'h01e : (video_50hz ? 9'h056 : 9'h072));
    end
end


wire [3:0] ic66[256] = '{
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF,	4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hF, 4'hF, 4'hD, 4'hD, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF,	4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    
    4'hF, 4'hF, 4'hF, 4'hF,	4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE,	4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hF, 4'hF, 4'hF, 4'hF, 4'hD, 4'hD,
    4'hD, 4'hF, 4'hF, 4'hF,	4'hF, 4'hF, 4'hF, 4'hF
};

wire [3:0] ic75[256] = '{
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'h9, 4'h9, 4'hB, 4'hB,
    4'hB, 4'hB, 4'hB, 4'hB, 4'hB, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hF, 4'hF, 4'hF, 4'hF, 4'hD, 4'hD, 4'h9,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'h9, 4'h9, 4'hB, 4'hB,
    4'hB, 4'hB, 4'hB, 4'hB, 4'hB, 4'hB, 4'hB, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA,
    4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hA, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE,
    4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hD, 4'hD, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF,
    4'hF, 4'hF, 4'hF, 4'hF
};


endmodule