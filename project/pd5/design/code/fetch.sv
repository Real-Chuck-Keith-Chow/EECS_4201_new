/*
 * Module: fetch
 *
 * Description: Fetch stage - handles PC and instruction fetch.
 * This is a wrapper/helper module. The main pipeline logic is in pd5.sv.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) stall_i - stall the fetch stage
 * 4) flush_i - flush/squash the fetch stage
 * 5) branch_taken_i - branch was taken
 * 6) jump_i - jump instruction
 * 7) branch_target_i - target address for branch/jump
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) AWIDTH wide next program counter pc_next_o
 */
`include "constants.svh"

module fetch #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic rst,
    input logic stall_i,
    input logic flush_i,
    input logic branch_taken_i,
    input logic jump_i,
    input logic [AWIDTH-1:0] branch_target_i,
    output logic [AWIDTH-1:0] pc_o,
    output logic [AWIDTH-1:0] pc_next_o
);

    // PC register
    reg [AWIDTH-1:0] pc_reg;

    // quick next-PC chooser (branch wins, otherwise +4)
    always_comb begin
        if (branch_taken_i || jump_i) begin
            pc_next_o = branch_target_i;
        end else begin
            pc_next_o = pc_reg + 4;
        end
    end

    // bump the PC each cycle unless reset or stalled
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_reg <= PC_START;
        end else if (!stall_i) begin
            pc_reg <= pc_next_o;
        end
        // If stalled, hold current PC
    end

    assign pc_o = pc_reg;

endmodule : fetch

