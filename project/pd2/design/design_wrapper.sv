`include "probes.svh"

module design_wrapper (
    input  logic clk,
    input  logic reset
);

`ifdef PROBE_F_PC   logic [31:0] F_PC_w;   `endif
`ifdef PROBE_F_INSN logic [31:0] F_INSN_w; `endif
`ifdef PROBE_D_PC   logic [31:0] D_PC_w;   `endif
`ifdef PROBE_D_OPCODE logic [6:0] D_OPCODE_w; `endif
`ifdef PROBE_D_RD   logic [4:0]  D_RD_w;   `endif
`ifdef PROBE_D_FUNCT3 logic [2:0] D_FUNCT3_w; `endif
`ifdef PROBE_D_RS1  logic [4:0]  D_RS1_w;  `endif
`ifdef PROBE_D_RS2  logic [4:0]  D_RS2_w;  `endif
`ifdef PROBE_D_FUNCT7 logic [6:0] D_FUNCT7_w; `endif
`ifdef PROBE_D_IMM  logic [31:0] D_IMM_w;  `endif
`ifdef PROBE_D_SHAMT logic [4:0] D_SHAMT_w; `endif

  // Harness wants instance name "core"
  `TOP_MODULE #(.DWIDTH(32)) core (
    .clk   (clk),
    .reset (reset)
`ifdef PROBE_F_PC   , .F_PC   (F_PC_w)    `endif
`ifdef PROBE_F_INSN , .F_INSN (F_INSN_w)  `endif
`ifdef PROBE_D_PC   , .D_PC   (D_PC_w)    `endif
`ifdef PROBE_D_OPCODE , .D_OPCODE (D_OPCODE_w) `endif
`ifdef PROBE_D_RD   , .D_RD   (D_RD_w)    `endif
`ifdef PROBE_D_FUNCT3 , .D_FUNCT3 (D_FUNCT3_w) `endif
`ifdef PROBE_D_RS1  , .D_RS1  (D_RS1_w)   `endif
`ifdef PROBE_D_RS2  , .D_RS2  (D_RS2_w)   `endif
`ifdef PROBE_D_FUNCT7 , .D_FUNCT7 (D_FUNCT7_w) `endif
`ifdef PROBE_D_IMM  , .D_IMM  (D_IMM_w)   `endif
`ifdef PROBE_D_SHAMT, .D_SHAMT(D_SHAMT_w) `endif
  );

endmodule

