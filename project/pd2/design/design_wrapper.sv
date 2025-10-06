module design_wrapper (
    input logic clk,
    input logic reset
 );
 // instantiate 
    // For testing purposes only not finalized yet
 `TOP_MODULE #(.DWIDTH(32)) core (
     .clk(clk),
     .reset(reset)

`ifdef PROBE_F_PC
     , .F_PC()
`endif
`ifdef PROBE_F_INSN
     , .F_INSN()
`endif
`ifdef PROBE_D_PC
     , .D_PC()
`endif
`ifdef PROBE_D_OPCODE
     , .D_OPCODE()
`endif
`ifdef PROBE_D_RD
     , .D_RD()
`endif
`ifdef PROBE_D_FUNCT3
     , .D_FUNCT3()
`endif
`ifdef PROBE_D_RS1
     , .D_RS1()
`endif
`ifdef PROBE_D_RS2
     , .D_RS2()
`endif
`ifdef PROBE_D_FUNCT7
     , .D_FUNCT7()
`endif
`ifdef PROBE_D_IMM
     , .D_IMM()
`endif
`ifdef PROBE_D_SHAMT
     , .D_SHAMT()
`endif
  );
endmodule
