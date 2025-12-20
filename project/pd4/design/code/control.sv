import constants_pkg::*;

/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */

module control #(
    parameter int DWIDTH = DATA_WIDTH
)(
    //inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    //outputs
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

    always_comb begin
        //default values
        pcsel_o = 1'b0;      //0: PC+4, 1: branch/jump target
        immsel_o = 1'b0;     //0: rs2, 1: immediate
        regwren_o = 1'b0;    //Register write enable
        rs1sel_o = 1'b0;     //0: rs1, 1: PC (for AUIPC)
        rs2sel_o = 1'b0;     //0: rs2, 1: immediate
        memren_o = 1'b0;     //Memory read enable
        memwren_o = 1'b0;    //Memory write enable
        wbsel_o = 2'b00;     //00: ALU, 01: memory, 10: PC+4
        alusel_o = ALU_ADD;  //Default ALU operation

        case (opcode_i)
            OP_LUI: begin
                regwren_o = 1'b1;
                immsel_o = 1'b1;
                rs2sel_o = 1'b1;
                alusel_o = ALU_PASS;
                wbsel_o = 2'b00;
            end

            OP_AUIPC: begin
                regwren_o = 1'b1;
                rs1sel_o = 1'b1;  //use PC as rs1
                immsel_o = 1'b1;
                rs2sel_o = 1'b1;
                alusel_o = ALU_ADD;
                wbsel_o = 2'b00;
            end

            OP_JAL: begin
                pcsel_o = 1'b1;
                regwren_o = 1'b1;
                wbsel_o = 2'b10;  //write PC+4 to rd
            end

            OP_JALR: begin
                pcsel_o = 1'b1;
                regwren_o = 1'b1;
                immsel_o = 1'b1;
                rs2sel_o = 1'b1;
                alusel_o = ALU_ADD;
                wbsel_o = 2'b10;  //write PC+4 to rd
            end

            OP_BRANCH: begin
                pcsel_o = 1'b0;  //will be determined by branch condition
                immsel_o = 1'b0;
                rs2sel_o = 1'b0;
                //ALU operation depends on branch type
                case (funct3_i)
                    3'b000, 3'b001: alusel_o = ALU_SUB;  //BEQ, BNE
                    3'b100, 3'b101: alusel_o = ALU_SLT;  //BLT, BGE
                    3'b110, 3'b111: alusel_o = ALU_SLTU; //BLTU, BGEU
                    default: alusel_o = ALU_SUB;
                endcase
            end

            OP_LOAD: begin
                regwren_o = 1'b1;
                immsel_o = 1'b1;
                rs2sel_o = 1'b1;
                memren_o = 1'b1;
                alusel_o = ALU_ADD;
                wbsel_o = 2'b01;  //write from memory
            end

            OP_STORE: begin
                immsel_o = 1'b1;
                rs2sel_o = 1'b0;  //rs2 contains data to store
                memwren_o = 1'b1;
                alusel_o = ALU_ADD;
            end

            OP_IMM: begin
                regwren_o = 1'b1;
                immsel_o = 1'b1;
                rs2sel_o = 1'b1;
                wbsel_o = 2'b00;
                
                // Determine ALU operation
                case (funct3_i)
                    3'b000: alusel_o = ALU_ADD;   //ADDI
                    3'b001: alusel_o = ALU_SLL;   //SLLI
                    3'b010: alusel_o = ALU_SLT;   //SLTI
                    3'b011: alusel_o = ALU_SLTU;  //SLTIU
                    3'b100: alusel_o = ALU_XOR;   //XORI
                    3'b101: begin
                        if (funct7_i[5]) 
                            alusel_o = ALU_SRA;  //SRAI
                        else 
                            alusel_o = ALU_SRL;  //SRLI
                    end
                    3'b110: alusel_o = ALU_OR;    //ORI
                    3'b111: alusel_o = ALU_AND;   //ANDI
                    default: alusel_o = ALU_ADD;
                endcase
            end

            OP_REG: begin
                regwren_o = 1'b1;
                immsel_o = 1'b0;
                rs2sel_o = 1'b0;
                wbsel_o = 2'b00;
                
                //determine ALU operation
                case (funct3_i)
                    3'b000: begin
                        if (funct7_i[5])
                            alusel_o = ALU_SUB;  //SUB
                        else
                            alusel_o = ALU_ADD;  //ADD
                    end
                    3'b001: alusel_o = ALU_SLL;   //SLL
                    3'b010: alusel_o = ALU_SLT;   //SLT
                    3'b011: alusel_o = ALU_SLTU;  //SLTU
                    3'b100: alusel_o = ALU_XOR;   //XOR
                    3'b101: begin
                        if (funct7_i[5])
                            alusel_o = ALU_SRA;  //SRA
                        else
                            alusel_o = ALU_SRL;  //SRL
                    end
                    3'b110: alusel_o = ALU_OR;    //OR
                    3'b111: alusel_o = ALU_AND;   //AND
                    default: alusel_o = ALU_ADD;
                endcase
            end

            default: begin
                //NOP - all control signals remain at default
            end
        endcase
    end

endmodule : control
