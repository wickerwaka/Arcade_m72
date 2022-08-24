
// http://wiki.pldarchive.co.uk/index.php?title=M72-R-3A

import m72_pkg::*;

module pal_3a
(
	input logic [19:0] A,
    
    input board_type_t board_type,

    input logic BANK,
    input logic DBEN,
    input logic M_IO,
    input logic [12:0] COD,
	output logic ls245_en, // TODO this signal might be better named
    output [24:1] sdr_addr,
    output writable,
    output logic S
);

    always_comb begin
        case (board_type)
        M72_RTYPE: begin
            casex (A[19:16])
            4'b010x: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:1] | A[16:1]; end
            4'b00xx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[17:1]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[17:1]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end
        M72_GALLOP: begin
            casex (A[19:16])
            4'b1010: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:1] | A[16:1]; end
            4'b0xxx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[18:1]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[18:1]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end
        M72_DBREED: begin
            casex (A[19:16])
            4'b100x: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:1] | A[16:1]; end
            4'b0xxx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[18:1]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:1] | A[18:1]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end
        endcase

        S = COD[11];
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
	output logic SND2,
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
        SND2 = IOWR & A[7] & A[6] & !A[3] & !A[2] & !A[1];
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

