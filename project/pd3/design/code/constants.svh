/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_



/*
 * Define constants as required...
 */


//below are all the opcode for all the different types of ops needed in pd3
parameter logic [6:0] OPCODE_OP_R_TYPE   =    7'b0110011;// opcode for R-type
parameter logic [6:0] OPCODE_OP_IMM =  7'b0010011;// opcode for I-type




 //ALU operation
 parameter logic [3:0] ALU_ADD =         4'b0000; //This is the ALU function selector to select add
parameter logic [3:0] ALU_SUB        =        4'b0001;


`endif
