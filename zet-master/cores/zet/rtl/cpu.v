// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      cpu.v
// Description: Wishbone based CPU (80186 compatible)
// --------------------------------------------------------------------
// --------------------------------------------------------------------
`timescale 1ns/10ps
`define IR_SIZE 36
`define MEM_OP  31
`define ADD_IP `IR_SIZE'bx__0__1__0__1__10_001_001__0__01__0__0_1111_xxxx_xxxx_1111_xx
`define OP_NOP 8'h90
`define DEBUG         0
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:      Instruction Set
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
`define MICRO_DATA_WIDTH 49
`define MICRO_ADDR_WIDTH 10
`define SEQ_DATA_WIDTH 10
`define SEQ_ADDR_WIDTH 10
// --------------------------------------------------------------------
`define MOVRRB	10'b0000000000
`define MOVRRW	10'b0000000001
`define MOVRMB	10'b0000000010
`define MOVRMW	10'b0000000011
`define MOVAMB	10'b0000000100
`define MOVAMW	10'b0000000101
`define MOVMRB	10'b0000000110
`define MOVMRW	10'b0000000111
`define MOVMAB	10'b0000001000
`define MOVMAW	10'b0000001001
`define MOVIRB	10'b0000001010
`define MOVIRW	10'b0000001011
`define MOVIMB	10'b0000001100
`define MOVIMW	10'b0000001110
`define PUSHR	10'b0000010000
`define PUSHM	10'b0000010011
`define PUSHI	10'b0000010110
`define LEAVE	10'b0000011001
`define ENTER	10'b0000011100
`define POPR	10'b0000100000
`define POPM	10'b0000100011
`define INIB	10'b0000100110
`define INIW	10'b0000100111
`define INRB	10'b0000101000
`define INRW	10'b0000101001
`define OUTIB	10'b0000101010
`define OUTIW	10'b0000101011
`define OUTRB	10'b0000101100
`define OUTRW	10'b0000101101
`define LAHF	10'b0000101110
`define SAHF	10'b0000101111
`define LDS	10'b0000110000
`define LEA	10'b0000110011
`define LES	10'b0000110100
`define PUSHF	10'b0000110111
`define POPF	10'b0000111010
`define XCHRRB	10'b0000111101
`define XCHRRW	10'b0001000000
`define XCHRMB	10'b0001000011
`define XCHRMW	10'b0001000110
`define XLAT	10'b0001001001
`define AAA	10'b0001001011
`define AAS	10'b0001001100
`define AAM	10'b0001001101
`define AAD	10'b0001100010
`define DAA	10'b0001100111
`define DAS	10'b0001101000
`define CBW	10'b0001101001
`define CWD	10'b0001101010
`define INCRB	10'b0001101011
`define INCRW	10'b0001101100
`define INCMB	10'b0001101101
`define INCMW	10'b0001110000
`define DECRB	10'b0001110011
`define DECRW	10'b0001110100
`define DECMB	10'b0001110101
`define DECMW	10'b0001111000
`define ADDRRB	10'b0001111011
`define ADDRRW	10'b0001111100
`define ADDRMB	10'b0001111101
`define ADDRMW	10'b0010000000
`define ADDMRB	10'b0010000011
`define ADDMRW	10'b0010000101
`define ADDIRB	10'b0010000111
`define ADDIRW	10'b0010001000
`define ADDIMB	10'b0010001001
`define ADDIMW	10'b0010001100
`define ADCRRB	10'b0010001111
`define ADCRRW	10'b0010010000
`define ADCRMB	10'b0010010001
`define ADCRMW	10'b0010010100
`define ADCMRB	10'b0010010111
`define ADCMRW	10'b0010011001
`define ADCIRB	10'b0010011011
`define ADCIRW	10'b0010011100
`define ADCIMB	10'b0010011101
`define ADCIMW	10'b0010100000
`define SUBRRB	10'b0010100011
`define SUBRRW	10'b0010100100
`define SUBRMB	10'b0010100101
`define SUBRMW	10'b0010101000
`define SUBMRB	10'b0010101011
`define SUBMRW	10'b0010101101
`define SUBIRB	10'b0010101111
`define SUBIRW	10'b0010110000
`define SUBIMB	10'b0010110001
`define SUBIMW	10'b0010110100
`define SBBRRB	10'b0010110111
`define SBBRRW	10'b0010111000
`define SBBRMB	10'b0010111001
`define SBBRMW	10'b0010111100
`define SBBMRB	10'b0010111111
`define SBBMRW	10'b0011000001
`define SBBIRB	10'b0011000011
`define SBBIRW	10'b0011000100
`define SBBIMB	10'b0011000101
`define SBBIMW	10'b0011001000
`define MULRB	10'b0011001011
`define MULRW	10'b0011001110
`define MULMB	10'b0011010001
`define MULMW	10'b0011010101
`define IMULRB	10'b0011011001
`define IMULRW	10'b0011011100
`define IMULMB	10'b0011011111
`define IMULMW	10'b0011100011
`define IMULIR	10'b0011100111
`define IMULIM	10'b0011101010
`define DIVRB	10'b0011101110
`define DIVRW	10'b0100000011
`define DIVMB	10'b0100011000
`define DIVMW	10'b0100101110
`define IDIVRB	10'b0101000100
`define IDIVRW	10'b0101011001
`define IDIVMB	10'b0101101110
`define IDIVMW	10'b0110000100
`define NEGRB	10'b0110011010
`define NEGRW	10'b0110011011
`define NEGMB	10'b0110011100
`define NEGMW	10'b0110011111
`define CMPRRB	10'b0110100010
`define CMPRRW	10'b0110100011
`define CMPRMB	10'b0110100100
`define CMPRMW	10'b0110100110
`define CMPMRB	10'b0110101000
`define CMPMRW	10'b0110101010
`define CMPIRB	10'b0110101100
`define CMPIRW	10'b0110101101
`define CMPIMB	10'b0110101110
`define CMPIMW	10'b0110110000
`define ANDRRB	10'b0110110010
`define ANDRRW	10'b0110110011
`define ANDRMB	10'b0110110100
`define ANDRMW	10'b0110110111
`define ANDMRB	10'b0110111010
`define ANDMRW	10'b0110111100
`define ANDIRB	10'b0110111110
`define ANDIRW	10'b0110111111
`define ANDIMB	10'b0111000000
`define ANDIMW	10'b0111000011
`define ORRRB	10'b0111000110
`define ORRRW	10'b0111000111
`define ORRMB	10'b0111001000
`define ORRMW	10'b0111001011
`define ORMRB	10'b0111001110
`define ORMRW	10'b0111010000
`define ORIRB	10'b0111010010
`define ORIRW	10'b0111010011
`define ORIMB	10'b0111010100
`define ORIMW	10'b0111010111
`define NOTRB	10'b0111011010
`define NOTRW	10'b0111011011
`define NOTMB	10'b0111011100
`define NOTMW	10'b0111011111
`define RCL1RB	10'b0111100010
`define RCL1RW	10'b0111100011
`define RCLCRB	10'b0111100100
`define RCLCRW	10'b0111100101
`define RCL1MB	10'b0111100110
`define RCL1MW	10'b0111101001
`define RCLCMB	10'b0111101100
`define RCLCMW	10'b0111101111
`define RCLIRB	10'b0111110010
`define RCLIRW	10'b0111110011
`define RCLIMB	10'b0111110100
`define RCLIMW	10'b0111110111
`define RCR1RB	10'b0111111010
`define RCR1RW	10'b0111111011
`define RCRCRB	10'b0111111100
`define RCRCRW	10'b0111111101
`define RCR1MB	10'b0111111110
`define RCR1MW	10'b1000000001
`define RCRCMB	10'b1000000100
`define RCRCMW	10'b1000000111
`define RCRIRB	10'b1000001010
`define RCRIRW	10'b1000001011
`define RCRIMB	10'b1000001100
`define RCRIMW	10'b1000001111
`define ROL1RB	10'b1000010010
`define ROL1RW	10'b1000010011
`define ROLCRB	10'b1000010100
`define ROLCRW	10'b1000010101
`define ROL1MB	10'b1000010110
`define ROL1MW	10'b1000011001
`define ROLCMB	10'b1000011100
`define ROLCMW	10'b1000011111
`define ROLIRB	10'b1000100010
`define ROLIRW	10'b1000100011
`define ROLIMB	10'b1000100100
`define ROLIMW	10'b1000100111
`define ROR1RB	10'b1000101010
`define ROR1RW	10'b1000101011
`define RORCRB	10'b1000101100
`define RORCRW	10'b1000101101
`define ROR1MB	10'b1000101110
`define ROR1MW	10'b1000110001
`define RORCMB	10'b1000110100
`define RORCMW	10'b1000110111
`define RORIRB	10'b1000111010
`define RORIRW	10'b1000111011
`define RORIMB	10'b1000111100
`define RORIMW	10'b1000111111
`define SAL1RB	10'b1001000010
`define SAL1RW	10'b1001000011
`define SALCRB	10'b1001000100
`define SALCRW	10'b1001000101
`define SAL1MB	10'b1001000110
`define SAL1MW	10'b1001001001
`define SALCMB	10'b1001001100
`define SALCMW	10'b1001001111
`define SALIRB	10'b1001010010
`define SALIRW	10'b1001010011
`define SALIMB	10'b1001010100
`define SALIMW	10'b1001010111
`define SAR1RB	10'b1001011010
`define SAR1RW	10'b1001011011
`define SARCRB	10'b1001011100
`define SARCRW	10'b1001011101
`define SAR1MB	10'b1001011110
`define SAR1MW	10'b1001100001
`define SARCMB	10'b1001100100
`define SARCMW	10'b1001100111
`define SARIRB	10'b1001101010
`define SARIRW	10'b1001101011
`define SARIMB	10'b1001101100
`define SARIMW	10'b1001101111
`define SHR1RB	10'b1001110010
`define SHR1RW	10'b1001110011
`define SHRCRB	10'b1001110100
`define SHRCRW	10'b1001110101
`define SHR1MB	10'b1001110110
`define SHR1MW	10'b1001111001
`define SHRCMB	10'b1001111100
`define SHRCMW	10'b1001111111
`define SHRIRB	10'b1010000010
`define SHRIRW	10'b1010000011
`define SHRIMB	10'b1010000100
`define SHRIMW	10'b1010000111
`define TSTRRB	10'b1010001010
`define TSTRRW	10'b1010001011
`define TSTMRB	10'b1010001100
`define TSTMRW	10'b1010001110
`define TSTIRB	10'b1010010000
`define TSTIRW	10'b1010010001
`define TSTIMB	10'b1010010010
`define TSTIMW	10'b1010010100
`define XORRRB	10'b1010010110
`define XORRRW	10'b1010010111
`define XORRMB	10'b1010011000
`define XORRMW	10'b1010011011
`define XORMRB	10'b1010011110
`define XORMRW	10'b1010100000
`define XORIRB	10'b1010100010
`define XORIRW	10'b1010100011
`define XORIMB	10'b1010100100
`define XORIMW	10'b1010100111
`define CALLN	10'b1010101010
`define CALLNR	10'b1010101101
`define CALLNM	10'b1010110001
`define CALLF	10'b1010110101
`define CALLFM	10'b1010111010
`define JCC	10'b1011000000
`define JCXZ	10'b1011000001
`define JMPI	10'b1011000010
`define JMPR	10'b1011000011
`define JMPM	10'b1011000100
`define LJMPI	10'b1011000101
`define LJMPM	10'b1011000111
`define LOOP	10'b1011001001
`define LOOPE	10'b1011001011
`define LOOPNE	10'b1011001101
`define RETN0	10'b1011001111
`define RETNV	10'b1011010001
`define RETF0	10'b1011010100
`define RETFV	10'b1011011000
`define CMPSB	10'b1011011101
`define CMPSW	10'b1011100011
`define CMPSBR	10'b1011101001
`define CMPSWR	10'b1011110000
`define LODSB	10'b1011110111
`define LODSW	10'b1011111001
`define LODSBR	10'b1011111011
`define LODSWR	10'b1011111110
`define MOVSB	10'b1100000001
`define MOVSW	10'b1100000101
`define MOVSBR	10'b1100001001
`define MOVSWR	10'b1100001110
`define SCASB	10'b1100010011
`define SCASW	10'b1100010110
`define SCASBR	10'b1100011001
`define SCASWR	10'b1100011101
`define STOSB	10'b1100100001
`define STOSW	10'b1100100011
`define STOSBR	10'b1100100101
`define STOSWR	10'b1100101000
`define INT3	10'b1100101011
`define INT	10'b1100110110
`define INTD	10'b1101000001
`define EINT	10'b1101001010
`define EINTP	10'b1101010101
`define INTO	10'b1101100000
`define IRET	10'b1101101100
`define NOP	10'b1101110011
`define CLC	10'b1101110100
`define CLD	10'b1101110101
`define CLI	10'b1101110110
`define CMC	10'b1101110111
`define HLT	10'b1101111000
`define STC	10'b1101111001
`define STD	10'b1101111010
`define STI	10'b1101111011
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      cpu.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module cpu (
`ifdef DEBUG
    output [15:0] cs,
    output [15:0] ip,
    output [ 2:0] state,
    output [ 2:0] next_state,
    output [ 5:0] iralu,
    output [15:0] x,
    output [15:0] y,
    output [15:0] imm,
    output [15:0] aluo,
    output [15:0] ax,
    output [15:0] dx,
    output [15:0] bp,
    output [15:0] si,
    output [15:0] es,
    input         dbg_block,
    output [15:0] c,
    output [ 3:0] addr_c,
    output [ 3:0] addr_a,
    output [15:0] cpu_dat_o,
    output [15:0] d,
    output [ 3:0] addr_d,
    output        byte_exec,
    output [ 8:0] flags,
    output        end_seq,
    output        ext_int,
    output        cpu_block,
    output [19:0] cpu_adr_o,
    output [`SEQ_DATA_WIDTH-2:0] micro_addr,
`endif

    // Wishbone master interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    output [19:1] wb_adr_o,
    output        wb_we_o,
    output        wb_tga_o,  // io/mem
    output [ 1:0] wb_sel_o,
    output        wb_stb_o,
    output        wb_cyc_o,
    input         wb_ack_i,
    input         wb_tgc_i,  // intr
    output        wb_tgc_o   // inta
  );

  // Net declarations
`ifndef DEBUG
  wire [15:0] cs, ip;
  wire [15:0] imm;
  wire [15:0] cpu_dat_o;
  wire        byte_exec;
  wire        cpu_block;
  wire [19:0] cpu_adr_o;
`endif
  wire [`IR_SIZE-1:0] ir;
  wire [15:0] off;

  wire [19:0] addr_exec, addr_fetch;
  wire byte_fetch, fetch_or_exec;
  wire of, zf, cx_zero;
  wire div_exc;
  wire wr_ip0;
  wire ifl;

  wire        cpu_byte_o;
  wire        cpu_m_io;
  wire        wb_block;
  wire [15:0] cpu_dat_i;
  wire        cpu_we_o;
  wire [15:0] iid_dat_i;

  // Module instantiations
  fetch fetch0 (
`ifdef DEBUG
    .state      (state),
    .next_state (next_state),
    .ext_int    (ext_int),
    .end_seq    (end_seq),
    .micro_addr (micro_addr),
`endif
    .clk  (wb_clk_i),
    .rst  (wb_rst_i),
    .cs   (cs),
    .ip   (ip),
    .of   (of),
    .zf   (zf),
    .data (cpu_dat_i),
    .ir   (ir),
    .off  (off),
    .imm  (imm),
    .pc   (addr_fetch),

    .cx_zero       (cx_zero),
    .bytefetch     (byte_fetch),
    .fetch_or_exec (fetch_or_exec),
    .block         (cpu_block),
    .div_exc       (div_exc),

    .wr_ip0  (wr_ip0),

    .intr (wb_tgc_i),
    .ifl  (ifl),
    .inta (wb_tgc_o)
  );

  exec exec0 (
`ifdef DEBUG
    .x    (x),
    .y    (y),
    .aluo (aluo),
    .ax   (ax),
    .dx   (dx),
    .bp   (bp),
    .si   (si),
    .es   (es),
    .c    (c),
    .addr_c (addr_c),
    .addr_a (addr_a),
    .omemalu (d),
    .addr_d (addr_d),
    .flags  (flags),
`endif
    .ir      (ir),
    .off     (off),
    .imm     (imm),
    .cs      (cs),
    .ip      (ip),
    .of      (of),
    .zf      (zf),
    .cx_zero (cx_zero),
    .clk     (wb_clk_i),
    .rst     (wb_rst_i),
    .memout  (iid_dat_i),
    .wr_data (cpu_dat_o),
    .addr    (addr_exec),
    .we      (cpu_we_o),
    .m_io    (cpu_m_io),
    .byteop  (byte_exec),
    .block   (cpu_block),
    .div_exc (div_exc),
    .wrip0   (wr_ip0),

    .ifl     (ifl)
  );

  wb_master wm0 (
    .cpu_byte_o (cpu_byte_o),
    .cpu_memop  (ir[`MEM_OP]),
    .cpu_m_io   (cpu_m_io),
    .cpu_adr_o  (cpu_adr_o),
    .cpu_block  (wb_block),
    .cpu_dat_i  (cpu_dat_i),
    .cpu_dat_o  (cpu_dat_o),
    .cpu_we_o   (cpu_we_o),

    .wb_clk_i  (wb_clk_i),
    .wb_rst_i  (wb_rst_i),
    .wb_dat_i  (wb_dat_i),
    .wb_dat_o  (wb_dat_o),
    .wb_adr_o  (wb_adr_o),
    .wb_we_o   (wb_we_o),
    .wb_tga_o  (wb_tga_o),
    .wb_sel_o  (wb_sel_o),
    .wb_stb_o  (wb_stb_o),
    .wb_cyc_o  (wb_cyc_o),
    .wb_ack_i  (wb_ack_i)
  );

  // Assignments
  assign cpu_adr_o  = fetch_or_exec ? addr_exec : addr_fetch;
  assign cpu_byte_o = fetch_or_exec ? byte_exec : byte_fetch;
  assign iid_dat_i  = wb_tgc_o ? wb_dat_i : cpu_dat_i;

`ifdef DEBUG
  assign iralu = ir[28:23];
  assign cpu_block = wb_block | dbg_block;
`else
  assign cpu_block = wb_block;
`endif
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Wishbone Master Interface
// --------------------------------------------------------------------
module wb_master (
    input             cpu_byte_o,
    input             cpu_memop,
    input             cpu_m_io,
    input      [19:0] cpu_adr_o,
    output reg        cpu_block,
    output reg [15:0] cpu_dat_i,
    input      [15:0] cpu_dat_o,
    input             cpu_we_o,

    input             wb_clk_i,
    input             wb_rst_i,
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    output reg [19:1] wb_adr_o,
    output            wb_we_o,
    output            wb_tga_o,
    output reg [ 1:0] wb_sel_o,
    output reg        wb_stb_o,
    output            wb_cyc_o,
    input             wb_ack_i
  );

  // Register and nets declarations
  reg  [ 1:0] cs; // current state
  reg  [ 1:0] ns; // next state
  reg  [19:1] adr1; // next address (for unaligned acc)

  wire        op; // in an operation
  wire        odd_word; // unaligned word
  wire        a0;  // address 0 pin
  wire [15:0] blw; // low byte (sign extended)
  wire [15:0] bhw; // high byte (sign extended)
  wire [ 1:0] sel_o; // bus byte select

  // Declare the symbolic names for states
  localparam [1:0]
    IDLE    = 2'd0,
    stb1_hi = 2'd1,
    stb2_hi = 2'd2,
    bloc_lo = 2'd3;

  // Assignments
  assign op        = (cpu_memop | cpu_m_io);
  assign odd_word  = (cpu_adr_o[0] & !cpu_byte_o);
  assign a0        = cpu_adr_o[0];
  assign blw       = { {8{wb_dat_i[7]}}, wb_dat_i[7:0] };
  assign bhw       = { {8{wb_dat_i[15]}}, wb_dat_i[15:8] };
  assign wb_we_o   = cpu_we_o;
  assign wb_tga_o  = cpu_m_io;
  assign sel_o     = a0 ? 2'b10 : (cpu_byte_o ? 2'b01 : 2'b11);
  assign wb_cyc_o  = wb_stb_o;

  // Behaviour
  // cpu_dat_i
  always @(posedge wb_clk_i)
    cpu_dat_i <= (cs == stb1_hi) ? (wb_ack_i ? (a0 ? bhw : (cpu_byte_o ? blw : wb_dat_i))
                   : cpu_dat_i) : ((cs == stb2_hi && wb_ack_i) ? { wb_dat_i[7:0], cpu_dat_i[7:0] } : cpu_dat_i);
  
  always @(posedge wb_clk_i) adr1 <= cpu_adr_o[19:1] + 1'b1;		// adr1
  always @(posedge wb_clk_i) wb_adr_o <= (ns==stb2_hi) ? adr1 : cpu_adr_o[19:1];		  // wb_adr_o
  always @(posedge wb_clk_i) wb_sel_o <= (ns==stb1_hi) ? sel_o : 2'b01;			  // wb_sel_o
  always @(posedge wb_clk_i) wb_stb_o <= (ns==stb1_hi || ns==stb2_hi);			  // wb_stb_o
  always @(posedge wb_clk_i) wb_dat_o <= a0 ? { cpu_dat_o[7:0], cpu_dat_o[15:8] } : cpu_dat_o;		  // wb_dat_o

  always @(*)		  // cpu_block
    case (cs)
      IDLE:    cpu_block <= op;
      default: cpu_block <= 1'b1;
      bloc_lo: cpu_block <= wb_ack_i;
    endcase

  // state machine - cs - current state
  always @(posedge wb_clk_i) cs <= wb_rst_i ? IDLE : ns;

  // ns - next state
  always @(*)
    case (cs)
      default: ns <= wb_ack_i ? IDLE : (op ? stb1_hi : IDLE);
      stb1_hi: ns <= wb_ack_i ? (odd_word ? stb2_hi : bloc_lo) : stb1_hi;
      stb2_hi: ns <= wb_ack_i ? bloc_lo : stb2_hi;
      bloc_lo: ns <= wb_ack_i ? bloc_lo : IDLE;
    endcase

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:      exec.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module exec (
`ifdef DEBUG
    output [15:0] x,
    output [15:0] y,
    output [15:0] aluo,
    output [15:0] ax,
    output [15:0] dx,
    output [15:0] bp,
    output [15:0] si,
    output [15:0] es,
    output [15:0] c,
    output [ 3:0] addr_a,
    output [ 3:0] addr_c,
    output [15:0] omemalu,
    output [ 3:0] addr_d,
    output [ 8:0] flags,
`endif
    input [`IR_SIZE-1:0] ir,
    input [15:0]  off,
    input [15:0]  imm,
    output [15:0] cs,
    output [15:0] ip,
    output        of,
    output        zf,
    output        cx_zero,
    input         clk,
    input         rst,
    input [15:0]  memout,

    output [15:0] wr_data,
    output [19:0] addr,
    output        we,
    output        m_io,
    output        byteop,
    input         block,
    output        div_exc,
    input         wrip0,

    output        ifl
  );

  // Net declarations
`ifndef DEBUG
  wire [15:0] c;
  wire [15:0] omemalu;
  wire [ 3:0] addr_a;
  wire [ 3:0] addr_c;
  wire [ 3:0] addr_d;
  wire  [8:0] flags;
`endif
  wire [15:0] a, b, s, alu_iflags, bus_b;
  wire [31:0] aluout;
  wire [3:0]  addr_b;
  wire [2:0]  t, func;
  wire [1:0]  addr_s;
  wire        wrfl, high, memalu, r_byte, c_byte;
  wire        wr, wr_reg;
  wire        wr_cnd;
  wire        jmp;
  wire        b_imm;
  wire  [8:0] iflags, oflags;
  wire  [4:0] logic_flags;
  wire        alu_word;
  wire        a_byte;
  wire        b_byte;
  wire        wr_high;
  wire        dive;

  // Module instances
  alu     alu0( {c, a }, bus_b, aluout, t, func, alu_iflags, oflags,
               alu_word, s, off, clk, dive);
  regfile reg0 (
`ifdef DEBUG
    ax, dx, bp, si, es,
`endif
    a, b, c, cs, ip, {aluout[31:16], omemalu}, s, flags, wr_reg, wrfl,
                wr_high, clk, rst, addr_a, addr_b, addr_c, addr_d, addr_s, iflags,
                ~byteop, a_byte, b_byte, c_byte, cx_zero, wrip0);
  jmp_cond jc0( logic_flags, addr_b, addr_c[0], c, jmp);

  // Assignments
  assign addr_s = ir[1:0];
  assign addr_a = ir[5:2];
  assign addr_b = ir[9:6];
  assign addr_c = ir[13:10];
  assign addr_d = ir[17:14];
  assign wrfl   = ir[18];
  assign we     = ir[19];
  assign wr     = ir[20];
  assign wr_cnd = ir[21];
  assign high   = ir[22];
  assign t      = ir[25:23];
  assign func   = ir[28:26];
  assign byteop = ir[29];
  assign memalu = ir[30];
  assign m_io   = ir[32];
  assign b_imm  = ir[33];
  assign r_byte = ir[34];
  assign c_byte = ir[35];

  assign omemalu = memalu ? aluout[15:0] : memout;
  assign bus_b   = b_imm ? imm : b;

  assign addr = aluout[19:0];
  assign wr_data = c;
  assign wr_reg  = (wr | (jmp & wr_cnd)) && !block && !div_exc;
  assign wr_high = high && !block && !div_exc;
  assign of  = flags[8];
  assign ifl = flags[6];
  assign zf  = flags[3];

  assign iflags = oflags;
  assign alu_iflags = { 4'b0, flags[8:3], 1'b0, flags[2], 1'b0, flags[1],
                        1'b1, flags[0] };
  assign logic_flags = { flags[8], flags[4], flags[3], flags[1], flags[0] };

  assign alu_word = (t==3'b011) ? ~r_byte : ~byteop;
  assign a_byte = (t==3'b011 && func[1]) ? 1'b0 : r_byte;
  assign b_byte = r_byte;
  assign div_exc = dive && wr;

`ifdef DEBUG
  assign x        = a;
  assign y        = bus_b;
  assign aluo     = aluout[15:0];
`endif

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Fetch Module
// --------------------------------------------------------------------
module fetch (
`ifdef DEBUG
    output reg [2:0] state,
    output [2:0] next_state,
    output       ext_int,
    output       end_seq,

    output [`SEQ_DATA_WIDTH-2:0] micro_addr,
`endif
    input clk,
    input rst,
    input [15:0] cs,
    input [15:0] ip,
    input of,
    input zf,
    input cx_zero,
    input [15:0] data,
    output [`IR_SIZE-1:0] ir,
    output [15:0] off,
    output [15:0] imm,
    output [19:0] pc,
    output bytefetch,
    output fetch_or_exec,
    input  block,
    input  div_exc,
    output wr_ip0,
    input  intr,
    input  ifl,
    output inta
  );

  // Registers, nets and parameters
  parameter opcod_st = 3'h0;
  parameter modrm_st = 3'h1;
  parameter offse_st = 3'h2;
  parameter immed_st = 3'h3;
  parameter execu_st = 3'h4;

`ifndef DEBUG
  reg  [2:0] state;
  wire [2:0] next_state;
  wire       end_seq;
  wire       ext_int;
`endif

  wire [`IR_SIZE-1:0] rom_ir;
  wire [7:0] opcode, modrm;
  wire exec_st;
  wire [15:0] imm_d;
  wire prefix, repz_pr, sovr_pr;
  wire next_in_opco, next_in_exec;
  wire need_modrm, need_off, need_imm, off_size, imm_size;
  wire ld_base;

  reg [7:0] opcode_l, modrm_l;
  reg [15:0] off_l, imm_l;
  reg [1:0] pref_l;
  reg [2:0] sop_l;

  // Module instantiation
  decode decode0(
`ifdef DEBUG
                 micro_addr,
`endif
                 opcode, modrm, off_l, imm_l, pref_l[1], clk, rst, block,
                 exec_st, div_exc, need_modrm, need_off, need_imm, off_size,
                 imm_size, rom_ir, off, imm_d, ld_base, end_seq, sop_l,
                 intr, ifl, inta, ext_int, pref_l[1]);
  next_or_not nn0(pref_l, opcode[7:1], cx_zero, zf, ext_int, next_in_opco,
                  next_in_exec);
  nstate ns0(state, prefix, need_modrm, need_off, need_imm, end_seq,
             rom_ir[28:23], of, next_in_opco, next_in_exec, block, div_exc,
             intr, ifl, next_state);

  // Assignments
  assign pc = (cs << 4) + ip;

  assign ir     = (state == execu_st) ? rom_ir : `ADD_IP;
  assign opcode = (state == opcod_st) ? data[7:0] : opcode_l;
  assign modrm  = (state == modrm_st) ? data[7:0] : modrm_l;
  assign fetch_or_exec = (state == execu_st);
  assign bytefetch = (state == offse_st) ? ~off_size
                   : ((state == immed_st) ? ~imm_size : 1'b1);
  assign exec_st = (state == execu_st);
  assign imm = (state == execu_st) ? imm_d
              : (((state == offse_st) & off_size
                | (state == immed_st) & imm_size) ? 16'd2
              : 16'd1);
  assign wr_ip0 = (state == opcod_st) && !pref_l[1] && !sop_l[2];

  assign sovr_pr = (opcode[7:5]==3'b001 && opcode[2:0]==3'b110);
  assign repz_pr = (opcode[7:1]==7'b1111_001);
  assign prefix  = sovr_pr || repz_pr;
  assign ld_base = (next_state == execu_st);

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        state <= execu_st;
        opcode_l <= `OP_NOP;
      end
    else if (!block)
      case (next_state)
        default:  // opcode or prefix
          begin
            case (state)
              opcod_st:
                begin // There has been a prefix
                  pref_l <= repz_pr ? { 1'b1, opcode[0] } : pref_l;
                  sop_l  <= sovr_pr ? { 1'b1, opcode[4:3] } : sop_l;
                end
              default: begin pref_l <= 2'b0; sop_l <= 3'b0; end
            endcase
            state <= opcod_st;
            off_l <= 16'd0;
            modrm_l <= 8'b0000_0110;
          end

        modrm_st:  // modrm
          begin
            opcode_l  <= data[7:0];
            state <= modrm_st;
          end

        offse_st:  // offset
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              default: modrm_l <= data[7:0];
            endcase
            state <= offse_st;
          end

        immed_st:  // immediate
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              default: off_l <= data;
            endcase
            state <= immed_st;
          end

        execu_st:  // execute
          begin
            case (state)
              opcod_st: opcode_l <= data[7:0];
              modrm_st: modrm_l <= data[7:0];
              offse_st: off_l <= data;
              immed_st: imm_l <= data;
            endcase
            state <= execu_st;
          end
      endcase
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Next State machine
// --------------------------------------------------------------------
module nstate (
    input [2:0] state,
    input prefix,
    input need_modrm,
    input need_off,
    input need_imm,
    input end_seq,
    input [5:0] ftype,
    input of,
    input next_in_opco,
    input next_in_exec,
    input block,
    input div_exc,
    input intr,
    input ifl,
    output [2:0] next_state
  );

  // Net declarations
  parameter opcod_st = 3'h0;
  parameter modrm_st = 3'h1;
  parameter offse_st = 3'h2;
  parameter immed_st = 3'h3;
  parameter execu_st = 3'h4;
  wire into, end_instr, end_into;
  wire [2:0] n_state;
  wire       intr_ifl;

  // Assignments
  assign into = (ftype==6'b111_010);
  assign end_into = into ? ~of : end_seq;
  assign end_instr = !div_exc && !intr_ifl && end_into && !next_in_exec;
  assign intr_ifl = intr & ifl;

  assign n_state = (state == opcod_st) ? (prefix ? opcod_st
                         : (next_in_opco ? opcod_st
                         : (need_modrm ? modrm_st
                         : (need_off ? offse_st
                         : (need_imm ? immed_st : execu_st)))))
                     : (state == modrm_st) ? (need_off ? offse_st
                                           : (need_imm ? immed_st : execu_st))
                     : (state == offse_st) ? (need_imm ? immed_st : execu_st)
                     : (state == immed_st) ? (execu_st)
   /* state == execu_st */ : (end_instr ? opcod_st : execu_st);

  assign next_state = block ? state : n_state;
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module next_or_not (
    input [1:0] prefix,
    input [7:1] opcode,
    input cx_zero,
    input zf,
    input ext_int,
    output next_in_opco,
    output next_in_exec
  );

  // Net declarations
  wire exit_z, cmp_sca, exit_rep, valid_ops;

  // Assignments
  assign cmp_sca = opcode[2] & opcode[1];
  assign exit_z = prefix[0] ? /* repz */ (cmp_sca ? ~zf : 1'b0 )
                            : /* repnz */ (cmp_sca ? zf : 1'b0 );
  assign exit_rep = cx_zero | exit_z;
  assign valid_ops = (opcode[7:1]==7'b1010_010   // movs
                   || opcode[7:1]==7'b1010_011   // cmps
                   || opcode[7:1]==7'b1010_101   // stos
                   || opcode[7:1]==7'b1010_110   // lods
                   || opcode[7:1]==7'b1010_111); // scas
  assign next_in_exec = prefix[1] && valid_ops && !exit_rep && !ext_int;
  assign next_in_opco = prefix[1] && valid_ops && cx_zero;
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Decode instruction
// --------------------------------------------------------------------
module decode (
`ifdef DEBUG
    output [`SEQ_DATA_WIDTH-2:0] micro_addr,
`endif
    input [7:0] opcode,
    input [7:0] modrm,
    input [15:0] off_i,
    input [15:0] imm_i,
    input       rep,
    input clk,
    input rst,
    input block,
    input exec_st,
    input div_exc,

    output need_modrm,
    output need_off,
    output need_imm,
    output off_size,
    output imm_size,

    output [`IR_SIZE-1:0] ir,
    output [15:0] off_o,
    output [15:0] imm_o,
    input  ld_base,
    output end_seq,

    input  [2:0] sop_l,

    input        intr,
    input        ifl,
    output reg   inta,
    output reg   ext_int,
    input        repz_pr
  );

  // Net declarations
`ifndef DEBUG
  wire [`SEQ_DATA_WIDTH-2:0] micro_addr;
`endif
  wire [`SEQ_ADDR_WIDTH-1:0] base_addr, seq_addr;
  wire [3:0] src, dst, base, index;
  wire [1:0] seg;
  reg  [`SEQ_ADDR_WIDTH-1:0] seq;
  reg  dive;
  reg  old_ext_int;
//  reg  [`SEQ_ADDR_WIDTH-1:0] base_l;

  // Module instantiations
  opcode_deco opcode_deco0 (opcode, modrm, rep, sop_l, base_addr, need_modrm,
                            need_off, need_imm, off_size, imm_size, src, dst,
                            base, index, seg);
  seq_rom seq_rom0 (seq_addr, {end_seq, micro_addr});
  micro_data mdata0 (micro_addr, off_i, imm_i, src, dst, base, index, seg,
                     ir, off_o, imm_o);

  // Assignments
  assign seq_addr = (dive ? `INTD   : (ext_int ? (repz_pr ? `EINTP : `EINT) : base_addr)) + seq;

  // Behaviour
  // seq
  always @(posedge clk)
    if (rst) seq <= `SEQ_ADDR_WIDTH'd0;
    else if (!block)
      seq <= (exec_st && !end_seq && !rst) ? (seq + `SEQ_ADDR_WIDTH'd1)
                                           : `SEQ_ADDR_WIDTH'd0;

/* In Altera Quartus II, this latch doesn't work properly
  // base_l
  always @(posedge clk)
    base_l <= rst ? `NOP : (ld_base ? base_addr : base_l);
*/
  // dive
  always @(posedge clk)
    if (rst) dive <= 1'b0;
    else dive <= block ? dive
     : (div_exc ? 1'b1 : (dive ? !end_seq : 1'b0));

  // ext_int
  always @(posedge clk)
    if (rst) ext_int <= 1'b0;
    else ext_int <= block ? ext_int
      : ((intr & ifl & exec_st & end_seq) ? 1'b1
        : (ext_int ? !end_seq : 1'b0));

  // old_ext_int
  always @(posedge clk) old_ext_int <= rst ? 1'b0 : ext_int;

  // inta
  always @(posedge clk)
    inta <= rst ? 1'b0 : (!old_ext_int & ext_int);
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Opcode decoder
// --------------------------------------------------------------------
module opcode_deco (
    input [7:0] op,
    input [7:0] modrm,
    input       rep,
    input [2:0] sovr_pr,

    output reg [`SEQ_ADDR_WIDTH-1:0] seq_addr,
    output reg need_modrm,
    output reg need_off,
    output reg need_imm,
    output     off_size,
    output reg imm_size,

    output reg [3:0] src,
    output reg [3:0] dst,
    output [3:0] base,
    output [3:0] index,
    output [1:0] seg
  );

  // Net declarations
  wire [1:0] mod;
  wire [2:0] regm;
  wire [2:0] rm;
  wire       d, b, sm, dm;
  wire       off_size_mod, need_off_mod;
  wire [2:0] srcm, dstm;
  wire       off_size_from_mod;

  // Module instantiations
  memory_regs mr(rm, mod, sovr_pr, base, index, seg);

  // Assignments
  assign mod  = modrm[7:6];
  assign regm = modrm[5:3];
  assign rm   = modrm[2:0];
  assign d    = op[1];
  assign dstm = d ? regm : rm;
  assign sm   = d & (mod != 2'b11);
  assign dm   = ~d & (mod != 2'b11);
  assign srcm = d ? rm : regm;
  assign b    = ~op[0];
  assign off_size_mod = (base == 4'b1100 && index == 4'b1100) ? 1'b1 : mod[1];
  assign need_off_mod = (base == 4'b1100 && index == 4'b1100) || ^mod;
  assign off_size_from_mod = !op[7] | (!op[5] & !op[4]) | (op[6] & op[4]);
  assign off_size = !off_size_from_mod | off_size_mod;

  // Behaviour
  always @(op or dm or b or need_off_mod or srcm or sm or dstm
           or mod or rm or regm or rep or modrm)
    casex (op)
      8'b0000_000x: // add r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ADDRRB : `ADDRRW)
                                     : (b ? `ADDRMB : `ADDRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0000_001x: // add r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ADDRRB : `ADDRRW)
                                     : (b ? `ADDMRB : `ADDMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0000_010x: // add i->r
        begin
          seq_addr   <= b ? `ADDIRB : `ADDIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b000x_x110: // push seg
        begin
          seq_addr <= `PUSHR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 2'b10, op[4:3] };
          dst <= 4'b0;
        end

      8'b0000_100x: // or r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ORRRB : `ORRRW)
                                     : (b ? `ORRMB : `ORRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0000_101x: // or r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ORRRB : `ORRRW)
                                     : (b ? `ORMRB : `ORMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0000_110x: // or i->r
        begin
          seq_addr   <= b ? `ORIRB : `ORIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b000x_x111: // pop seg
        begin
          seq_addr <= `POPR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src      <= 4'b0;
          dst      <= { 2'b10, op[4:3] };
        end

      8'b0001_000x: // adc r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ADCRRB : `ADCRRW)
                                     : (b ? `ADCRMB : `ADCRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0001_001x: // adc r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ADCRRB : `ADCRRW)
                                     : (b ? `ADCMRB : `ADCMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0001_010x: // adc i->r
        begin
          seq_addr   <= b ? `ADCIRB : `ADCIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0001_100x: // sbb r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `SBBRRB : `SBBRRW)
                                     : (b ? `SBBRMB : `SBBRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0001_101x: // sbb r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `SBBRRB : `SBBRRW)
                                     : (b ? `SBBMRB : `SBBMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0001_110x: // sbb i->r
        begin
          seq_addr   <= b ? `SBBIRB : `SBBIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0010_000x: // and r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ANDRRB : `ANDRRW)
                                     : (b ? `ANDRMB : `ANDRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0010_001x: // and r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `ANDRRB : `ANDRRW)
                                     : (b ? `ANDMRB : `ANDMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0010_010x: // and i->r
        begin
          seq_addr   <= b ? `ANDIRB : `ANDIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0010_0111: // daa
        begin
          seq_addr   <= `DAA;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0010_100x: // sub r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `SUBRRB : `SUBRRW)
                                     : (b ? `SUBRMB : `SUBRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0010_101x: // sub r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `SUBRRB : `SUBRRW)
                                     : (b ? `SUBMRB : `SUBMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0010_110x: // sub i->r
        begin
          seq_addr   <= b ? `SUBIRB : `SUBIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0010_1111: // das
        begin
          seq_addr   <= `DAS;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_000x: // xor r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `XORRRB : `XORRRW)
                                     : (b ? `XORRMB : `XORRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0011_001x: // xor r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `XORRRB : `XORRRW)
                                     : (b ? `XORMRB : `XORMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0011_010x: // and i->r
        begin
          seq_addr   <= b ? `XORIRB : `XORIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_0111: // aaa
        begin
          seq_addr   <= `AAA;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_100x: // cmp r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `CMPRRB : `CMPRRW)
                                     : (b ? `CMPRMB : `CMPRMW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0011_101x: // cmp r->r, m->r
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `CMPRRB : `CMPRRW)
                                     : (b ? `CMPMRB : `CMPMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, dstm };
          src        <= { 1'b0, srcm };
        end

      8'b0011_110x: // cmp i->r
        begin
          seq_addr   <= b ? `CMPIRB : `CMPIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0011_1111: // aas
        begin
          seq_addr   <= `AAS;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b0100_0xxx: // inc
        begin
          seq_addr   <= `INCRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= { 1'b0, op[2:0] };
        end

      8'b0100_1xxx: // dec
        begin
          seq_addr   <= `DECRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= { 1'b0, op[2:0] };
        end

      8'b0101_0xxx: // push reg
        begin
          seq_addr <= `PUSHR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, op[2:0] };
          dst <= 4'b0;
        end

      8'b0101_1xxx: // pop reg
        begin
          seq_addr <= `POPR;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= { 1'b0, op[2:0] };
        end

      8'b0110_10x0: // push imm
        begin
          seq_addr <= `PUSHI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= !op[1];
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b0110_10x1: // imul imm
        begin
          seq_addr <= (mod==2'b11) ? `IMULIR : `IMULIM;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= !op[1];
          src <= { 1'b0, rm };
          dst <= { 1'b0, regm };
        end

      8'b0111_xxxx: // jcc
        begin
          seq_addr <= `JCC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= { op[3:0] };
          dst <= 4'b0;
        end

      8'b1000_00xx: // and, or i->r, i->m
        begin
          seq_addr   <= regm == 3'b111 ? ((mod==2'b11) ? (b ? `CMPIRB  : `CMPIRW) : (b ? `CMPIMB : `CMPIMW))
           : (regm == 3'b101 ? ((mod==2'b11) ? (b ? `SUBIRB : `SUBIRW) : (b ? `SUBIMB : `SUBIMW))
           : (regm == 3'b011 ? ((mod==2'b11) ? (b ? `SBBIRB : `SBBIRW) : (b ? `SBBIMB : `SBBIMW))
           : (regm == 3'b010 ? ((mod==2'b11) ? (b ? `ADCIRB : `ADCIRW) : (b ? `ADCIMB : `ADCIMW))
           : (regm == 3'b000 ? ((mod==2'b11) ? (b ? `ADDIRB : `ADDIRW) : (b ? `ADDIMB : `ADDIMW))
           : (regm == 3'b100 ? ((mod==2'b11) ? (b ? `ANDIRB : `ANDIRW) : (b ? `ANDIMB : `ANDIMW))
           : (regm == 3'b001 ? ((mod==2'b11) ? (b ? `ORIRB : `ORIRW)   : (b ? `ORIMB : `ORIMW))
           : ((mod==2'b11) ? (b ? `XORIRB : `XORIRW): (b ? `XORIMB : `XORIMW))))))));
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b1;
          imm_size   <= !op[1] & op[0];
          dst        <= { 1'b0, modrm[2:0] };
          src        <= 4'b0;
        end

      8'b1000_010x: // test r->r, r->m
        begin
          seq_addr   <= (mod==2'b11) ? (b ? `TSTRRB : `TSTRRW) : (b ? `TSTMRB : `TSTMRW);
          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= { 1'b0, srcm };
          src        <= { 1'b0, dstm };
        end

      8'b1000_011x: // xchg
        begin
          seq_addr <= (mod==2'b11) ? (b ? `XCHRRB : `XCHRRW) : (b ? `XCHRMB : `XCHRMW);
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          dst <= { 1'b0, dstm };
          src <= { 1'b0, srcm };
        end
      8'b1000_10xx: // mov: r->r, r->m, m->r
        begin
          if (dm)   // r->m
            begin
              seq_addr <= b ? `MOVRMB : `MOVRMW;
              need_off <= need_off_mod;
              src <= { 1'b0, srcm };
              dst <= 4'b0;
            end
          else if(sm) // m->r
            begin
              seq_addr <= b ? `MOVMRB : `MOVMRW;
              need_off <= need_off_mod;
              src <= 4'b0;
              dst <= { 1'b0, dstm };
            end
          else     // r->r
            begin
              seq_addr <= b ? `MOVRRB : `MOVRRW;
              need_off <= 1'b0;
              dst <= { 1'b0, dstm };
              src <= { 1'b0, srcm };
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          imm_size <= 1'b0;
        end

      8'b1000_1100: // mov: s->m, s->r
        begin
          if (dm)   // s->m
            begin
              seq_addr <= `MOVRMW;
              need_off <= need_off_mod;
              src <= { 1'b1, srcm };
              dst <= 4'b0;
            end
          else     // s->r
            begin
              seq_addr <= `MOVRRW;
              need_off <= 1'b0;
              src <= { 1'b1, srcm };
              dst <= { 1'b0, dstm };
            end
          need_imm <= 1'b0;
          need_modrm <= 1'b1;
          imm_size <= 1'b0;
        end

      8'b1000_1101: // lea
        begin
          seq_addr <= `LEA;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1000_1110: // mov: m->s, r->s
        begin
          if (sm)   // m->s
            begin
              seq_addr <= `MOVMRW;
              need_off <= need_off_mod;
              src <= 4'b0;
              dst <= { 1'b1, dstm };
            end
          else     // r->s
            begin
              seq_addr <= `MOVRRW;
              need_off <= 1'b0;
              src <= { 1'b0, srcm };
              dst <= { 1'b1, dstm };
            end
          need_modrm <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
        end

      8'b1000_1111: // pop mem or (pop reg non-standard)
        begin
          seq_addr <= (mod==2'b11) ? `POPR : `POPM;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= { 1'b0, rm };
        end

      8'b1001_0xxx: // nop, xchg acum
        begin
          seq_addr <= `XCHRRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0000;
          dst <= { 1'b0, op[2:0] };
        end

      8'b1001_1000: // cbw
        begin
          seq_addr   <= `CBW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1001_1001: // cwd
        begin
          seq_addr   <= `CWD;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b0;
          imm_size   <= 1'b0;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1001_1010: // call different seg
        begin
          seq_addr <= `CALLF;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1100: // pushf
        begin
          seq_addr <= `PUSHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;

          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1101: // popf
        begin
          seq_addr <= `POPF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1110: // sahf
        begin
          seq_addr <= `SAHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1001_1111: // lahf
        begin
          seq_addr <= `LAHF;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_000x: // mov: m->a
        begin
          seq_addr <= b ? `MOVMAB : `MOVMAW;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_001x: // mov: a->m
        begin
          seq_addr <= b ? `MOVAMB : `MOVAMW;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_010x: // movs
        begin
          seq_addr <= rep ? (b ? `MOVSBR : `MOVSWR) : (b ? `MOVSB : `MOVSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_011x: // cmps
        begin
          seq_addr <= rep ? (b ? `CMPSBR : `CMPSWR) : (b ? `CMPSB : `CMPSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_100x: // test i->r
        begin
          seq_addr   <= b ? `TSTIRB : `TSTIRW;
          need_modrm <= 1'b0;
          need_off   <= 1'b0;
          need_imm   <= 1'b1;
          imm_size   <= ~b;
          dst        <= 4'b0;
          src        <= 4'b0;
        end

      8'b1010_101x: // stos
        begin
          seq_addr <= rep ? (b ? `STOSBR : `STOSWR) : (b ? `STOSB : `STOSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_110x: // lods
        begin
          seq_addr <= rep ? (b ? `LODSBR : `LODSWR) : (b ? `LODSB : `LODSW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1010_111x: // scas
        begin
          seq_addr <= rep ? (b ? `SCASBR : `SCASWR) : (b ? `SCASB : `SCASW);
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1011_xxxx: // mov: i->r
        begin
          seq_addr <= op[3] ? `MOVIRW : `MOVIRB;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= op[3];

          src <= 4'b0;
          dst <= { 1'b0, op[2:0] };
        end

      8'b1100_0000: // ror/rol/rcr/rcl/sal/shl/sar/shr imm8
        begin
          seq_addr <=  (regm==3'b000) ? ((mod==2'b11) ? `ROLIRB : `ROLIMB)
                    : ((regm==3'b001) ? ((mod==2'b11) ? `RORIRB : `RORIMB)
                    : ((regm==3'b010) ? ((mod==2'b11) ? `RCLIRB : `RCLIMB)
                    : ((regm==3'b011) ? ((mod==2'b11) ? `RCRIRB : `RCRIMB)
                    : ((regm==3'b100) ? ((mod==2'b11) ? `SALIRB : `SALIMB)
                    : ((regm==3'b101) ? ((mod==2'b11) ? `SHRIRB : `SHRIMB)
                                      : ((mod==2'b11) ? `SARIRB : `SARIMB))))));
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= rm;
          dst <= rm;
        end

      8'b1100_0001: // ror/rol/rcr/rcl/sal/shl/sar/shr imm16
        begin
          seq_addr <=  (regm==3'b000) ? ((mod==2'b11) ? `ROLIRW : `ROLIMW)
                    : ((regm==3'b001) ? ((mod==2'b11) ? `RORIRW : `RORIMW)
                    : ((regm==3'b010) ? ((mod==2'b11) ? `RCLIRW : `RCLIMW)
                    : ((regm==3'b011) ? ((mod==2'b11) ? `RCRIRW : `RCRIMW)
                    : ((regm==3'b100) ? ((mod==2'b11) ? `SALIRW : `SALIMW)
                    : ((regm==3'b101) ? ((mod==2'b11) ? `SHRIRW : `SHRIMW)
                                      : ((mod==2'b11) ? `SARIRW : `SARIMW))))));
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= rm;
          dst <= rm;
        end

      8'b1100_0010: // ret near with value
        begin
          seq_addr <= `RETNV;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_0011: // ret near
        begin
          seq_addr <= `RETN0;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_0100: // les
        begin
          seq_addr <= `LES;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1100_0101: // lds
        begin
          seq_addr <= `LDS;
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= { 1'b0, srcm };
          dst <= 4'b0;
        end

      8'b1100_011x: // mov: i->m (or i->r non-standard)
        begin
          seq_addr <= (mod==2'b11) ? (b ? `MOVIRB : `MOVIRW)
                                   : (b ? `MOVIMB : `MOVIMW);
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= ~b;

          src <= 4'b0;
          dst <= { 1'b0, rm };
        end

      8'b1100_1000: // enter
        begin
          seq_addr <= `ENTER;
          need_modrm <= 1'b0;
          need_off <= need_off_mod;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1001: // leave
        begin
          seq_addr <= `LEAVE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1010: // ret far with value
        begin
          seq_addr <= `RETFV;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1011: // ret far
        begin
          seq_addr <= `RETF0;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1100: // int 3
        begin
          seq_addr <= `INT3;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1101: // int
        begin
          seq_addr <= `INT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1110: // into
        begin
          seq_addr <= `INTO;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1100_1111: // iret
        begin
          seq_addr <= `IRET;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_00xx: // sal/shl
        begin
          seq_addr <= (regm==3'b010) ? ((mod==2'b11) ? (op[1] ? (op[0] ? `RCLCRW : `RCLCRB ) : (op[0] ? `RCL1RW : `RCL1RB ))
          : (op[1] ? (op[0] ? `RCLCMW : `RCLCMB ) : (op[0] ? `RCL1MW : `RCL1MB )))
          : ((regm==3'b011) ? ((mod==2'b11) ?  (op[1] ? (op[0] ? `RCRCRW : `RCRCRB ) : (op[0] ? `RCR1RW : `RCR1RB ))
          : (op[1] ? (op[0] ? `RCRCMW : `RCRCMB )
                       : (op[0] ? `RCR1MW : `RCR1MB )))
         : ((regm==3'b001) ? ((mod==2'b11) ?
            (op[1] ? (op[0] ? `RORCRW : `RORCRB )
                       : (op[0] ? `ROR1RW : `ROR1RB ))
          : (op[1] ? (op[0] ? `RORCMW : `RORCMB )
                       : (op[0] ? `ROR1MW : `ROR1MB )))
         : ((regm==3'b000) ? ((mod==2'b11) ?
            (op[1] ? (op[0] ? `ROLCRW : `ROLCRB )
                       : (op[0] ? `ROL1RW : `ROL1RB ))
          : (op[1] ? (op[0] ? `ROLCMW : `ROLCMB )
                       : (op[0] ? `ROL1MW : `ROL1MB )))
         : ( (regm==3'b100) ? ((mod==2'b11) ?
            (op[1] ? (op[0] ? `SALCRW : `SALCRB )
                       : (op[0] ? `SAL1RW : `SAL1RB ))
          : (op[1] ? (op[0] ? `SALCMW : `SALCMB )
                       : (op[0] ? `SAL1MW : `SAL1MB )))
         : ( (regm==3'b111) ? ((mod==2'b11) ?
            (op[1] ? (op[0] ? `SARCRW : `SARCRB )
                       : (op[0] ? `SAR1RW : `SAR1RB ))
          : (op[1] ? (op[0] ? `SARCMW : `SARCMB )
                       : (op[0] ? `SAR1MW : `SAR1MB )))
           : ((mod==2'b11) ?
            (op[1] ? (op[0] ? `SHRCRW : `SHRCRB )
                       : (op[0] ? `SHR1RW : `SHR1RB ))
          : (op[1] ? (op[0] ? `SHRCMW : `SHRCMB )
                       : (op[0] ? `SHR1MW : `SHR1MB ))))))));

          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= rm;
          dst <= rm;
        end

      8'b1101_0100: // aam
        begin
          seq_addr <= `AAM;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_0101: // aad
        begin
          seq_addr <= `AAD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1101_0111: // xlat
        begin
          seq_addr <= `XLAT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0000: // loopne
        begin
          seq_addr <= `LOOPNE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0001: // loope
        begin
          seq_addr <= `LOOPE;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0010: // loop
        begin
          seq_addr <= `LOOP;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_0011: // jcxz
        begin
          seq_addr <= `JCXZ;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_010x: // in imm
        begin
          seq_addr <= b ? `INIB : `INIW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_011x: // out imm
        begin
          seq_addr <= b ? `OUTIB : `OUTIW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_1000: // call same segment
        begin
          seq_addr <= `CALLN;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= 1'b1;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_10x1: // jmp direct
        begin
          seq_addr <= `JMPI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b1;
          imm_size <= ~op[1];

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_1010: // jmp indirect different segment
        begin
          seq_addr <= `LJMPI;
          need_modrm <= 1'b0;
          need_off <= 1'b1;
          need_imm <= 1'b1;
          imm_size <= 1'b1;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_110x: // in dx
        begin
          seq_addr <= b ? `INRB : `INRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1110_111x: // out dx
        begin
          seq_addr <= b ? `OUTRB : `OUTRW;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_0100: // hlt
        begin
          seq_addr <= `HLT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_0101: // cmc
        begin
          seq_addr <= `CMC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_011x: // test, not, neg, mul, imul
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ? (b ? `TSTIRB : `TSTIRW) : (b ? `TSTIMB : `TSTIMW);
            3'b010: seq_addr <= (mod==2'b11) ? (b ? `NOTRB  : `NOTRW)  : (b ? `NOTMB  : `NOTMW);
            3'b011: seq_addr <= (mod==2'b11) ? (b ? `NEGRB  : `NEGRW)  : (b ? `NEGMB  : `NEGMW);
            3'b100: seq_addr <= (mod==2'b11) ? (b ? `MULRB  : `MULRW)  : (b ? `MULMB  : `MULMW);
            3'b101: seq_addr <= (mod==2'b11) ? (b ? `IMULRB : `IMULRW) : (b ? `IMULMB : `IMULMW);
            3'b110: seq_addr <= (mod==2'b11) ? (b ? `DIVRB  : `DIVRW)  : (b ? `DIVMB  : `DIVMW);
            3'b111: seq_addr <= (mod==2'b11) ? (b ? `IDIVRB : `IDIVRW) : (b ? `IDIVMB : `IDIVMW);
            default: seq_addr <= `NOP;
          endcase

          need_modrm <= 1'b1;
          need_off   <= need_off_mod;
          need_imm   <= (regm == 3'b000); // imm on test
          imm_size   <= ~b;
          dst        <= { 1'b0, modrm[2:0] };
          src        <= { 1'b0, modrm[2:0] };
        end

      8'b1111_1000: // clc
        begin
          seq_addr <= `CLC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1001: // stc
        begin
          seq_addr <= `STC;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1010: // cli
        begin
          seq_addr <= `CLI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1011: // sti
        begin
          seq_addr <= `STI;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1100: // cld
        begin
          seq_addr <= `CLD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1101: // std
        begin
          seq_addr <= `STD;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;
          src <= 4'b0;
          dst <= 4'b0;
        end

      8'b1111_1110: // inc
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ? `INCRB : `INCMB;
            3'b001: seq_addr <= (mod==2'b11) ? `DECRB : `DECMB;
            default: seq_addr <= `NOP;
          endcase
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= { 1'b0, rm };
          dst <= 4'b0;
        end

      8'b1111_1111:
        begin
          case (regm)
            3'b000: seq_addr <= (mod==2'b11) ? `INCRW : `INCMW;
            3'b001: seq_addr <= (mod==2'b11) ? `DECRW : `DECMW;
            3'b010: seq_addr <= (mod==2'b11) ? `CALLNR : `CALLNM;
            3'b011: seq_addr <= `CALLFM;
            3'b100: seq_addr <= (mod==2'b11) ? `JMPR : `JMPM;
            3'b101: seq_addr <= `LJMPM;
            3'b110: seq_addr <= (mod==2'b11) ? `PUSHR : `PUSHM;
            default: seq_addr <= `NOP;
          endcase
          need_modrm <= 1'b1;
          need_off <= need_off_mod;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= { 1'b0, rm };
          dst <= 4'b0;
        end

      default: // hlt
        begin
          seq_addr <= `HLT;
          need_modrm <= 1'b0;
          need_off <= 1'b0;
          need_imm <= 1'b0;
          imm_size <= 1'b0;

          src <= 4'b0;
          dst <= 4'b0;
        end

  endcase

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Memory Registers
// --------------------------------------------------------------------
module memory_regs (
    input [2:0] rm,
    input [1:0] mod,
    input [2:0] sovr_pr,

    output reg [3:0] base,
    output reg [3:0] index,
    output     [1:0] seg
  );

  // Register declaration
  reg [1:0] s;

  // Continuous assignments
  assign seg = sovr_pr[2] ? sovr_pr[1:0] : s;

  // Behaviour
  always @(rm or mod)
    case (rm)
      3'b000: begin base <= 4'b0011; index <= 4'b0110; s <= 2'b11; end
      3'b001: begin base <= 4'b0011; index <= 4'b0111; s <= 2'b11; end
      3'b010: begin base <= 4'b0101; index <= 4'b0110; s <= 2'b10; end
      3'b011: begin base <= 4'b0101; index <= 4'b0111; s <= 2'b10; end
      3'b100: begin base <= 4'b1100; index <= 4'b0110; s <= 2'b11; end
      3'b101: begin base <= 4'b1100; index <= 4'b0111; s <= 2'b11; end
      3'b110: begin base <= mod ? 4'b0101 : 4'b1100; index <= 4'b1100;
                    s <= mod ? 2'b10 : 2'b11; end
      3'b111: begin base <= 4'b0011; index <= 4'b1100; s <= 2'b11; end
    endcase
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Microcode data
// --------------------------------------------------------------------
module micro_data (
    input [`MICRO_ADDR_WIDTH-1:0] n_micro,
    input [15:0] off_i,
    input [15:0] imm_i,
    input [3:0] src,
    input [3:0] dst,
    input [3:0] base,
    input [3:0] index,
    input [1:0] seg,
    output [`IR_SIZE-1:0] ir,
    output [15:0] off_o,
    output [15:0] imm_o
  );

  // Net declarations
  wire [`MICRO_DATA_WIDTH-1:0] micro_o;
  wire [17:0] high_ir;
  wire var_s, var_off;
  wire [1:0] var_a, var_b, var_c, var_d;
  wire [2:0] var_imm;

  wire [3:0] addr_a, addr_b, addr_c, addr_d;
  wire [3:0] micro_a, micro_b, micro_c, micro_d;
  wire [1:0] addr_s, micro_s;

  // Module instantiations
  micro_rom m0 (n_micro, micro_o);

  // Assignments
  assign micro_s = micro_o[1:0];
  assign micro_a = micro_o[5:2];
  assign micro_b = micro_o[9:6];
  assign micro_c = micro_o[13:10];
  assign micro_d = micro_o[17:14];
  assign high_ir = micro_o[35:18];
  assign var_s   = micro_o[36];
  assign var_a   = micro_o[38:37];
  assign var_b   = micro_o[40:39];
  assign var_c   = micro_o[42:41];
  assign var_d   = micro_o[44:43];
  assign var_off = micro_o[45];
  assign var_imm = micro_o[48:46];

  assign imm_o = var_imm == 3'd0 ? (16'h0000)
               : (var_imm == 3'd1 ? (16'h0002)
               : (var_imm == 3'd2 ? (16'h0004)
               : (var_imm == 3'd3 ? off_i
               : (var_imm == 3'd4 ? imm_i
               : (var_imm == 3'd5 ? 16'hffff
               : (var_imm == 3'd6 ? 16'b11 : 16'd1))))));

  assign off_o = var_off ? off_i : 16'h0000;

  assign addr_a = var_a == 2'd0 ? micro_a
                : (var_a == 2'd1 ? base
                : (var_a == 2'd2 ? dst : src ));
  assign addr_b = var_b == 2'd0 ? micro_b
                : (var_b == 2'd1 ? index : src);
  assign addr_c = var_c == 2'd0 ? micro_c
                : (var_c == 2'd1 ? dst : src);
  assign addr_d = var_d == 2'd0 ? micro_d
                : (var_d == 2'd1 ? dst : src);
  assign addr_s = var_s ? seg : micro_s;

  assign ir = { high_ir, addr_d, addr_c, addr_b, addr_a, addr_s };
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Microcode ROM
// altera message_off 10030
//  get rid of the warning about
//  not initializing the ROM
// --------------------------------------------------------------------
module micro_rom (
    input [`MICRO_ADDR_WIDTH-1:0] addr,
    output [`MICRO_DATA_WIDTH-1:0] q
  );

  // Registers, nets and parameters
  reg [`MICRO_DATA_WIDTH-1:0] rom[0:2**`MICRO_ADDR_WIDTH-1];

  // Assignments
  assign q = rom[addr];

  // Behaviour
  initial $readmemb("micro_rom.dat", rom);
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Sequntial Machine ROM
// --------------------------------------------------------------------
module seq_rom (
    input [`SEQ_ADDR_WIDTH-1:0] addr,
    output [`SEQ_DATA_WIDTH-1:0] q
  );

  // Registers, nets and parameters
  reg [`SEQ_DATA_WIDTH-1:0] rom[0:2**`SEQ_ADDR_WIDTH-1];

  // Assignments
  assign q = rom[addr];

  // Behaviour
  initial $readmemb("seq_rom.dat", rom);
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module:      jmp_cond.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module jmp_cond (
    input [4:0]  logic_flags,
    input [3:0]  cond,
    input        is_cx,
    input [15:0] cx,
    output reg   jmp
  );

  // Net declarations
  wire of, sf, zf, pf, cf;
  wire cx_zero;

  // Assignments
  assign of = logic_flags[4];
  assign sf = logic_flags[3];
  assign zf = logic_flags[2];
  assign pf = logic_flags[1];
  assign cf = logic_flags[0];
  assign cx_zero = ~(|cx);

  // Behaviour
  always @(cond or is_cx or cx_zero or zf or of or cf or sf or pf)
    if (is_cx) case (cond)
        4'b0000: jmp <= cx_zero;         /* jcxz   */
        4'b0001: jmp <= ~cx_zero;        /* loop   */
        4'b0010: jmp <= zf & ~cx_zero;   /* loopz  */
        default: jmp <= ~zf & ~cx_zero; /* loopnz */
      endcase
    else case (cond)
      4'b0000: jmp <= of;
      4'b0001: jmp <= ~of;
      4'b0010: jmp <= cf;
      4'b0011: jmp <= ~cf;
      4'b0100: jmp <= zf;
      4'b0101: jmp <= ~zf;
      4'b0110: jmp <= cf | zf;
      4'b0111: jmp <= ~cf & ~zf;

      4'b1000: jmp <= sf;
      4'b1001: jmp <= ~sf;
      4'b1010: jmp <= pf;
      4'b1011: jmp <= ~pf;
      4'b1100: jmp <= (sf ^ of);
      4'b1101: jmp <= (sf ^~ of);
      4'b1110: jmp <= zf | (sf ^ of);
      4'b1111: jmp <= ~zf & (sf ^~ of);
    endcase

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module:      regfile.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module regfile (
`ifdef DEBUG
    output [15:0] ax,
    output [15:0] dx,
    output [15:0] bp,
    output [15:0] si,
    output [15:0] es,
`endif

    output [15:0] a,
    output [15:0] b,
    output [15:0] c,
    output [15:0] cs,
    output [15:0] ip,
    input  [31:0] d,
    output [15:0] s,

    output reg [8:0] flags,

    input         wr,
    input         wrfl,
    input         wrhi,
    input         clk,
    input         rst,
    input  [ 3:0] addr_a,
    input  [ 3:0] addr_b,
    input  [ 3:0] addr_c,
    input  [ 3:0] addr_d,
    input  [ 1:0] addr_s,
    input  [ 8:0] iflags,
    input         word_op,
    input         a_byte,
    input         b_byte,
    input         c_byte,
    output        cx_zero,
    input         wr_ip0
  );

  // Net declarations
  reg [15:0] r[15:0];
  wire [7:0] a8, b8, c8;

  // Assignments
`ifdef DEBUG
  assign ax = r[0];
  assign dx = r[2];
  assign bp = r[5];
  assign si = r[6];
  assign es = r[8];
`endif
  assign a = (a_byte & ~addr_a[3]) ? { {8{a8[7]}}, a8} : r[addr_a];
  assign a8 = addr_a[2] ? r[addr_a[1:0]][15:8] : r[addr_a][7:0];

  assign b = (b_byte & ~addr_b[3]) ? { {8{b8[7]}}, b8} : r[addr_b];
  assign b8 = addr_b[2] ? r[addr_b[1:0]][15:8] : r[addr_b][7:0];

  assign c = (c_byte & ~addr_c[3]) ? { {8{c8[7]}}, c8} : r[addr_c];
  assign c8 = addr_c[2] ? r[addr_c[1:0]][15:8] : r[addr_c][7:0];

  assign s = r[{2'b10,addr_s}];

  assign cs = r[9];
  assign cx_zero = (addr_d==4'd1) ? (d==16'd0) : (r[1]==16'd0);

  assign ip = r[15];

  // Behaviour
  always @(posedge clk)
    if (rst) begin
      r[0]  <= 16'd0; r[1]  <= 16'd0;
      r[2]  <= 16'd0; r[3]  <= 16'd0;
      r[4]  <= 16'd0; r[5]  <= 16'd0;
      r[6]  <= 16'd0; r[7]  <= 16'd0;
      r[8]  <= 16'd0; r[9]  <= 16'hf000;
      r[10] <= 16'd0; r[11] <= 16'd0;
      r[12] <= 16'd0; r[13] <= 16'd0;
      r[14] <= 16'd0; r[15] <= 16'hfff0;
      flags <= 9'd0;
    end else
      begin
        if (wr) begin
          if (word_op | addr_d[3:2]==2'b10)
             r[addr_d] <= word_op ? d[15:0] : {{8{d[7]}},d[7:0]};
          else if (addr_d[3]~^addr_d[2]) r[addr_d][7:0] <= d[7:0];
          else r[{2'b0,addr_d[1:0]}][15:8] <= d[7:0];
        end
        if (wrfl) flags <= iflags;
        if (wrhi) r[4'd2] <= d[31:16];
        if (wr_ip0) r[14] <= ip;
      end

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:      alu.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module alu (
    input  [31:0] x,
    input  [15:0] y,
    output [31:0] out,
    input  [ 2:0] t,
    input  [ 2:0] func,
    input  [15:0] iflags,
    output [ 8:0] oflags,
    input         word_op,
    input  [15:0] seg,
    input  [15:0] off,
    input         clk,
    output        div_exc
  );

  // Net declarations
  wire [15:0] add, log, shi, rot;
  wire  [8:0] othflags;
  wire [19:0] oth;
  wire [31:0] cnv, mul;
  wire af_add, af_cnv;
  wire cf_cnv, cf_add, cf_mul, cf_log, cf_shi, cf_rot;
  wire of_cnv, of_add, of_mul, of_log, of_shi, of_rot;
  wire ofi, sfi, zfi, afi, pfi, cfi;
  wire ofo, sfo, zfo, afo, pfo, cfo;
  wire flags_unchanged;
  wire dexc;

  // Module instances
  addsub add1 (x[15:0], y, add, func, word_op, cfi, cf_add, af_add, of_add);

  conv cnv2 (
    .x      (x[15:0]),
    .func   (func),
    .out    (cnv),
    .iflags ({afi, cfi}),
    .oflags ({af_cnv, of_cnv, cf_cnv})
  );

  muldiv mul3 (
    .x       (x),
    .y       (y),
    .o       (mul),
    .f       (func),
    .word_op (word_op),
    .cfo     (cf_mul),
    .ofo     (of_mul),
    .clk     (clk),
    .exc     (dexc)
  );

  bitlog log4 (x[15:0], y, log, func, cf_log, of_log);
  shifts shi5 (x[15:0], y[7:0], shi, func[1:0], word_op, cfi, ofi, cf_shi, of_shi);
  rotate rot6 (x[15:0], y[4:0], func[1:0], cfi, word_op, rot, cf_rot, ofi, of_rot);
  othop  oth7 (x[15:0], y, seg, off, iflags, func, word_op, oth, othflags);

  mux8_16 m0(t, {8'd0, y[7:0]}, add, cnv[15:0],
             mul[15:0], log, shi, rot, oth[15:0], out[15:0]);
  mux8_16 m1(t, 16'd0, 16'd0, cnv[31:16], mul[31:16],
             16'd0, 16'd0, 16'd0, {12'b0,oth[19:16]}, out[31:16]);
  mux8_1  a1(t, 1'b0, cf_add, cf_cnv, cf_mul, cf_log, cf_shi, cf_rot, 1'b0, cfo);
  mux8_1  a2(t, 1'b0, af_add, af_cnv, 1'b0, 1'b0, 1'b0, afi, 1'b0, afo);
  mux8_1  a3(t, 1'b0, of_add, of_cnv, of_mul, of_log, of_shi, of_rot, 1'b0, ofo);

  // Flags
  assign pfo = flags_unchanged ? pfi : ^~ out[7:0];
  assign zfo = flags_unchanged ? zfi
             : ((word_op && (t!=3'd2)) ? ~|out[15:0] : ~|out[7:0]);
  assign sfo = flags_unchanged ? sfi
             : ((word_op && (t!=3'd2)) ? out[15] : out[7]);

  assign oflags = (t == 3'd7) ? othflags 
                 : { ofo, iflags[10:8], sfo, zfo, afo, pfo, cfo };

  assign ofi = iflags[11];
  assign sfi = iflags[7];
  assign zfi = iflags[6];
  assign afi = iflags[4];
  assign pfi = iflags[2];
  assign cfi = iflags[0];

  assign flags_unchanged = (t == 3'd4 && func == 3'd2 || t == 3'd5 && y[4:0] == 5'h0 || t == 3'd6);

  assign div_exc = func[1] && (t==3'd3) && dexc;

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// --------------------------------------------------------------------
module rotate (
    input  [15:0] x,
    input  [ 4:0] y,
    input  [ 1:0] func,  // 00: ror, 01: rol, 10: rcr, 11: rcl
    input         cfi,
    input         word_op,
    output [15:0] out,
    output        cfo,
    input         ofi,
    output        ofo
  );

  // Net declarations
  wire [4:0] ror16, rol16, rcr16, rcl16, rot16;
  wire [3:0] ror8, rol8, rcr8, rcl8, rot8;
  wire [7:0] out8;
  wire [15:0] out16;
  wire co8, co16;
  wire unchanged;

  // Module instantiation
  rxr8 rxr8_0 (
    .x  (x[7:0]),
    .ci (cfi),
    .y  (rot8),
    .e  (func[1]),
    .w  (out8),
    .co (co8)
  );

  rxr16 rxr16_0 (
    .x  (x),
    .ci (cfi),
    .y  (rot16),
    .e  (func[1]),
    .w  (out16),
    .co (co16)
  );

  // Continuous assignments
  assign unchanged = word_op ? (y==5'b0) : (y[3:0]==4'b0);
  assign ror16 = { 1'b0, y[3:0] };
  assign rol16 = { 1'b0, -y[3:0] };
  assign ror8  = { 1'b0, y[2:0] };
  assign rol8  = { 1'b0, -y[2:0] };

  assign rcr16 = (y <= 5'd16) ? y : { 1'b0, y[3:0] - 4'b1 };
  assign rcl16 = (y <= 5'd17) ? 5'd17 - y : 6'd34 - y;
  assign rcr8  = y[3:0] <= 4'd8 ? y[3:0] : { 1'b0, y[2:0] - 3'b1 };
  assign rcl8  = y[3:0] <= 4'd9 ? 4'd9 - y[3:0] : 5'd18 - y[3:0];

  assign rot8 = func[1] ? (func[0] ? rcl8 : rcr8 )
                        : (func[0] ? rol8 : ror8 );
  assign rot16 = func[1] ? (func[0] ? rcl16 : rcr16 )
                         : (func[0] ? rol16 : ror16 );

  assign out = word_op ? out16 : { x[15:8], out8 };
  assign cfo = unchanged ? cfi : (func[1] ? (word_op ? co16 : co8)
                                          : (func[0] ? out[0]
                                            : (word_op ? out[15] : out[7])));
  // Overflow
  assign ofo = unchanged ? ofi : (func[0] ? // left
                         (word_op ? cfo^out[15] : cfo^out[7])
                       : // right
                         (word_op ? out[15]^out[14] : out[7]^out[6]));
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module rxr16 (
    input      [15:0] x,
    input             ci,
    input      [ 4:0] y,
    input             e,
    output reg [15:0] w,
    output reg        co
  );

  always @(x or ci or y or e)
    case (y)
      default: {co,w} <= {ci,x};
      5'd01: {co,w} <= e ? {x[0], ci, x[15:1]} : {ci, x[0], x[15:1]};
      5'd02: {co,w} <= e ? {x[ 1:0], ci, x[15: 2]} : {ci, x[ 1:0], x[15: 2]};
      5'd03: {co,w} <= e ? {x[ 2:0], ci, x[15: 3]} : {ci, x[ 2:0], x[15: 3]};
      5'd04: {co,w} <= e ? {x[ 3:0], ci, x[15: 4]} : {ci, x[ 3:0], x[15: 4]};
      5'd05: {co,w} <= e ? {x[ 4:0], ci, x[15: 5]} : {ci, x[ 4:0], x[15: 5]};
      5'd06: {co,w} <= e ? {x[ 5:0], ci, x[15: 6]} : {ci, x[ 5:0], x[15: 6]};
      5'd07: {co,w} <= e ? {x[ 6:0], ci, x[15: 7]} : {ci, x[ 6:0], x[15: 7]};
      5'd08: {co,w} <= e ? {x[ 7:0], ci, x[15: 8]} : {ci, x[ 7:0], x[15: 8]};
      5'd09: {co,w} <= e ? {x[ 8:0], ci, x[15: 9]} : {ci, x[ 8:0], x[15: 9]};
      5'd10: {co,w} <= e ? {x[ 9:0], ci, x[15:10]} : {ci, x[ 9:0], x[15:10]};
      5'd11: {co,w} <= e ? {x[10:0], ci, x[15:11]} : {ci, x[10:0], x[15:11]};
      5'd12: {co,w} <= e ? {x[11:0], ci, x[15:12]} : {ci, x[11:0], x[15:12]};
      5'd13: {co,w} <= e ? {x[12:0], ci, x[15:13]} : {ci, x[12:0], x[15:13]};
      5'd14: {co,w} <= e ? {x[13:0], ci, x[15:14]} : {ci, x[13:0], x[15:14]};
      5'd15: {co,w} <= e ? {x[14:0], ci, x[15]} : {ci, x[14:0], x[15]};
      5'd16: {co,w} <= {x,ci};
    endcase
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module rxr8 (
    input      [7:0] x,
    input            ci,
    input      [3:0] y,
    input            e,
    output reg [7:0] w,
    output reg       co
  );

  always @(x or ci or y or e)
    case (y)
      default: {co,w} <= {ci,x};
      5'd01: {co,w} <= e ? {x[0], ci, x[7:1]} : {ci, x[0], x[7:1]};
      5'd02: {co,w} <= e ? {x[1:0], ci, x[7:2]} : {ci, x[1:0], x[7:2]};
      5'd03: {co,w} <= e ? {x[2:0], ci, x[7:3]} : {ci, x[2:0], x[7:3]};
      5'd04: {co,w} <= e ? {x[3:0], ci, x[7:4]} : {ci, x[3:0], x[7:4]};
      5'd05: {co,w} <= e ? {x[4:0], ci, x[7:5]} : {ci, x[4:0], x[7:5]};
      5'd06: {co,w} <= e ? {x[5:0], ci, x[7:6]} : {ci, x[5:0], x[7:6]};
      5'd07: {co,w} <= e ? {x[6:0], ci, x[7]} : {ci, x[6:0], x[7]};
      5'd08: {co,w} <= {x,ci};
    endcase
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Module:      addsub.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module addsub (
    input  [15:0] x,
    input  [15:0] y,
    output [15:0] out,
    input  [ 2:0] f,
    input         word_op,
    input         cfi,
    output        cfo,
    output        afo,
    output        ofo
  );

  // Net declarations
  wire [15:0] op2;

  wire ci;
  wire cfoadd;
  wire xs, ys, os;

  // Module instances
  fulladd16 fa0 ( // We instantiate only one adder
    .x  (x),      //  to have less hardware
    .y  (op2),
    .ci (ci),
    .co (cfoadd),
    .z  (out),
    .s  (f[2])
  );

  // Assignments
  assign op2 = f[2] ? ~y
             : ((f[1:0]==2'b11) ? { 8'b0, y[7:0] } : y);
  assign ci  = f[2] & f[1] | f[2] & ~f[0] & ~cfi
             | f[2] & f[0] | (f==3'b0) & cfi;
  assign afo = f[1] ? (f[2] ? &out[3:0] : ~|out[3:0] )
                    : (x[4] ^ y[4] ^ out[4]);
  assign cfo = f[1] ? cfi /* inc, dec */
             : (word_op ? cfoadd : (x[8]^y[8]^out[8]));

  assign xs  = word_op ? x[15] : x[7];
  assign ys  = word_op ? y[15] : y[7];
  assign os  = word_op ? out[15] : out[7];
  assign ofo = f[2] ? (~xs & ys & os | xs & ~ys & ~os)
                    : (~xs & ~ys & os | xs & ys & ~os);
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module conv (
    input  [15:0] x,
    input  [ 2:0] func,
    output [31:0] out,
    input  [ 1:0] iflags, // afi, cfi
    output [ 2:0] oflags  // afo, ofo, cfo
  );

  // Net declarations
  wire        afi, cfi;
  wire        ofo, afo, cfo;
  wire [15:0] aaa, aas;
  wire [ 7:0] daa, tmpdaa, das, tmpdas;
  wire [15:0] cbw, cwd;

  wire        acond, dcond;
  wire        tmpcf;

  // Module instances
  mux8_16 m0(func, cbw, aaa, aas, 16'd0,
                   cwd, {x[15:8], daa}, {x[15:8], das}, 16'd0, out[15:0]);

  // Assignments
  assign aaa = (acond ? (x + 16'h0106) : x) & 16'hff0f;
  assign aas = (acond ? (x - 16'h0106) : x) & 16'hff0f;

  assign tmpdaa = acond ? (x[7:0] + 8'h06) : x[7:0];
  assign daa    = dcond ? (tmpdaa + 8'h60) : tmpdaa;
  assign tmpdas = acond ? (x[7:0] - 8'h06) : x[7:0];
  assign das    = dcond ? (tmpdas - 8'h60) : tmpdas;

  assign               cbw   = { { 8{x[ 7]}}, x[7:0] };
  assign { out[31:16], cwd } = { {16{x[15]}}, x      };

  assign acond = ((x[7:0] & 8'h0f) > 8'h09) | afi;
  assign dcond = (x[7:0] > 8'h99) | cfi;

  assign afi = iflags[1];
  assign cfi = iflags[0];

  assign afo = acond;
  assign ofo = 1'b0;
  assign tmpcf = (x[7:0] < 8'h06) | cfi;
  assign cfo = func[2] ? (dcond ? 1'b1 : (acond & tmpcf))
             : acond;

  assign oflags = { afo, ofo, cfo };
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module:      muldiv.v
// Description: Wishbone based cpu (80186 compatible)
// --------------------------------------------------------------------
module muldiv (
    input  [31:0] x,  // 16 MSb for division
    input  [15:0] y,
    output [31:0] o,
    input  [ 2:0] f,
    input         word_op,
    output        cfo,
    output        ofo,
    input         clk,
    output        exc
  );

  // Net declarations
  wire as, bs, cfs, cfu;
  wire [16:0] a, b;
  wire [33:0] p;
  wire div0, over, ovf, mint;

  wire [33:0] zi;
  wire [16:0] di;
  wire [17:0] q;
  wire [17:0] s;

  // Module instantiations
  mult signmul17 (
    .clk (clk),
    .a   (a),
    .b   (b),
    .p   (p)
  );

  div_su #(34) dut (
    .clk  (clk),
    .ena  (1'b1),
    .z    (zi),
    .d    (di),
    .q    (q),
    .s    (s),
    .ovf  (ovf),
    .div0 (div0)
  );

  // Sign ext. for imul
  assign as  = f[0] & (word_op ? x[15] : x[7]);
  assign bs  = f[0] & (word_op ? y[15] : y[7]);
  assign a   = word_op ? { as, x[15:0] }
                       : { {9{as}}, x[7:0] };
  assign b   = word_op ? { bs, y } : { {9{bs}}, y[7:0] };

  assign zi  = f[2] ? { 26'h0, x[7:0] }
               : (word_op ? (f[0] ? { {2{x[31]}}, x }
                               : { 2'b0, x })
                       : (f[0] ? { {18{x[15]}}, x[15:0] }
                               : { 18'b0, x[15:0] }));

  assign di  = word_op ? (f[0] ? { y[15], y } : { 1'b0, y })
                       : (f[0] ? { {9{y[7]}}, y[7:0] }
                               : { 9'h000, y[7:0] });

  assign o   = f[2] ? { 16'h0, q[7:0], s[7:0] }
               : (f[1] ? ( word_op ? {s[15:0], q[15:0]}
                                : {16'h0, s[7:0], q[7:0]})
                    : p[31:0]);

  assign ofo = f[1] ? 1'b0 : cfo;
  assign cfo = f[1] ? 1'b0 : !(f[0] ? cfs : cfu);
  assign cfu = word_op ? (o[31:16] == 16'h0)
                       : (o[15:8] == 8'h0);
  assign cfs = word_op ? (o[31:16] == {16{o[15]}})
                       : (o[15:8] == {8{o[7]}});

  // Exceptions
  assign over = f[2] ? 1'b0
              : (word_op ? (f[0] ? (q[17:16]!={2{q[15]}})
                                : (q[17:16]!=2'b0) )
                        : (f[0] ? (q[17:8]!={10{q[7]}})
                                : (q[17:8]!=10'h000)));
  assign mint = f[0] & (word_op ? (x==32'h80000000)
                                : (x==16'h8000));
  assign exc  = div0 | (!f[2] & ovf) | over | mint;
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module bitlog(x, y, out, func, cfo, ofo);
  // IO ports
  input  [15:0] x, y;
  input  [2:0]  func;
  output [15:0] out;
  output        cfo, ofo;

  // Net declarations
  wire [15:0] and_n, or_n, not_n, xor_n;

  // Module instantiations
  mux8_16 m0(func, and_n, or_n, not_n, xor_n, 16'd0, 16'd0, 16'd0, 16'd0, out);

  // Assignments
  assign and_n  = x & y;
  assign or_n   = x | y;
  assign not_n  = ~x;
  assign xor_n  = x ^ y;

  assign cfo = 1'b0;
  assign ofo = 1'b0;
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// This module implements the instructions shl/sal, sar, shr
// --------------------------------------------------------------------
module shifts(x, y, out, func, word_op, cfi, ofi, cfo, ofo);
  // IO ports
  input  [15:0] x;
  input  [ 7:0] y;
  input   [1:0] func;
  input         word_op;
  output [15:0] out;
  output        cfo, ofo;
  input         cfi, ofi;

  // Net declarations
  wire [15:0] sal, sar, shr, sal16, sar16, shr16;
  wire [7:0]  sal8, sar8, shr8;
  wire ofo_shl, ofo_sar, ofo_shr;
  wire cfo_sal8, cfo_sal16, cfo_sar8, cfo_sar16, cfo_shr8, cfo_shr16;
  wire cfo16, cfo8;
  wire unchanged;

  // Module instantiations
  mux4_16 m0(func, sal, sar, shr, 16'd0, out);

  // Assignments
  assign { cfo_sal16, sal16 } = x << y;
  assign { sar16, cfo_sar16 } = (y > 5'd16) ? 17'h1ffff
    : (({x,1'b0} >> y) | (x[15] ? (17'h1ffff << (17 - y))
                                     : 17'h0));
  assign { shr16, cfo_shr16 } = ({x,1'b0} >> y);

  assign { cfo_sal8, sal8 } = x[7:0] << y;
  assign { sar8, cfo_sar8 } = (y > 5'd8) ? 9'h1ff
    : (({x[7:0],1'b0} >> y) | (x[7] ? (9'h1ff << (9 - y))
                                         : 9'h0));
  assign { shr8, cfo_shr8 } = ({x[7:0],1'b0} >> y);

  assign sal     = word_op ? sal16 : { 8'd0, sal8 };
  assign shr     = word_op ? shr16 : { 8'd0, shr8 };
  assign sar     = word_op ? sar16 : { {8{sar8[7]}}, sar8 };

  assign ofo = unchanged ? ofi
             : (func[1] ? ofo_shr : (func[0] ? ofo_sar : ofo_shl));
  assign cfo16 = func[1] ? cfo_shr16
               : (func[0] ? cfo_sar16 : cfo_sal16);
  assign cfo8  = func[1] ? cfo_shr8
               : (func[0] ? cfo_sar8 : cfo_sal8);
  assign cfo = unchanged ? cfi : (word_op ? cfo16 : cfo8);
  assign ofo_shl = word_op ? (out[15] != cfo) : (out[7] != cfo);
  assign ofo_sar = 1'b0;
  assign ofo_shr = word_op ? x[15] : x[7];

  assign unchanged = word_op ? (y==5'b0) : (y[3:0]==4'b0);
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
module othop (x, y, seg, off, iflags, func, word_op, out, oflags);
  // IO ports
  input [15:0] x, y, off, seg, iflags;
  input [2:0] func;
  input word_op;
  output [19:0] out;
  output [8:0] oflags;

  // Net declarations
  wire [15:0] deff, deff2, outf, clcm, setf, intf, strf;
  wire [19:0] dcmp, dcmp2; 
  wire dfi;

  // Module instantiations
  mux8_16 m0(func, dcmp[15:0], dcmp2[15:0], deff, outf, clcm, setf, intf, strf, out[15:0]);
  assign out[19:16] = func ? dcmp2[19:16] : dcmp[19:16];

  // Assignments
  assign dcmp  = (seg << 4) + deff;
  assign dcmp2 = (seg << 4) + deff2;
  assign deff  = x + y + off;
  assign deff2 = x + y + off + 16'd2;
  assign outf  = y;
  assign clcm  = y[2] ? (y[1] ? /* -1: clc */ {iflags[15:1], 1'b0} 
                         : /* 4: cld */ {iflags[15:11], 1'b0, iflags[9:0]})
                     : (y[1] ? /* 2: cli */ {iflags[15:10], 1'b0, iflags[8:0]}
                       : /* 0: cmc */ {iflags[15:1], ~iflags[0]});
  assign setf  = y[2] ? (y[1] ? /* -1: stc */ {iflags[15:1], 1'b1} 
                         : /* 4: std */ {iflags[15:11], 1'b1, iflags[9:0]})
                     : (y[1] ? /* 2: sti */ {iflags[15:10], 1'b1, iflags[8:0]}
                       : /* 0: outf */ iflags);

  assign intf = {iflags[15:10], 2'b0, iflags[7:0]};
  assign dfi  = iflags[10];
  assign strf = dfi ? (x - y) : (x + y);

  assign oflags = word_op ? { out[11:6], out[4], out[2], out[0] }
                           : { iflags[11:8], out[7:6], out[4], out[2], out[0] };
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module mult (
    input clk,

    input      signed [16:0] a,
    input      signed [16:0] b,
    output reg signed [33:0] p
  );

  always @(posedge clk) p <= a * b;
endmodule
// --------------------------------------------------------------------


// --------------------------------------------------------------------
// Multiplexor 8:1 de 16 bits d'amplada
// --------------------------------------------------------------------
module mux8_16(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  [15:0] in0, in1, in2, in3, in4, in5, in6, in7;
  output [15:0] out;

  reg    [15:0] out;

  always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7)
    case(sel)
     3'd0:  out = in0;
     3'd1:  out = in1;
     3'd2:  out = in2;
     3'd3:  out = in3;
     3'd4:  out = in4;
     3'd5:  out = in5;
     3'd6:  out = in6;
     3'd7:  out = in7;
    endcase
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Multiplexor 8:1 d'1 bit d'amplada
// --------------------------------------------------------------------
module mux8_1(sel, in0, in1, in2, in3, in4, in5, in6, in7, out);
  input  [2:0]  sel;
  input  in0, in1, in2, in3, in4, in5, in6, in7;
  output out;

  reg    out;

  always @(sel or in0 or in1 or in2 or in3 or in4 or in5 or in6 or in7)
    case(sel)
     3'd0:  out = in0;
     3'd1:  out = in1;
     3'd2:  out = in2;
     3'd3:  out = in3;
     3'd4:  out = in4;
     3'd5:  out = in5;
     3'd6:  out = in6;
     3'd7:  out = in7;
    endcase
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Multiplexor 4:1 de 16 bits d'amplada
// --------------------------------------------------------------------
module mux4_16(sel, in0, in1, in2, in3, out);
  input  [1:0]  sel;
  input  [15:0] in0, in1, in2, in3;
  output [15:0] out;

  reg    [15:0] out;

  always @(sel or in0 or in1 or in2 or in3)
    case(sel)
     2'd0:  out = in0;
     2'd1:  out = in1;
     2'd2:  out = in2;
     2'd3:  out = in3;
    endcase
endmodule

module fulladd16 (
    input  [15:0] x,
    input  [15:0] y,
    input         ci,
    output        co,
    output [15:0] z,
    input         s
  );

  // Continuous assignments
  assign {co,z} = {1'b0, x} + {s, y} + ci;
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module div_su(clk, ena, z, d, q, s, div0, ovf);

  //
  // parameters
  //
  parameter z_width = 16;
  parameter d_width = z_width /2;
  
  //
  // inputs & outputs
  //
  input clk;              // system clock
  input ena;              // clock enable

  input  [z_width-1:0] z; // divident
  input  [d_width-1:0] d; // divisor
  output [d_width  :0] q; // quotient
  output [d_width  :0] s; // remainder
  output div0;
  output ovf;

  reg [d_width:0] q, s;
  reg div0;
  reg ovf;

  //
  // variables
  //
  reg [z_width -1:0] iz;
  reg [d_width -1:0] id;
  reg [d_width +1:0] szpipe, sdpipe;

  wire [d_width -1:0] iq, is;
  wire                idiv0, iovf;

  //
  // module body
  //

  // check d, take abs value
  always @(posedge clk)
    if (ena)
      if (d[d_width-1])
         id <= ~d +1'h1;
      else
         id <= d;

  // check z, take abs value
  always @(posedge clk)
    if (ena)
      if (z[z_width-1])
         iz <= ~z +1'h1;
      else
         iz <= z;

  // generate szpipe (z sign bit pipe)
  integer n;
  always @(posedge clk)
    if(ena)
    begin
        szpipe[0] <= z[z_width-1];

        for(n=1; n <= d_width+1; n=n+1)
           szpipe[n] <= szpipe[n-1];
    end

  // generate sdpipe (d sign bit pipe)
  integer m;
  always @(posedge clk)
    if(ena)
    begin
        sdpipe[0] <= d[d_width-1];

        for(m=1; m <= d_width+1; m=m+1)
           sdpipe[m] <= sdpipe[m-1];
    end

  // hookup non-restoring divider
  div_uu #(z_width, d_width)
  divider (
    .clk(clk),
    .ena(ena),
    .z(iz),
    .d(id),
    .q(iq),
    .s(is),
    .div0(idiv0),
    .ovf(iovf)
  );

  // correct divider results if 'd' was negative
  always @(posedge clk)
    if(ena)
      begin
         q <= (szpipe[d_width+1]^sdpipe[d_width+1]) ?
              ((~iq) + 1'h1) : ({1'b0, iq});
         s <= (szpipe[d_width+1]) ?
              ((~is) + 1'h1) : ({1'b0, is});
      end

  // delay flags same as results
  always @(posedge clk)
    if(ena)
    begin
        div0 <= idiv0;
        ovf  <= iovf;
    end
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module div_uu(clk, ena, z, d, q, s, div0, ovf);

	//
	// parameters
	//
	parameter z_width = 16;
	parameter d_width = z_width /2;
	
	//
	// inputs & outputs
	//
	input clk;               // system clock
	input ena;               // clock enable

	input  [z_width -1:0] z; // divident
	input  [d_width -1:0] d; // divisor
	output [d_width -1:0] q; // quotient
	output [d_width -1:0] s; // remainder
	output div0;
	output ovf;
	reg [d_width-1:0] q;
	reg [d_width-1:0] s;
	reg div0;
	reg ovf;

	//	
	// functions
	//
	function [z_width:0] gen_s;
		input [z_width:0] si;
		input [z_width:0] di;
	begin
	  if(si[z_width])
	    gen_s = {si[z_width-1:0], 1'b0} + di;
	  else
	    gen_s = {si[z_width-1:0], 1'b0} - di;
	end
	endfunction

	function [d_width-1:0] gen_q;
		input [d_width-1:0] qi;
		input [z_width:0] si;
	begin
	  gen_q = {qi[d_width-2:0], ~si[z_width]};
	end
	endfunction

	function [d_width-1:0] assign_s;
		input [z_width:0] si;
		input [z_width:0] di;
		reg [z_width:0] tmp;
	begin
	  if(si[z_width])
	    tmp = si + di;
	  else
	    tmp = si;

	  assign_s = tmp[z_width-1:z_width-d_width];
	end
	endfunction

	//
	// variables
	//
	reg [d_width-1:0] q_pipe  [d_width-1:0];
	reg [z_width:0] s_pipe  [d_width:0];
	reg [z_width:0] d_pipe  [d_width:0];

	reg [d_width:0] div0_pipe, ovf_pipe;
	//
	// perform parameter checks
	//
	// synopsys translate_off
	initial
	begin
	  if(d_width !== z_width / 2)
	    $display("div.v parameter error (d_width != z_width/2).");
	end
	// synopsys translate_on

	integer n0, n1, n2, n3;

	// generate divisor (d) pipe
	always @(d)
	  d_pipe[0] <= {1'b0, d, {(z_width-d_width){1'b0}} };

	always @(posedge clk)
	  if(ena)
	    for(n0=1; n0 <= d_width; n0=n0+1)
	       d_pipe[n0] <= d_pipe[n0-1];

	// generate internal remainder pipe
	always @(z)
	  s_pipe[0] <= z;

	always @(posedge clk)
	  if(ena)
	    for(n1=1; n1 <= d_width; n1=n1+1)
	       s_pipe[n1] <= gen_s(s_pipe[n1-1], d_pipe[n1-1]);

	// generate quotient pipe
	always @(posedge clk)
	  q_pipe[0] <= 0;

	always @(posedge clk)
	  if(ena)
	    for(n2=1; n2 < d_width; n2=n2+1)
	       q_pipe[n2] <= gen_q(q_pipe[n2-1], s_pipe[n2]);


	// flags (divide_by_zero, overflow)
	always @(z or d)
	begin
	  ovf_pipe[0]  <= !(z[z_width-1:d_width] < d);
	  div0_pipe[0] <= ~|d;
	end

	always @(posedge clk)
	  if(ena)
	    for(n3=1; n3 <= d_width; n3=n3+1)
	    begin
	        ovf_pipe[n3] <= ovf_pipe[n3-1];
	        div0_pipe[n3] <= div0_pipe[n3-1];
	    end

	// assign outputs
	always @(posedge clk)
	  if(ena)
	    ovf <= ovf_pipe[d_width];

	always @(posedge clk)
	  if(ena)
	    div0 <= div0_pipe[d_width];

	always @(posedge clk)
	  if(ena)
	    q <= gen_q(q_pipe[d_width-1], s_pipe[d_width]);

	always @(posedge clk)
	  if(ena)
	    s <= assign_s(s_pipe[d_width], d_pipe[d_width]);
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

