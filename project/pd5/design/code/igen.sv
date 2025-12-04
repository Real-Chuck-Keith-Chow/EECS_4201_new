/*
 * Module: igen
 *
 * Description: Immediate value generator for RV32I
 * Extracts and sign-extends immediate values from instruction encodings.
 */
`include "constants.svh"

module igen #(
    parameter int DWIDTH = 32
)(
    input logic [31:0] insn_i,
    input logic [2:0] imm_type_i,
    output logic [DWIDTH-1:0] imm_o
);

    // Extract immediate fields based on instruction format
    always_comb begin
        case (imm_type_i)
            IMM_I: begin // I-type: imm[11:0] = insn[31:20]
                imm_o = {{20{insn_i[31]}}, insn_i[31:20]};
            end
            IMM_S: begin // S-type: imm[11:0] = {insn[31:25], insn[11:7]}
                imm_o = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};
            end
            IMM_B: begin // B-type: imm[12:1] = {inst[31], inst[7], inst[30:25], inst[11:8]}, imm[0]=0
                imm_o = {{19{insn_i[31]}}, insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
            end
            IMM_U: begin // U-type: imm[31:12] = insn[31:12]
                imm_o = {insn_i[31:12], 12'b0};
            end
            IMM_J: begin // J-type: imm[20:1] = {insn[31], insn[19:12], insn[20], insn[30:21]}
                imm_o = {{11{insn_i[31]}}, insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};
            end
            default: begin
                imm_o = 32'b0;
            end
        endcase
    end

endmodule : igen
