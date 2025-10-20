/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

/*
 * Define constants as required...
 */
localparam logic [6:0] OP_LUI     = 7'b0110111;
localparam logic [6:0] OP_AUIPC   = 7'b0010111;
localparam logic [6:0] OP_JAL     = 7'b1101111;
localparam logic [6:0] OP_JALR    = 7'b1100111;
localparam logic [6:0] OP_BRANCH  = 7'b1100011;
localparam logic [6:0] OP_LOAD    = 7'b0000011;
localparam logic [6:0] OP_STORE   = 7'b0100011;
localparam logic [6:0] OP_OPIMM   = 7'b0010011; // I-type ALU
localparam logic [6:0] OP_OP      = 7'b0110011; // R-type ALU
localparam logic [6:0] OP_MISC    = 7'b0001111;
localparam logic [6:0] OP_SYSTEM  = 7'b1110011;

// funct3 for branches
localparam logic [2:0] F3_BEQ   = 3'b000;
localparam logic [2:0] F3_BNE   = 3'b001;
localparam logic [2:0] F3_BLT   = 3'b100;
localparam logic [2:0] F3_BGE   = 3'b101;
localparam logic [2:0] F3_BLTU  = 3'b110;
localparam logic [2:0] F3_BGEU  = 3'b111;

// I-type shifts (funct3=001/101) use funct7 to disambiguate
localparam logic [2:0] F3_SLLI  = 3'b001;
localparam logic [2:0] F3_SRxx  = 3'b101;
localparam logic [6:0] F7_SRLI  = 7'b0000000;
localparam logic [6:0] F7_SRAI  = 7'b0100000;


`endif
