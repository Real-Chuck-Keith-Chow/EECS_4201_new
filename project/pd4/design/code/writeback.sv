import constants_pkg::*;

/*
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 * 2) AWIDTH wide next computed PC next_pc_o
 */

 module writeback #(
     parameter int DWIDTH = DATA_WIDTH,
     parameter int AWIDTH = ADDR_WIDTH
 )(
     //input
     input logic [AWIDTH-1:0] pc_i,
     input logic [DWIDTH-1:0] alu_res_i,
     input logic [DWIDTH-1:0] memory_data_i,
     input logic [1:0] wbsel_i,
     input logic pcsel_i,
     input logic brtaken_i,
     //output
     output logic [DWIDTH-1:0] writeback_data_o,
     output logic [AWIDTH-1:0] next_pc_o
 );
    
    //PC+4 computation
    logic [AWIDTH-1:0] word_stride;
    logic [AWIDTH-1:0] pc_plus4;

    assign word_stride = WORD_STRIDE[AWIDTH-1:0];
    assign pc_plus4 = pc_i + word_stride;
    
    //write-back data mux
    always_comb begin
        unique case (wbsel_i)
            2'b00: writeback_data_o = alu_res_i;
            2'b01: writeback_data_o = memory_data_i;
            2'b10: writeback_data_o = pc_plus4;
            default: writeback_data_o = alu_res_i;
        endcase
    end

    //next PC logic
    always_comb begin
        next_pc_o = pc_plus4;
        if (pcsel_i || brtaken_i) begin
            next_pc_o = alu_res_i;
        end
    end

endmodule : writeback







