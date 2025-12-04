/*
 * Module: control
 *
 * Description: Main control unit for RV32I pipeline.
 * Generates control signals based on opcode and funct3/funct7 fields.
 */
`include "constants.svh"

module control #(
    parameter int DWIDTH = 32
)(
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    
    // Control outputs
    output logic [3:0] alu_op_o,          // ALU operation
    output logic [1:0] alu_src1_o,        // ALU source 1 select
    output logic [1:0] alu_src2_o,        // ALU source 2 select
    output logic reg_write_o,             // Register write enable
    output logic mem_read_o,              // Memory read enable
    output logic mem_write_o,             // Memory write enable
    output logic [1:0] wb_src_o,          // Writeback source select
    output logic branch_o,                // Branch instruction
    output logic jump_o,                  // Jump instruction (JAL/JALR)
    output logic jalr_o,                  // JALR instruction (uses rs1)
    output logic [2:0] imm_type_o         // Immediate type
);

    // main decoder: start from safe defaults, then patch based on opcode/funct bits
    always_comb begin
        // Default values
        alu_op_o = ALU_ADD;
        alu_src1_o = ALU_SRC_REG;
        alu_src2_o = ALU_SRC_REG;
        reg_write_o = 1'b0;
        mem_read_o = 1'b0;
        mem_write_o = 1'b0;
        wb_src_o = WB_SRC_ALU;
        branch_o = 1'b0;
        jump_o = 1'b0;
        jalr_o = 1'b0;
        imm_type_o = IMM_I;

        case (opcode_i)
            OP_LUI: begin
                // LUI: rd = imm << 12
                alu_op_o = ALU_PASS_B;
                alu_src1_o = ALU_SRC_ZERO;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_ALU;
                imm_type_o = IMM_U;
            end
            
            OP_AUIPC: begin
                // AUIPC: rd = PC + (imm << 12)
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_PC;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_ALU;
                imm_type_o = IMM_U;
            end
            
            OP_JAL: begin
                // JAL: rd = PC + 4; PC = PC + imm
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_PC;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_PC4;
                jump_o = 1'b1;
                imm_type_o = IMM_J;
            end
            
            OP_JALR: begin
                // JALR: rd = PC + 4; PC = (rs1 + imm) & ~1
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_REG;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_PC4;
                jump_o = 1'b1;
                jalr_o = 1'b1;
                imm_type_o = IMM_I;
            end
            
            OP_BRANCH: begin
                // Branch: PC = PC + imm if condition met
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_PC;
                alu_src2_o = ALU_SRC_IMM;
                branch_o = 1'b1;
                imm_type_o = IMM_B;
            end
            
            OP_LOAD: begin
                // Load: rd = M[rs1 + imm]
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_REG;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                mem_read_o = 1'b1;
                wb_src_o = WB_SRC_MEM;
                imm_type_o = IMM_I;
            end
            
            OP_STORE: begin
                // Store: M[rs1 + imm] = rs2
                alu_op_o = ALU_ADD;
                alu_src1_o = ALU_SRC_REG;
                alu_src2_o = ALU_SRC_IMM;
                mem_write_o = 1'b1;
                imm_type_o = IMM_S;
            end
            
            OP_IMM: begin
                // I-type ALU operations
                alu_src1_o = ALU_SRC_REG;
                alu_src2_o = ALU_SRC_IMM;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_ALU;
                imm_type_o = IMM_I;

                // funct3 picks the exact ALU op for immediates.
                case (funct3_i)
                    FUNCT3_ADD:  alu_op_o = ALU_ADD;   // ADDI
                    FUNCT3_SLT:  alu_op_o = ALU_SLT;   // SLTI
                    FUNCT3_SLTU: alu_op_o = ALU_SLTU;  // SLTIU
                    FUNCT3_XOR:  alu_op_o = ALU_XOR;   // XORI
                    FUNCT3_OR:   alu_op_o = ALU_OR;    // ORI
                    FUNCT3_AND:  alu_op_o = ALU_AND;   // ANDI
                    FUNCT3_SLL:  alu_op_o = ALU_SLL;   // SLLI
                    FUNCT3_SRL:  alu_op_o = (funct7_i[5]) ? ALU_SRA : ALU_SRL; // SRLI/SRAI
                    default:     alu_op_o = ALU_ADD;
                endcase
            end
            
            OP_REG: begin
                // R-type ALU operations
                alu_src1_o = ALU_SRC_REG;
                alu_src2_o = ALU_SRC_REG;
                reg_write_o = 1'b1;
                wb_src_o = WB_SRC_ALU;

                // for real register ops we look at both funct3 and funct7.
                case (funct3_i)
                    FUNCT3_ADD:  alu_op_o = (funct7_i[5]) ? ALU_SUB : ALU_ADD; // ADD/SUB
                    FUNCT3_SLL:  alu_op_o = ALU_SLL;
                    FUNCT3_SLT:  alu_op_o = ALU_SLT;
                    FUNCT3_SLTU: alu_op_o = ALU_SLTU;
                    FUNCT3_XOR:  alu_op_o = ALU_XOR;
                    FUNCT3_SRL:  alu_op_o = (funct7_i[5]) ? ALU_SRA : ALU_SRL; // SRL/SRA
                    FUNCT3_OR:   alu_op_o = ALU_OR;
                    FUNCT3_AND:  alu_op_o = ALU_AND;
                    default:     alu_op_o = ALU_ADD;
                endcase
            end
            
            OP_SYSTEM: begin
                // ECALL, EBREAK - treated as NOP for our purposes
                // No register writes, no memory operations
            end
            
            OP_FENCE: begin
                // FENCE - treated as NOP for our purposes
            end
            
            default: begin
                // Unknown opcode - NOP behavior
            end
        endcase
    end

endmodule : control
