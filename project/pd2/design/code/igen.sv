/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

module igen (
  input  logic [31:0] insn_i,
  input  logic [6:0]  opcode_i,
  output logic [31:0] imm_o
);
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  assign imm_i = {{20{insn_i[31]}}, insn_i[31:20]};
  assign imm_s = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};
  assign imm_b = {{19{insn_i[31]}}, insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
  assign imm_u = {insn_i[31:12], 12'b0};
  assign imm_j = {{11{insn_i[31]}}, insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};

  always_comb begin
    unique case (opcode_i)
      7'b0010011, 7'b0000011, 7'b1100111: imm_o = imm_i; // OP-IMM, LOAD, JALR
      7'b0100011:                         imm_o = imm_s; // STORE
      7'b0110111, 7'b0010111:             imm_o = imm_u; // LUI, AUIPC
      7'b1101111:                         imm_o = imm_j; // JAL
      7'b1100011:                         imm_o = imm_b; // BRANCH
      default:                            imm_o = 32'b0;
    endcase
  end
endmodule



