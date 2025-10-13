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

    /*ADD = 2'b00,
      SUB = 2'b01,
      AND = 2'b10,
      OR =  2'b11*/
    always_comb begin
      if (sel_i == ADD) begin
        res_o =  op1_i + op2_i;
      end else if(sel_i == SUB) begin
        res_o =  op1_i - op2_i;
      end else if(sel_i == AND) begin
        res_o =  op1_i & op2_i;
      end else if(sel_i == OR) begin
        res_o =  op1_i | op2_i;
      end else begin
        res_o = '0;  // Default case
      end
      
      neg_o = res_o[DWIDTH-1] == 1;
      zero_o = (res_o == 0);

    end
endmodule: alu
