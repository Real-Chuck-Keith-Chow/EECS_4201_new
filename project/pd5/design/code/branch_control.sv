/*
 * Module: branch_control
 *
 * Description: Branch comparison logic for RV32I.
 * Determines if a branch should be taken based on funct3 and operand comparison.
 */
`include "constants.svh"

module branch_control #(
    parameter int DWIDTH = 32
)(
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_data_i,
    input logic [DWIDTH-1:0] rs2_data_i,
    input logic branch_i,           // Is this a branch instruction?
    output logic branch_taken_o     // Should branch be taken?
);

    logic cmp_result;

    // Simple comparator: look at funct3 and let the branch unit know.
    always_comb begin
        cmp_result = 1'b0;

        case (funct3_i)
            FUNCT3_BEQ: begin  // BEQ: rs1 == rs2
                cmp_result = (rs1_data_i == rs2_data_i);
            end
            FUNCT3_BNE: begin  // BNE: rs1 != rs2
                cmp_result = (rs1_data_i != rs2_data_i);
            end
            FUNCT3_BLT: begin  // BLT: rs1 < rs2 (signed)
                cmp_result = ($signed(rs1_data_i) < $signed(rs2_data_i));
            end
            FUNCT3_BGE: begin  // BGE: rs1 >= rs2 (signed)
                cmp_result = ($signed(rs1_data_i) >= $signed(rs2_data_i));
            end
            FUNCT3_BLTU: begin // BLTU: rs1 < rs2 (unsigned)
                cmp_result = (rs1_data_i < rs2_data_i);
            end
            FUNCT3_BGEU: begin // BGEU: rs1 >= rs2 (unsigned)
                cmp_result = (rs1_data_i >= rs2_data_i);
            end
            default: begin
                cmp_result = 1'b0;
            end
        endcase
        
        // Branch is taken only if it's a branch instruction AND condition is met
        branch_taken_o = branch_i && cmp_result;
    end

endmodule : branch_control
