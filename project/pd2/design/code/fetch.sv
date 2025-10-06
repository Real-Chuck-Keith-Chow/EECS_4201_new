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

 module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
    )(
        // inputs
        input logic clk,
        input logic rst,
        // outputs
        output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */

    logic [AWIDTH - 1:0] pc;

    // Memory interface signals
    logic [DWIDTH-1:0] mem_data;
    logic mem_read_en;

    // Instantiate instruction memory
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASEADDR)
    ) imem (
        .clk(clk),
        .rst(rst),
        .addr_i(pc),
        .data_i('0),  // No writes to instruction memory
        .read_en_i(mem_read_en),
        .write_en_i(1'b0),  // Instruction memory is read-only
        .data_o(mem_data)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= BASEADDR;
            mem_read_en <= 1'b0;
        end else begin
            pc <= pc + 32'd4;
            mem_read_en <= 1'b1;  // Always read next instruction
        end
    end

    assign pc_o = pc;
    assign insn_o = mem_data;

endmodule : fetch






