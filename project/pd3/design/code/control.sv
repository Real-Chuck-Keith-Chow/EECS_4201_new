/*
 * Module: control
 *
 * Description: Combinational control decode for RV32I core ops.
 * This is a lightweight control to drive EXU/redirect/WB in PD3 context.
 */
`include "constants.svh"

module control (
  input  logic [31:0] insn_i,
  output logic        is_branch_o,
  output logic        is_jal_o,
  output logic        is_jalr_o,
  output logic        reg_write_en_o,
  output logic        mem_read_o,
  output logic        mem_write_o,
  output logic [3:0]  alu_sel_o,
  output logic        use_imm_o
);
  logic [6:0] opc   = insn_i[6:0];
  logic [2:0] funct3= insn_i[14:12];
  logic [6:0] funct7= insn_i[31:25];

  // defaults
  always_comb begin
    is_branch_o     = 1'b0;
    is_jal_o        = 1'b0;
    is_jalr_o       = 1'b0;
    reg_write_en_o  = 1'b0;
    mem_read_o      = 1'b0;
    mem_write_o     = 1'b0;
    alu_sel_o       = ALU_ADD;
    use_imm_o       = 1'b0;

    unique case (opc)
      OPCODE_OP: begin
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b0;
      end
      OPCODE_OP_IMM: begin
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b1;
      end
      OPCODE_LUI: begin
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b1;
      end
      OPCODE_AUIPC: begin
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b1;
      end
      OPCODE_JAL: begin
        is_jal_o       = 1'b1;
        reg_write_en_o = 1'b1;
      end
      OPCODE_JALR: begin
        is_jalr_o      = 1'b1;
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b1;
      end
      OPCODE_BRANCH: begin
        is_branch_o    = 1'b1;
      end
      OPCODE_LOAD: begin
        mem_read_o     = 1'b1;  // placeholder (data path not hooked in PD3)
        reg_write_en_o = 1'b1;
        use_imm_o      = 1'b1;
      end
      OPCODE_STORE: begin
        mem_write_o    = 1'b1;  // placeholder
        use_imm_o      = 1'b1;
      end
      default: ;
    endcase
  end
endmodule
