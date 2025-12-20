import constants_pkg::*;

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
    parameter int DWIDTH = DATA_WIDTH,
    parameter int AWIDTH = ADDR_WIDTH,
    parameter logic [AWIDTH-1:0] BASEADDR=MEM_BASE_ADDR
)(
    //inputs
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] next_pc_i,
    //outputs	
    output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);
    logic [AWIDTH - 1:0] pc_reg;
    logic [DWIDTH - 1:0] imem_data;
    
    //update PC on clock edge
    always_ff @(posedge clk) begin 
        if (rst) begin
            pc_reg <= BASEADDR;
        end else begin
            pc_reg <= next_pc_i;
        end
    end
       
    assign pc_o = pc_reg;
    assign insn_o = imem_data;

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASEADDR)
    ) instruction_memory (
        .clk(clk),
        .rst(rst),
        .addr_i(pc_reg),
        .data_i('0),
        .read_en_i(1'b1),
        .write_en_i(1'b0),
        .size_i(MEM_SIZE_WORD),
        .unsigned_load_i(1'b1),
        .data_o(imem_data),
        .probe_data_o()
    );

endmodule : fetch
