bleqq@Keiths3D:~/EECS-4201-project/project/pd2/design/code$ cat control.sv
/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
        parameter int DWIDTH=32
)(
        // inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

     // defaults
    always_comb begin
        pcsel_o   = 1'b0;
        immsel_o  = 1'b0;
        regwren_o = 1'b0;
        rs1sel_o  = 1'b0;
        rs2sel_o  = 1'b0;
        memren_o  = 1'b0;
        memwen_o  = 1'b0;
        wbsel_o   = 2'b00;
        alusel_o  = 4'h0; // ADD by default

        unique case (opcode_i)
            OP_LUI: begin
                regwren_o = 1'b1;
                rs1sel_o  = 1'b1;   // x0
                rs2sel_o  = 1'b1;   // imm
                immsel_o  = 1'b1;
                wbsel_o   = 2'b10;  // treat as immediate/U
                alusel_o  = 4'h0;   // pass B (ADD x0, imm)
            end
            OP_AUIPC: begin
                regwren_o = 1'b1;
                rs1sel_o  = 1'b0;   // PC acts elsewhere; keep defaults
                rs2sel_o  = 1'b1;   // imm
                immsel_o  = 1'b1;
                wbsel_o   = 2'b10;  // PC + imm
                alusel_o  = 4'h0;   // ADD
            end
            OP_JAL: begin
                pcsel_o   = 1'b1;
                regwren_o = 1'b1;   // write PC+4 to rd
                wbsel_o   = 2'b10;
            end
            OP_JALR: begin
                pcsel_o   = 1'b1;
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;   // imm
                immsel_o  = 1'b1;
                wbsel_o   = 2'b10;
            end
            OP_BRANCH: begin
                pcsel_o   = 1'b1;   // branch decision handled elsewhere
                alusel_o  = 4'h1;   // SUB/compare
            end
            OP_LOAD: begin
                regwren_o = 1'b1;
                memren_o  = 1'b1;
                rs2sel_o  = 1'b1;   // base + imm
                immsel_o  = 1'b1;
                wbsel_o   = 2'b01;  // from memory
                alusel_o  = 4'h0;   // ADD
            end
            OP_STORE: begin
                memwen_o  = 1'b1;
                rs2sel_o  = 1'b1;   // use imm as offset
                immsel_o  = 1'b1;
                alusel_o  = 4'h0;   // ADD
            end
            OP_OPIMM: begin
                regwren_o = 1'b1;
                rs2sel_o  = 1'b1;   // imm
                immsel_o  = 1'b1;
                // alusel_o could decode funct3/funct7 further; keep simple
            end
            OP_OP: begin
                regwren_o = 1'b1;
                // rs2sel_o = 0 (register)
            end
            default: ; // keep defaults
        endcase
    end

endmodule : control
