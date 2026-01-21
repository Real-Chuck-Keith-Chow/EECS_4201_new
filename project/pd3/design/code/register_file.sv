`include "constants.svh"

/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) clk
 * 2) reset signal rst
 * 3) 5-bit rs1 address rs1_i
 * 4) 5-bit rs2 address rs2_i
 * 5) 5-bit rd address rd_i
 * 6) DWIDTH-wide data writeback datawb_i
 * 7) register write enable regwren_i
 * Outputs:
 * 1) 32-bit rs1 data rs1data_o
 * 2) 32-bit rs2 data rs2data_o
 */

 module register_file #(
     parameter int DWIDTH=32
 )(
     // inputs
     input logic clk,
     input logic rst,
     input logic [4:0] rs1_i,
     input logic [4:0] rs2_i,
     input logic [4:0] rd_i,
     input logic [DWIDTH-1:0] datawb_i,
     input logic regwren_i,
     // outputs
     output logic [DWIDTH-1:0] rs1data_o,
     output logic [DWIDTH-1:0] rs2data_o
 );

    logic [DWIDTH-1:0] registers [0:31];
    int i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i++) begin
                registers[i] <= '0;
            end
            registers[5'd2] <= SP_RESET;
        end else if (regwren_i && (rd_i != 5'd0)) begin
            registers[rd_i] <= datawb_i;
        end
    end

    always_comb begin
        rs1data_o = (rs1_i == 5'd0) ? '0 : registers[rs1_i];
        rs2data_o = (rs2_i == 5'd0) ? '0 : registers[rs2_i];
    end

endmodule : register_file

