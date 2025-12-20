import constants_pkg::*;

/*
 * Module: igen
 *
 * Description: Immediate value generator
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */

module igen #(
    parameter int DWIDTH = DATA_WIDTH
)(
    //input
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    //output
    output logic [31:0] imm_o
);

    //immediate generation logic
    always_comb begin
        imm_o = 32'h0;
        
        case (opcode_i)
            OP_LUI, OP_AUIPC: begin
                // U-type: imm[31:12] | rd | opcode
                imm_o = {insn_i[31:12], 12'b0};
            end
            
            OP_JAL: begin
                // J-type: imm[20|10:1|11|19:12] | rd | opcode
                imm_o = {{12{insn_i[31]}},    // Sign extend
                         insn_i[19:12],        // imm[19:12]
                         insn_i[20],           // imm[11]
                         insn_i[30:21],        // imm[10:1]
                         1'b0};                // imm[0] = 0
            end
            
            OP_JALR, OP_LOAD, OP_IMM: begin
                // I-type: imm[11:0] | rs1 | funct3 | rd | opcode
                imm_o = {{20{insn_i[31]}}, insn_i[31:20]};
            end
            
            OP_BRANCH: begin
	    //B-type: imm[12|10:5|4:1|11]
	    imm_o = {{20{insn_i[31]}},    // Sign extend
		     insn_i[7],            // imm[11]
		     insn_i[30:25],        // imm[10:5]
		     insn_i[11:8],         // imm[4:1]
		     1'b0};                // imm[0] = 0
	     end
            
            OP_STORE: begin
                //S-type: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
                imm_o = {{20{insn_i[31]}},    // Sign extend
                         insn_i[31:25],        // imm[11:5]
                         insn_i[11:7]};        // imm[4:0]
            end
            
            default: begin
                imm_o = 32'h0;
            end
        endcase
    end

endmodule : igen
