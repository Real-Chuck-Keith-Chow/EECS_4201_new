/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

`include "constants.svh"

module igen #(
    parameter int DWIDTH=32
    )(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [31:0] imm_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */

      logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;

    // I-type (load, OP-IMM, JALR, system/misc when applicable)
    assign i_imm = {{20{insn_i[31]}}, insn_i[31:20]};

    // S-type (store)
    assign s_imm = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};

    // B-type (branch) — note the bit placement and low 0
    assign b_imm = {{19{insn_i[31]}}, insn_i[31], insn_i[7],
                    insn_i[30:25], insn_i[11:8], 1'b0};

    // U-type (LUI/AUIPC)
    assign u_imm = {insn_i[31:12], 12'b0};

    // J-type (JAL)
    assign j_imm = {{11{insn_i[31]}}, insn_i[31], insn_i[19:12],
                    insn_i[20], insn_i[30:21], 1'b0};

    always_comb begin
        unique case (opcode_i)
            OP_LUI, OP_AUIPC: imm_o = u_imm;      // U
            OP_JAL:           imm_o = j_imm;      // J
            OP_JALR,
            OP_LOAD,
            OP_OPIMM,
            OP_SYSTEM,
            OP_MISC:          imm_o = i_imm;      // I
            OP_STORE:         imm_o = s_imm;      // S
            OP_BRANCH:        imm_o = b_imm;      // B
            OP_OP:            imm_o = 32'd0;      // R has no immediate
            default:          imm_o = 32'd0;
        endcase
    end

endmodule : igen



