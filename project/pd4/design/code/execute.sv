import constants_pkg::*;

/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 3-bit funct3 funct3_i
 * 5) 7-bit funct7 funct7_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

module alu #(
    parameter int DWIDTH = DATA_WIDTH,
    parameter int AWIDTH = ADDR_WIDTH
)(  
    //input
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    input logic [6:0] opcode_i,
    input logic [3:0] alusel_i,
    input logic [DWIDTH-1:0] imm_i,
    input logic breq_i,
    input logic brlt_i,
    //output
    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);

    logic [DWIDTH-1:0] alu_res;
    logic signed [DWIDTH-1:0] signed_a;
    logic signed [DWIDTH-1:0] signed_b;
    logic [4:0] shamt;
    logic [AWIDTH-1:0] branch_target;
    logic [AWIDTH-1:0] jalr_target;

    assign signed_a = rs1_i;
    assign signed_b = rs2_i;
    assign shamt = rs2_i[4:0];
    assign branch_target = pc_i + imm_i;
    assign jalr_target = (rs1_i + imm_i) & ~{{(AWIDTH-1){1'b0}}, 1'b1};

    always_comb begin
        unique case (alusel_i)
            ALU_ADD:  alu_res = rs1_i + rs2_i;
            ALU_SUB:  alu_res = rs1_i - rs2_i;
            ALU_SLL:  alu_res = rs1_i << shamt;
            ALU_SLT:  alu_res = signed_a < signed_b ? {{(DWIDTH-1){1'b0}}, 1'b1} : '0;
            ALU_SLTU: alu_res = (rs1_i < rs2_i) ? {{(DWIDTH-1){1'b0}}, 1'b1} : '0;
            ALU_XOR:  alu_res = rs1_i ^ rs2_i;
            ALU_SRL:  alu_res = rs1_i >> shamt;
            ALU_SRA:  alu_res = signed_a >>> shamt;
            ALU_OR:   alu_res = rs1_i | rs2_i;
            ALU_AND:  alu_res = rs1_i & rs2_i;
            ALU_PASS: alu_res = rs2_i;
            default:  alu_res = '0;
        endcase
    end

    //branch-taken flag
    always_comb begin
        brtaken_o = 1'b0;
        if (opcode_i == OP_BRANCH) begin
            unique case (funct3_i)
                3'b000: brtaken_o = breq_i;      //BEQ
                3'b001: brtaken_o = ~breq_i;     //BNE
                3'b100: brtaken_o = brlt_i;      //BLT
                3'b101: brtaken_o = ~brlt_i;     //BGE
                3'b110: brtaken_o = brlt_i;      //BLTU
                3'b111: brtaken_o = ~brlt_i;     //BGEU
                default: brtaken_o = 1'b0;
            endcase
        end
    end

    always_comb begin
        res_o = alu_res;
        unique case (opcode_i)
            OP_BRANCH: res_o = branch_target;
            OP_JAL:    res_o = branch_target;
            OP_JALR:   res_o = jalr_target;
            default:   res_o = alu_res;
        endcase
    end

endmodule : alu
