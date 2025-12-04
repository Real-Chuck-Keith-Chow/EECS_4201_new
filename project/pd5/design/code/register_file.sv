/*
 * Module: register_file
 *
 * Description: 32-entry register file for RV32I
 * Register x0 is hardwired to zero.
 * Supports 2 simultaneous reads and 1 write.
 * Write occurs on rising edge of clock.
 * Read is combinational.
 */
`include "constants.svh"

module register_file #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 5,
    parameter int NUM_REGS = 32
)(
    input logic clk,
    input logic rst,
    // Read port 1
    input logic [AWIDTH-1:0] rs1_addr_i,
    output logic [DWIDTH-1:0] rs1_data_o,
    // Read port 2
    input logic [AWIDTH-1:0] rs2_addr_i,
    output logic [DWIDTH-1:0] rs2_data_o,
    // Raw read outputs for probes (no write-first bypass)
    output logic [DWIDTH-1:0] rs1_data_raw_o,
    output logic [DWIDTH-1:0] rs2_data_raw_o,
    // Write port
    input logic write_en_i,
    input logic [AWIDTH-1:0] rd_addr_i,
    input logic [DWIDTH-1:0] rd_data_i
);

    // Register array
    reg [DWIDTH-1:0] registers [0:NUM_REGS-1];

    // quick init so sim boots predictably
    // x0 = 0 (hardwired)
    // x2 = stack pointer = PC_START + MEM_DEPTH
    initial begin
        integer i;
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            registers[i] = 32'b0;
        end
        // Initialize stack pointer (x2) to top of memory
        registers[2] = PC_START + `MEM_DEPTH;
    end

    // Read logic (combinational) - x0 always returns 0
    // Write-first behavior: if writing to same register being read, return write data
    // This handles the timing race when producer exits WB as consumer enters ID
    assign rs1_data_o = (rs1_addr_i == 5'b0) ? 32'b0 :
                        (write_en_i && (rd_addr_i == rs1_addr_i) && (rd_addr_i != 5'b0)) ? rd_data_i :
                        registers[rs1_addr_i];

    assign rs2_data_o = (rs2_addr_i == 5'b0) ? 32'b0 :
                        (write_en_i && (rd_addr_i == rs2_addr_i) && (rd_addr_i != 5'b0)) ? rd_data_i :
                        registers[rs2_addr_i];
    
    // Raw read outputs for probes - show actual register contents without write-first bypass
    // x0 always returns 0
    assign rs1_data_raw_o = (rs1_addr_i == 5'b0) ? 32'b0 : registers[rs1_addr_i];
    assign rs2_data_raw_o = (rs2_addr_i == 5'b0) ? 32'b0 : registers[rs2_addr_i];

    // Write logic (sequential) - cannot write to x0
    // nothing fancy, just a single write port
    always_ff @(posedge clk) begin
        if (!rst && write_en_i && (rd_addr_i != 5'b0)) begin
            registers[rd_addr_i] <= rd_data_i;
        end
    end

endmodule : register_file
