// http://wiki.pldarchive.co.uk/index.php?title=M72-R-3A

module pal_3a
(
	input logic [19:0] a,
    input logic bank,
    input logic dben,
    input logic m_io,
    input logic [12:0] cod,
	output logic ls245_en, // TODO this signal might be better named
	output logic rom0_ce,
	output logic rom1_ce,
	output logic ram_cs2,
    output logic s,
    output logic n_s
);

	always_comb begin
        ls245_en = ((~dben & m_io & ~a[19] & ~a[18])
                        | (~dben & m_io & ~a[19] & ~a[17])
                        | (~dben & m_io & a[19] & a[18] & a[17] & a[16]));
        rom0_ce = (m_io & ~a[19] & ~a[18] & ~a[17]);
        rom1_ce = ((m_io & ~a[19] & ~a[18] & a[17]) | (m_io & a[19] & a[18] & a[17] & a[16]));
        ram_cs2 = (m_io & ~a[19] & a[18] & ~a[17]);

        s = cod[11];
        n_s = ~cod[11];
	end

endmodule

module pal_4d
(
    input logic IOWR,
    input logic IORD,
	input logic [7:0] A,

	output logic SW,
	output logic FLAG,
	output logic DSW,
	output logic SND,
    output logic FSET,
    output logic DMA_ON,
    output logic ISET,
    output logic INTCS
);

	always_comb begin
        SW = IORD & !A[7] & !A[6] & !A[3] & !A[2] & !A[1];
        FLAG = IORD & !A[7] & !A[6] & !A[3] & !A[2] & A[1];
        DSW = IORD & !A[7] & !A[6] & !A[3] & A[2] & !A[1];
        SND = IOWR & !A[7] & !A[6] & !A[3] & !A[2] & !A[1];
        FSET = IOWR & !A[7] & !A[6] & !A[3] & !A[2] & A[1];
        DMA_ON = IOWR & !A[7] & !A[6] & !A[3] & A[2] & !A[1];
        ISET = IOWR & !A[7] & !A[6] & !A[3] & A[2] & A[1];
        INTCS = (IOWR | IORD) & !A[7] & A[6];
	end

endmodule

module pal_3d
(
	input logic [19:0] A,
    input logic M_IO,
    input logic DBEN,
    input logic TNSL,
    input logic BRQ,

	output logic BUFDBEN,
	output logic BUFCS,
	output logic OBJ_P,
	output logic CHARA_P,
    output logic CHARA,
    output logic SOUND,
    output logic SDBEN
);

	always_comb begin
        BUFDBEN = A[19] & A[18] & !A[17] & !A[16] & !A[15] & !A[14] & M_IO & !DBEN & TNSL;

        BUFCS = TNSL & (!A[19] | !A[18] | A[17] | A[16] | A[15] | A[14] | !M_IO); // TODO unused, neg M_IO is not safe here

        OBJ_P = A[19] & A[18] & !A[17] & !A[16] & A[15] & !A[14] & M_IO;

        CHARA_P = A[19] & A[18] & !A[17] & !A[16] & A[15] & A[14] & M_IO;

        CHARA = A[19] & A[18] & !A[17] & A[16] & M_IO;

        SOUND = A[19] & A[18] & A[17] & !A[16] & M_IO;

        SDBEN = A[19] & A[18] & A[17] & !A[16] & M_IO & !DBEN & BRQ;
    end

endmodule

