/*
 * Constants for RV32I pipelined CPU
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

// Memory configuration
`ifndef MEM_DEPTH
`define MEM_DEPTH 1048576
`endif

// Base address for instruction memory
parameter logic [31:0] PC_START = 32'h01000000;

// NOP instruction encoding (addi x0, x0, 0)
parameter logic [31:0] NOP_INSN = 32'h00000013;

// Zero constant
parameter logic [31:0] ZERO = 32'd0;

// Opcode map: handy for decode/control.
parameter logic [6:0] OP_LUI    = 7'b0110111;  // LUI
parameter logic [6:0] OP_AUIPC  = 7'b0010111;  // AUIPC
parameter logic [6:0] OP_JAL    = 7'b1101111;  // JAL
parameter logic [6:0] OP_JALR   = 7'b1100111;  // JALR
parameter logic [6:0] OP_BRANCH = 7'b1100011;  // BEQ, BNE, BLT, BGE, BLTU, BGEU
parameter logic [6:0] OP_LOAD   = 7'b0000011;  // LB, LH, LW, LBU, LHU
parameter logic [6:0] OP_STORE  = 7'b0100011;  // SB, SH, SW
parameter logic [6:0] OP_IMM    = 7'b0010011;  // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
parameter logic [6:0] OP_REG    = 7'b0110011;  // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
parameter logic [6:0] OP_FENCE  = 7'b0001111;  // FENCE
parameter logic [6:0] OP_SYSTEM = 7'b1110011;  // ECALL, EBREAK

// Funct3 values for branches.
parameter logic [2:0] FUNCT3_BEQ  = 3'b000;
parameter logic [2:0] FUNCT3_BNE  = 3'b001;
parameter logic [2:0] FUNCT3_BLT  = 3'b100;
parameter logic [2:0] FUNCT3_BGE  = 3'b101;
parameter logic [2:0] FUNCT3_BLTU = 3'b110;
parameter logic [2:0] FUNCT3_BGEU = 3'b111;

// Funct3 values for loads/stores.
parameter logic [2:0] FUNCT3_BYTE  = 3'b000;  // LB, SB
parameter logic [2:0] FUNCT3_HALF  = 3'b001;  // LH, SH
parameter logic [2:0] FUNCT3_WORD  = 3'b010;  // LW, SW
parameter logic [2:0] FUNCT3_BYTEU = 3'b100;  // LBU
parameter logic [2:0] FUNCT3_HALFU = 3'b101;  // LHU

// Funct3 for ALU immediates (and shared codes).
parameter logic [2:0] FUNCT3_ADD  = 3'b000;  // ADDI (also ADD/SUB for OP_REG)
parameter logic [2:0] FUNCT3_SLT  = 3'b010;  // SLTI
parameter logic [2:0] FUNCT3_SLTU = 3'b011;  // SLTIU
parameter logic [2:0] FUNCT3_XOR  = 3'b100;  // XORI
parameter logic [2:0] FUNCT3_OR   = 3'b110;  // ORI
parameter logic [2:0] FUNCT3_AND  = 3'b111;  // ANDI
parameter logic [2:0] FUNCT3_SLL  = 3'b001;  // SLLI
parameter logic [2:0] FUNCT3_SRL  = 3'b101;  // SRLI, SRAI

// Only two funct7 encodings we care about.
parameter logic [6:0] FUNCT7_NORMAL = 7'b0000000;  // ADD, SRL, etc.
parameter logic [6:0] FUNCT7_ALT    = 7'b0100000;  // SUB, SRA

// ALU op codes used by the execute stage.
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
parameter logic [3:0] ALU_PASS_B = 4'b1010;  // Pass operand B through (for LUI)

// ALU input multiplexers.
parameter logic [1:0] ALU_SRC_REG  = 2'b00;  // Register
parameter logic [1:0] ALU_SRC_IMM  = 2'b01;  // Immediate
parameter logic [1:0] ALU_SRC_PC   = 2'b10;  // PC
parameter logic [1:0] ALU_SRC_ZERO = 2'b11;  // Zero

// Writeback mux choices.
parameter logic [1:0] WB_SRC_ALU  = 2'b00;  // ALU result
parameter logic [1:0] WB_SRC_MEM  = 2'b01;  // Memory data
parameter logic [1:0] WB_SRC_PC4  = 2'b10;  // PC + 4 (for JAL/JALR)
parameter logic [1:0] WB_SRC_IMM  = 2'b11;  // Immediate (unused in standard RV32I)

// Immediate generator modes.
parameter logic [2:0] IMM_I = 3'b000;  // I-type
parameter logic [2:0] IMM_S = 3'b001;  // S-type
parameter logic [2:0] IMM_B = 3'b010;  // B-type
parameter logic [2:0] IMM_U = 3'b011;  // U-type
parameter logic [2:0] IMM_J = 3'b100;  // J-type

// Forwarding select enums.
parameter logic [1:0] FWD_NONE   = 2'b00;  // No forwarding
parameter logic [1:0] FWD_EX_MEM = 2'b01;  // Forward from EX/MEM
parameter logic [1:0] FWD_MEM_WB = 2'b10;  // Forward from MEM/WB

`endif

