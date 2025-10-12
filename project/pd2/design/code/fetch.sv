// -----------------------------------------------------------------------------
// FETCH: sequential PC, combinational read, outputs registered in lock-step
// - BASEADDR = 0x0100_0000
// - Use pc_n (the "next" PC) for memory address and for the latched outputs,
//   then update pc_q <= pc_n. This avoids a 1-cycle lag at the clock edge.
// -----------------------------------------------------------------------------
module fetch #(
    parameter int DWIDTH   = 32,
    parameter int AWIDTH   = 32,
    parameter int BASEADDR = 32'h0100_0000
)(
    input  logic              clk,
    input  logic              rst,
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o
);

  // Program counter register (state)
  logic [AWIDTH-1:0] pc_q;

  // Next PC used for memory access and for outputs
  logic [AWIDTH-1:0] pc_n;
  always_comb begin
    if (rst) pc_n = BASEADDR;
    else     pc_n = pc_q + 32'd4;
  end

  // Combinational read from memory at pc_n (safe during reset)
  logic [DWIDTH-1:0] imem_data;

  // Registered outputs (aligned with pc_n)
  logic [AWIDTH-1:0] pc_o_q;
  logic [DWIDTH-1:0] insn_o_q;

  // State update: advance to pc_n
  always_ff @(posedge clk) begin
    pc_q <= pc_n;
  end

  // Instruction memory (combinational read)
  memory #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .BASE_ADDR(BASEADDR)
  ) u_imem (
    .clk        (clk),
    .rst        (rst),
    .addr_i     (pc_n),     // <<< use next PC to avoid 1-cycle lag
    .data_i     ('0),
    .read_en_i  (1'b1),
    .write_en_i (1'b0),
    .data_o     (imem_data)
  );

  // Latch F-stage outputs for this cycle (pc_n & its instruction)
  always_ff @(posedge clk) begin
    pc_o_q   <= pc_n;
    insn_o_q <= imem_data;
  end

  assign pc_o   = pc_o_q;
  assign insn_o = insn_o_q;

endmodule
