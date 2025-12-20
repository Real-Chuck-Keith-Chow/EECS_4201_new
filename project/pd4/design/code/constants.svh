/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

package constants_pkg;

parameter int DATA_WIDTH = 32;
parameter int ADDR_WIDTH = 32;

parameter logic [31:0] ZERO            = 32'd0;
parameter logic [31:0] SP_RESET        = 32'h0110_0000;
parameter logic [31:0] MEM_BASE_ADDR   = 32'h0100_0000;
parameter logic [31:0] WORD_STRIDE     = 32'd4;

//opcode encodings
parameter logic [6:0] OP_LUI    = 7'b0110111;
parameter logic [6:0] OP_AUIPC  = 7'b0010111;
parameter logic [6:0] OP_JAL    = 7'b1101111;
parameter logic [6:0] OP_JALR   = 7'b1100111;
parameter logic [6:0] OP_BRANCH = 7'b1100011;
parameter logic [6:0] OP_LOAD   = 7'b0000011;
parameter logic [6:0] OP_STORE  = 7'b0100011;
parameter logic [6:0] OP_IMM    = 7'b0010011;
parameter logic [6:0] OP_REG    = 7'b0110011;

//memory access sizes
parameter logic [1:0] MEM_SIZE_BYTE = 2'b00;
parameter logic [1:0] MEM_SIZE_HALF = 2'b01;
parameter logic [1:0] MEM_SIZE_WORD = 2'b10;

//ALU operation encodings
parameter logic [3:0] ALU_ADD  = 4'b0000;
parameter logic [3:0] ALU_SUB  = 4'b0001;
parameter logic [3:0] ALU_SLL  = 4'b0010;
parameter logic [3:0] ALU_SLT  = 4'b0011;
parameter logic [3:0] ALU_SLTU = 4'b0100;
parameter logic [3:0] ALU_XOR  = 4'b0101;
parameter logic [3:0] ALU_SRL  = 4'b0110;
parameter logic [3:0] ALU_SRA  = 4'b0111;
parameter logic [3:0] ALU_OR   = 4'b1000;
parameter logic [3:0] ALU_AND  = 4'b1001;
parameter logic [3:0] ALU_PASS = 4'b1010;

/*
 * Define constants as required...
 */

endpackage:constants_pkg

`endif
