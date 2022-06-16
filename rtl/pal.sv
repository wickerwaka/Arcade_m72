// http://wiki.pldarchive.co.uk/index.php?title=M72-R-3A

module pal_3a
(
	input logic [19:1] a,
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
    input logic M_IO,
    input logic IOWR,
    input logic IORD,
	input logic [19:1] A,
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
        INTCS = !M_IO & !A[7] & A[6];
	end

endmodule