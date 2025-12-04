/*
 * Module: writeback
 *
 * Description: Write-back stage - selects data to write to register file.
 *
 * Inputs:
 * 1) pc_i - PC of instruction (for PC+4 writeback)
 * 2) alu_res_i - result from ALU
 * 3) memory_data_i - data from memory (for loads)
 * 4) wb_src_i - writeback source select
 *
 * Outputs:
 * 1) DWIDTH wide write back data writeback_data_o
 */
`include "constants.svh"

module writeback #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32
)(
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] alu_res_i,
    input logic [DWIDTH-1:0] memory_data_i,
    input logic [1:0] wb_src_i,
    output logic [DWIDTH-1:0] writeback_data_o
);

    // simple mux for writeback selection
    always_comb begin
        case (wb_src_i)
            WB_SRC_ALU:  writeback_data_o = alu_res_i;
            WB_SRC_MEM:  writeback_data_o = memory_data_i;
            WB_SRC_PC4:  writeback_data_o = pc_i + 4;
            default:     writeback_data_o = alu_res_i;
        endcase
    end

endmodule : writeback

