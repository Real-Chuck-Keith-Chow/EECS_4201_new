/*
 * Module: alu
 *
 * Description: A simple ALU module that does addition, subtraction,
 * logical or and logical and operation. The operations are
 * combinational circuits.
 *
 * Inputs:
 * 1) DWIDTH-wide input op1_i
 * 2) DWIDTH-wide input op2_i
 * 3) 2-bit selection signal sel_i
 * (refer constants_pkg.sv for the selection signals)
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 * 2) 1-bit signal that is asserted if result is zero zero_o
 * 3) 1-bit signal that is asserted if result is negative neg_o
 */

// Declare the enumerations in a package
import constants_pkg::*;

module alu #(
    parameter int DWIDTH = 8)(
        input logic [1:0] sel_i,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o,
        output logic zero_o,
        output logic neg_o
    );

    /*
     * Process definitions to be filled by
     * student below...
     */
     always_comb begin
        case(sel_i)
        2'b00: res_o = op1_i + op2_i;
        2'b01: res_o = op1_i - op2_i; 
        2'b10: res_o = op1_i & op2_i;
        2'b11: res_o = op1_i | op2_i;
        default: res_0 = '0'; 
        endcase
     end


     // Flags
assign zero_o = (res_o == '0);       // 1 if result = 0
assign neg_o  = res_o[DWIDTH-1];     // 1 if result is negative



endmodule: alu
