
/*
 * Module: pd2
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */
`include "probes.svh"
module pd2 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset

`ifdef PROBE_F_PC
    , output logic [AWIDTH-1:0] F_PC
`endif
`ifdef PROBE_F_INSN
    , output logic [DWIDTH-1:0] F_INSN
`endif
`ifdef PROBE_D_PC
    , output logic [AWIDTH-1:0] D_PC
`endif
`ifdef PROBE_D_OPCODE
    , output logic [6:0] D_OPCODE
`endif
`ifdef PROBE_D_RD
    , output logic [4:0] D_RD
`endif
`ifdef PROBE_D_FUNCT3
    , output logic [2:0] D_FUNCT3
`endif
`ifdef PROBE_D_RS1
    , output logic [4:0] D_RS1
`endif
`ifdef PROBE_D_RS2
    , output logic [4:0] D_RS2
`endif
`ifdef PROBE_D_FUNCT7
    , output logic [6:0] D_FUNCT7
`endif
`ifdef PROBE_D_IMM
    , output logic [DWIDTH-1:0] D_IMM
`endif
`ifdef PROBE_D_SHAMT
    , output logic [4:0] D_SHAMT
`endif

    );

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */
   // Internal signals for igen testing
 logic [AWIDTH-1:0] f_pc;
    logic [DWIDTH-1:0] f_insn;

    // Decode stage signals
    logic [AWIDTH-1:0] d_pc;
    logic [DWIDTH-1:0] d_insn;
    logic [6:0] d_opcode;
    logic [4:0] d_rd;
    logic [4:0] d_rs1;
    logic [4:0] d_rs2;
    logic [6:0] d_funct7;
    logic [2:0] d_funct3;
    logic [4:0] d_shamt;
    logic [DWIDTH-1:0] d_imm;

    // Fetch stage
    fetch fetch_stage (
        .clk(clk),
        .rst(reset),
        .pc_o(f_pc),
        .insn_o(f_insn)
    );

    // Decode stage
    decode decode_stage (
        .clk(clk),
        .rst(reset),
        .insn_i(f_insn),
        .pc_i(f_pc),
        .pc_o(d_pc),
        .insn_o(d_insn),
        .opcode_o(d_opcode),
        .rd_o(d_rd),
        .rs1_o(d_rs1),
        .rs2_o(d_rs2),
        .funct7_o(d_funct7),
        .funct3_o(d_funct3),
        .shamt_o(d_shamt),
        .imm_o(d_imm)
    );

    // Immediate generator
    igen imm_gen (
        .opcode_i(d_opcode),
        .imm_o()  // Will connect to control later
    );

        // Connect probe outputs
`ifdef PROBE_F_PC
    assign F_PC = f_pc;
`endif
`ifdef PROBE_F_INSN
    assign F_INSN = f_insn;
`endif
`ifdef PROBE_D_PC
    assign D_PC = d_pc;
`endif
`ifdef PROBE_D_OPCODE
    assign D_OPCODE = d_opcode;
`endif
`ifdef PROBE_D_RD
    assign D_RD = d_rd;
`endif
`ifdef PROBE_D_FUNCT3
    assign D_FUNCT3 = d_funct3;
`endif
`ifdef PROBE_D_RS1
    assign D_RS1 = d_rs1;
`endif
`ifdef PROBE_D_RS2
    assign D_RS2 = d_rs2;
`endif
`ifdef PROBE_D_FUNCT7
    assign D_FUNCT7 = d_funct7;
`endif
`ifdef PROBE_D_IMM
    assign D_IMM = d_imm;
`endif
`ifdef PROBE_D_SHAMT
    assign D_SHAMT = d_shamt;
`endif

endmodule : pd2

