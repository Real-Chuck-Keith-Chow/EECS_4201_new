/*
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */

module three_stage_pipeline #(
parameter int DWIDTH = 8)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
    );

    /*
     * Process definitions to be filled by
     * student below...
     * [HINT] Instantiate the alu and reg_rst modules
     * and set up the necessary connections
     *
     */
//Wire declarations
logic [DWIDTH-1:0] op1_reg_out;
logic [DWIDTH-1:0] op2_reg_out;
logic [DWIDTH-1:0] stage1_alu_out;
logic [DWIDTH-1:0] sum_reg_out;
logic [DWIDTH-1:0] stage2_alu_out;

//Module instantiations for ALU and registers
reg_rst #(.DWIDTH(DWIDTH)) reg_op1(
  .clk (clk),
  .rst (rst),
  .in_i (op1_i),
  .out_o (op1_reg_out)
);

reg_rst #(.DWIDTH(DWIDTH)) reg_op2(
  .clk (clk),
  .rst (rst),
  .in_i (op2_i),
  .out_o (op2_reg_out)
);

alu #(.DWIDTH(DWIDTH)) alu_add( 
  .sel_i (ADD),
  .op1_i (op1_reg_out),
  .op2_i (op2_reg_out),
  .res_o (stage1_alu_out),
  .zero_o (),
  .neg_o ()
);

reg_rst #(.DWIDTH(DWIDTH)) reg_sum(
  .clk (clk),
  .rst (rst),
  .in_i (stage1_alu_out),
  .out_o (sum_reg_out)
);

alu #(.DWIDTH(DWIDTH)) alu_sub(
  .sel_i (SUB),
  .op1_i (sum_reg_out),
  .op2_i (op1_reg_out),
  .res_o (stage2_alu_out),
  .zero_o (),
  .neg_o ()
);

reg_rst #(.DWIDTH(DWIDTH)) reg_sub(
  .clk (clk),
  .rst (rst),
  .in_i (stage2_alu_out),
  .out_o (res_o)
);
endmodule: three_stage_pipeline

