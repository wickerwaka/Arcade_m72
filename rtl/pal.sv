// http://wiki.pldarchive.co.uk/index.php?title=M72-R-3A

module pal_3a
(
	input logic [19:1] a,
    input logic bank,
    input logic dben,
    input logic m_io,
    input logic [12:0] cod,
	output logic ls245_en,
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