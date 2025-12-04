/*
 * Module: execute
 *
 * Description: Execute stage - contains ALU for RV32I operations.
 */
`include "constants.svh"

module execute #(
    parameter int DWIDTH = 32
)(
    input logic [3:0] alu_op_i,
    input logic [DWIDTH-1:0] operand_a_i,
    input logic [DWIDTH-1:0] operand_b_i,
    input logic [4:0] shamt_i,
    output logic [DWIDTH-1:0] alu_result_o
);

    // Figure out the shift amount once; register shifts pull it from operand B.
    wire [4:0] shift_amt = operand_b_i[4:0];

    // Simple ALU mux: pick an operation based on alu_op_i and crank out a result.
    always_comb begin
        case (alu_op_i)
            ALU_ADD:    alu_result_o = operand_a_i + operand_b_i;
            ALU_SUB:    alu_result_o = operand_a_i - operand_b_i;
            ALU_SLL:    alu_result_o = operand_a_i << shift_amt;
            ALU_SLT:    alu_result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'd1 : 32'd0;
            ALU_SLTU:   alu_result_o = (operand_a_i < operand_b_i) ? 32'd1 : 32'd0;
            ALU_XOR:    alu_result_o = operand_a_i ^ operand_b_i;
            ALU_SRL:    alu_result_o = operand_a_i >> shift_amt;
            ALU_SRA:    alu_result_o = $signed(operand_a_i) >>> shift_amt;
            ALU_OR:     alu_result_o = operand_a_i | operand_b_i;
            ALU_AND:    alu_result_o = operand_a_i & operand_b_i;
            ALU_PASS_B: alu_result_o = operand_b_i;  // Pass B straight through (used for LUI)
            default:    alu_result_o = operand_a_i + operand_b_i;  // Treat unknown op as ADD
        endcase
    end

endmodule : execute
