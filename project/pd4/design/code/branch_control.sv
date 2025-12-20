import constants_pkg::*;

/*
 * Module: branch_control
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) 7-bit instruction opcode opcode_i
 * 2) 3-bit funct3 funct3_i
 * 3) 32-bit rs1 data rs1_i
 * 4) 32-bit rs2 data rs2_i
 *
 * Outputs:
 * 1) 1-bit operands are equal signal breq_o
 * 2) 1-bit rs1 < rs2 signal brlt_o
 */

 module branch_control #(
    parameter int DWIDTH = DATA_WIDTH
)( 
    //inputs
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    //outputs
    output logic breq_o,
    output logic brlt_o
);
    
    //signed comparison
    logic signed [DWIDTH-1:0] rs1_signed;
    logic signed [DWIDTH-1:0] rs2_signed;

    //control flag
    logic use_unsigned_compare;
	
    assign rs1_signed = rs1_i;
    assign rs2_signed = rs2_i;

    //comparison logic
    always_comb begin
        breq_o = (rs1_i == rs2_i);
        use_unsigned_compare = (funct3_i == 3'b110) || (funct3_i == 3'b111);

        if (use_unsigned_compare) begin
            brlt_o = (rs1_i < rs2_i);
        end else begin
            brlt_o = (rs1_signed < rs2_signed);
        end
    end

endmodule : branch_control
