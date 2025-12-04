/*
 * Module: decode
 *
 * Description: Instruction decode stage.
 * Extracts all fields from a 32-bit RV32I instruction.
 */
`include "constants.svh"

module decode #(
    parameter int DWIDTH = 32
)(
    input logic [31:0] insn_i,
    
    // Decoded fields
    output logic [6:0] opcode_o,
    output logic [4:0] rd_o,
    output logic [2:0] funct3_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [4:0] shamt_o
);

    // Nothing fancy here—just break the instruction into the fields everyone expects.
    assign opcode_o = insn_i[6:0];
    assign rd_o     = insn_i[11:7];
    assign funct3_o = insn_i[14:12];
    assign rs1_o    = insn_i[19:15];
    assign rs2_o    = insn_i[24:20];
    assign funct7_o = insn_i[31:25];
    assign shamt_o  = insn_i[24:20];  // shamt shares bits with rs2 for shift immediates

endmodule : decode
