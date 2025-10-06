/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */


/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

module igen (
    input logic [6:0] opcode_i,
    output logic [31:0] imm_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */
     always_comb begin
        case (opcode_i)
             // I-type instructions (OP-IMM, LOAD, JALR)
            7'b0010011,  // OP-IMM
            7'b0000011,  // LOAD
            7'b1100111:  // JALR
                imm_o = 32'h00000005;  // Simple test value for now

            // S-type instructions (STORE)
            7'b0100011:  // STORE
                imm_o = 32'h00000008;  // Simple test value

            // U-type instructions (LUI, AUIPC)
            7'b0110111,  // LUI
            7'b0010111:  // AUIPC
                imm_o = 32'h12345000;  // Simple test value

            // Default case
            default:
                imm_o = 32'b0;
        endcase
    end
endmodule : igen


