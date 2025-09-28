/*
 * Module: pd1
 * Description: Top-level for PD1. Instantiates:
 *   - fetch: generates the Program Counter (PC)
 *   - memory: byte-addressable RAM (combinational read, byte write)
 *
 * Notes:
 *   - The CPU/global address space maps this memory at BASE = 0x0100_0000.
 *   - For PD1 we only fetch instructions: read_en=1, write_en=0.
 *   - The instruction value (F_INSN) is taken from memory data_o.
 */

module pd1 #(
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32
)(
  input  logic clk,
  input  logic reset
);

  // ---------------------------------------------------------------------------
  // Fetch stage <-> Memory interface signals (nice names for probes.svh)
  // ---------------------------------------------------------------------------
  logic [AWIDTH-1:0] F_PC;            // fetch PC (program counter)
  logic [DWIDTH-1:0] F_INSN;          // instruction at PC (from memory)

  logic [AWIDTH-1:0] mem_addr;        // absolute address to memory
  logic [DWIDTH-1:0] mem_data_in;     // data to memory (unused in PD1)
  logic [DWIDTH-1:0] mem_data_out;    // data from memory
  logic              mem_read_en;     // read enable
  logic              mem_write_en;    // write enable

  // ---------------------------------------------------------------------------
  // Simple PD1 policy: always read instruction at PC; no writes
  // ---------------------------------------------------------------------------
  assign mem_addr     = F_PC;
  assign mem_data_in  = '0;
  assign mem_read_en  = 1'b1;
  assign mem_write_en = 1'b0;

  // We take the instruction value directly from memory output
  assign F_INSN = mem_data_out;

  // ---------------------------------------------------------------------------
  // Fetch stage
  //   - Holds BASE on reset; then PC += 4 every cycle
  //   - Its own insn_o isn't used in PD1 (we expose F_INSN from memory)
  // ---------------------------------------------------------------------------
  logic [DWIDTH-1:0] _unused_fetch_insn;

  fetch #(
    .DWIDTH   (DWIDTH),
    .AWIDTH   (AWIDTH),
    .BASEADDR (32'h0100_0000)
  ) u_fetch (
    .clk   (clk),
    .rst   (reset),
    .pc_o  (F_PC),
    .insn_o(_unused_fetch_insn)   // unused in PD1
  );

  // ---------------------------------------------------------------------------
  // Instruction memory (byte-addressable, little-endian)
  // ---------------------------------------------------------------------------
  memory #(
    .AWIDTH    (AWIDTH),
    .DWIDTH    (DWIDTH),
    .BASE_ADDR (32'h0100_0000)
  ) u_memory (
    .clk        (clk),
    .rst        (reset),
    .addr_i     (mem_addr),
    .data_i     (mem_data_in),
    .read_en_i  (mem_read_en),
    .write_en_i (mem_write_en),
    .data_o     (mem_data_out)
  );

  /*
   * To hook up the verification probes, edit project/pd1/design/probes.svh:
   *
   *   `define PROBE_ADDR      mem_addr
   *   `define PROBE_DATA_IN   mem_data_in
   *   `define PROBE_DATA_OUT  mem_data_out
   *   `define PROBE_READ_EN   mem_read_en
   *   `define PROBE_WRITE_EN  mem_write_en
   *   `define PROBE_F_PC      F_PC
   *   `define PROBE_F_INSN    F_INSN
   *
   * and ensure:
   *   `define TOP_MODULE pd1
   */

endmodule : pd1
