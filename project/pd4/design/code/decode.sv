import constants_pkg::*;

/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */

module decode #(
    parameter int DWIDTH = DATA_WIDTH,
    parameter int AWIDTH = ADDR_WIDTH
)(
    //inputs
    input logic clk,
    input logic rst,
    input logic [DWIDTH - 1:0] insn_i,
    input logic [DWIDTH - 1:0] pc_i,

    //outputs
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0] opcode_o,
    output logic [4:0] rd_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [2:0] funct3_o,
    output logic [4:0] shamt_o,
    output logic [DWIDTH-1:0] imm_o
);	

    //instantiate immediate generator
    igen igen_inst (
        .opcode_i(insn_i[6:0]),
        .insn_i(insn_i),
        .imm_o(imm_o)
    );

    //decode instruction fields
    always_comb begin
        //pass through PC and instruction
        pc_o = pc_i;
        insn_o = insn_i;
        
        //extract common fields
        opcode_o = insn_i[6:0];
        rd_o = insn_i[11:7];
        rs1_o = insn_i[19:15];
        rs2_o = insn_i[24:20];
        funct3_o = insn_i[14:12];
        funct7_o = insn_i[31:25];
        
        //extract shamt (shift amount) for immediate shift instructions
        shamt_o = insn_i[24:20];  //same as rs2 field for I-type shifts 
    end

endmodule : decode
