/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */
`include "constants.svh"

 module fetch #(
    parameter int DWIDTH   = 32,
    parameter int AWIDTH   = 32,
    parameter int BASEADDR = 32'h0100_0000
) (
    input  logic               clk,
    input  logic               rst,
    output logic [AWIDTH-1:0]  pc_o,
    output logic [DWIDTH-1:0]  insn_o
);
    logic [AWIDTH-1:0] pc;
    logic              mem_ren;
    logic [DWIDTH-1:0] mem_rdata;

    // simple sequential PC
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= BASEADDR;
        end else begin
            pc <= pc + 32'd4;
        end
    end

    // read always enabled after reset deasserts
    assign mem_ren = 1'b1;

    // Instruction memory (read-only here)
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASEADDR)
    ) u_imem (
        .clk        (clk),
        .rst        (rst),
        .addr_i     (pc),
        .data_i     ('0),
        .read_en_i  (mem_ren),
        .write_en_i (1'b0),
        .data_o     (mem_rdata)
    );

    assign pc_o   = pc;
    assign insn_o = mem_rdata;
endmodule : fetch
