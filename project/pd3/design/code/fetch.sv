/*
 * Module: fetch
 * Description: Minimal fetch stage with PC register and instruction ROM interface.
 *
 * Inputs:
 *  - clk, rst
 *  - branch redirect (take + target)
 *  - imem_rdata_i : instruction word from memory
 * Outputs:
 *  - pc_o, insn_o
 *  - imem_addr_o : address to request
 */
`include "constants.svh"

module fetch #(
  parameter int AWIDTH = 32
)(
  input  logic             clk,
  input  logic             rst,
  input  logic             take_branch_i,
  input  logic [AWIDTH-1:0] branch_target_i,

  input  logic [31:0]       imem_rdata_i,
  output logic [AWIDTH-1:0] imem_addr_o,

  output logic [AWIDTH-1:0] pc_o,
  output logic [31:0]       insn_o
);
  logic [AWIDTH-1:0] pc_q, pc_n;

  // Next PC
  always_comb begin
    pc_n = take_branch_i ? branch_target_i : (pc_q + 32'd4);
  end

  // PC register
  always_ff @(posedge clk) begin
    if (rst) pc_q <= RESET_PC;
    else     pc_q <= pc_n;
  end

  // ROM interface + outputs
  assign imem_addr_o = pc_q;
  assign insn_o      = imem_rdata_i;
  assign pc_o        = pc_q;

  // sim-only misalign warning
  // synthesis translate_off
  always @* if (pc_q[1:0] != 2'b00) $warning("fetch: misaligned PC %h", pc_q);
  // synthesis translate_on
endmodule
