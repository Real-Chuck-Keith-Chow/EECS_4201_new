/* Decode stage: extract fields, compute imm via igen, and present sanitized outputs */
`include "constants.svh"

module decode #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32
)(
    // inputs
    input  logic              clk,
    input  logic              rst,       // kept for interface; not used
    input  logic [DWIDTH-1:0] insn_i,
    input  logic [AWIDTH-1:0] pc_i,

    // outputs (combinational)
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0]        opcode_o,
    output logic [4:0]        rd_o,
    output logic [4:0]        rs1_o,
    output logic [4:0]        rs2_o,
    output logic [6:0]        funct7_o,
    output logic [2:0]        funct3_o,
    output logic [4:0]        shamt_o,
    output logic [DWIDTH-1:0] imm_o
);

  // ------------ Raw field extraction from instruction ------------
  logic [6:0] opcode_c;  assign opcode_c  = insn_i[6:0];
  logic [4:0] rd_c;      assign rd_c      = insn_i[11:7];
  logic [2:0] funct3_c;  assign funct3_c  = insn_i[14:12];
  logic [4:0] rs1_c;     assign rs1_c     = insn_i[19:15];
  logic [4:0] rs2_c;     assign rs2_c     = insn_i[24:20];
  logic [6:0] funct7_c;  assign funct7_c  = insn_i[31:25];
  logic [4:0] shamt_c;   assign shamt_c   = insn_i[24:20];

  // ------------ Immediate generation ------------
  logic [DWIDTH-1:0] imm_c;
  igen #(.DWIDTH(DWIDTH)) u_igen (
    .opcode_i(opcode_c),
    .insn_i  (insn_i),
    .imm_o   (imm_c)
  );

  // ------------ Sanitize presence/meaning of some fields ------------

  // rd is not present for STORE (S-type) or BRANCH (B-type)
  logic [4:0] rd_dec;
  always_comb begin
    unique case (opcode_c)
      OPCODE_STORE, OPCODE_BRANCH: rd_dec = 5'd0;
      default:                      rd_dec = rd_c;
    endcase
  end

  // rs2 is meaningful for R-type, STORE (S), and BRANCH (B); else 0
  logic [4:0] rs2_dec;
  always_comb begin
    unique case (opcode_c)
      OPCODE_OP, OPCODE_STORE, OPCODE_BRANCH: rs2_dec = rs2_c;
      default:                                rs2_dec = 5'd0;
    endcase
  end

  // funct7 is meaningful for R-type; for OP-IMM only on SRLI/SRAI (funct3=101)
  logic [6:0] funct7_dec;
  always_comb begin
    if (opcode_c == OPCODE_OP) begin
      funct7_dec = funct7_c;
    end else if (opcode_c == OPCODE_OP_IMM && funct3_c == 3'b101) begin
      // SRLI/SRAI: funct7 distinguishes logical vs arithmetic
      funct7_dec = funct7_c;
    end else begin
      funct7_dec = 7'd0;
    end
  end

  // ------------ Combinational outputs ------------
  assign pc_o      = pc_i;
  assign insn_o    = insn_i;
  assign opcode_o  = opcode_c;
  assign rd_o      = rd_dec;
  assign rs1_o     = rs1_c;
  assign rs2_o     = rs2_dec;
  assign funct7_o  = funct7_dec;
  assign funct3_o  = funct3_c;
  assign shamt_o   = shamt_c;
  assign imm_o     = imm_c;

endmodule : decode
