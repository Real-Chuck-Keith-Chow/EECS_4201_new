/*
 * Module: pd0
 *
 * Description: Top level module that will contain sub-module instantiations.
 * An instantiation of the assign_xor module is shown as an example. The other
 * modules must be instantiated similarly. Probes are defined, which will be used
 * to test This file also defines probes that will be used to test the design. Note
 * that the top level module should have only two inputs: clk and rest signals.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

/*
 * Module: pd0
 *
 * Description: Top level module with properly connected pipeline
 */
module pd0 #(
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // ====================================
    // Internal signals for pipeline connection
    // ====================================
    
    // REG module signals
    logic [DWIDTH-1:0] reg_rst_inp;
    logic [DWIDTH-1:0] reg_rst_out;
    
    // TSP module signals  
    logic [DWIDTH-1:0] tsp_op1;
    logic [DWIDTH-1:0] tsp_op2;
    logic [DWIDTH-1:0] tsp_out;
    
    // ALU module signals
    logic [DWIDTH-1:0] alu_op1;
    logic [DWIDTH-1:0] alu_op2;
    logic [DWIDTH-1:0] alu_res;
    logic [1:0] alu_sel;
    
    // XOR module signals
    logic assign_xor_op1;
    logic assign_xor_op2;
    logic assign_xor_res;
    
    // Instantiate register
    reg_rst #(.DWIDTH(DWIDTH)) reg_inst (
        .clk(clk),
        .rst(reset),
        .in_i(reg_rst_inp),
        .out_o(reg_rst_out)
    );
    
    // Instantiate three-stage pipeline
    three_stage_pipeline #(.DWIDTH(DWIDTH)) tsp_inst (
        .clk(clk),
        .rst(reset),
        .op1_i(tsp_op1),
        .op2_i(tsp_op2),
        .res_o(tsp_out)
    );
    
    // Instantiate ALU
    alu #(.DWIDTH(DWIDTH)) alu_inst (
        .op1_i(alu_op1),
        .op2_i(alu_op2),
        .sel_i(alu_sel),
        .res_o(alu_res),
        .neg_o(),
        .zero_o()
    );
    
    // Instantiate XOR
    assign_xor xor_inst (
        .op1_i(assign_xor_op1),
        .op2_i(assign_xor_op2),
        .res_o(assign_xor_res)
    );
endmodule: pd0
