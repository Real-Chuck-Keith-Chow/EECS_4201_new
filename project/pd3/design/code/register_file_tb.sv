`timescale 1ns/1ps
`include "constants.svh"

module register_file_tb;
    localparam int DWIDTH = 32;

    //DUT signals
    logic                 clk;
    logic                 rst;
    logic [4:0]           rs1_i, rs2_i, rd_i;
    logic [DWIDTH-1:0]    datawb_i;
    logic                 regwren_i;
    logic [DWIDTH-1:0]    rs1data_o, rs2data_o;

    //instantiate DUT
    register_file #(.DWIDTH(DWIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .rd_i(rd_i),
        .datawb_i(datawb_i),
        .regwren_i(regwren_i),
        .rs1data_o(rs1data_o),
        .rs2data_o(rs2data_o)
    );

    //clock generation: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    logic [DWIDTH-1:0] ref_regs [0:31];

    task reset_dut;
        integer i;
        begin
            rst = 1'b1;
            regwren_i = 1'b0;
            rs1_i = '0; rs2_i = '0; rd_i = '0; datawb_i = '0;
            @(posedge clk);
            @(posedge clk);
            rst = 1'b0;
            //update reference model
            for (i = 0; i < 32; i++) ref_regs[i] = '0;
            ref_regs[5'd2] = SP_RESET;
        end
    endtask

    task write_reg(input logic [4:0] rd, input logic [DWIDTH-1:0] data);
        begin
            rd_i = rd;
            datawb_i = data;
            regwren_i = 1'b1;
            @(posedge clk);
            regwren_i = 1'b0;
            rd_i = '0;
            datawb_i = '0;
            //update reference model at write edge (ignore x0)
            if (rd != 5'd0) ref_regs[rd] = data;
        end
    endtask

    task read_check(input logic [4:0] r1, input logic [4:0] r2);
        logic [DWIDTH-1:0] exp1, exp2;
        begin
            rs1_i = r1; rs2_i = r2;
            //let combinational read settle
            #1;
            exp1 = (r1 == 5'd0) ? '0 : ref_regs[r1];
            exp2 = (r2 == 5'd0) ? '0 : ref_regs[r2];
            assert(rs1data_o === exp1)
                else $fatal(1, "rs1 mismatch: r%0d exp=0x%08x got=0x%08x", r1, exp1, rs1data_o);
            assert(rs2data_o === exp2)
                else $fatal(1, "rs2 mismatch: r%0d exp=0x%08x got=0x%08x", r2, exp2, rs2data_o);
        end
    endtask

    //directed and random tests
    initial begin
        int k;
        logic [4:0] rdx, a, b;
        logic [31:0] dat;
        $display("[RF_TB] Starting register_file tests...");
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);

        reset_dut();

        //after reset: x0==0, x2==SP_RESET
        read_check(5'd0, 5'd2);

        //write to x0 should be ignored
        write_reg(5'd0, 32'hDEAD_BEEF);
        read_check(5'd0, 5'd0);

        //write and read a few registers
        write_reg(5'd1, 32'h1111_1111);
        write_reg(5'd2, 32'h2222_2222); //overwrite SP 
        write_reg(5'd3, 32'h3333_3333);
        read_check(5'd1, 5'd3);
        read_check(5'd2, 5'd1);

        //check read occurs after the rising edge
        rd_i = 5'd4; datawb_i = 32'hAAAA_AAAA; regwren_i = 1'b1;
        rs1_i = 5'd4; rs2_i = 5'd4; #1; // before clock edge, should still be old value (0)
        assert(rs1data_o === 32'h0000_0000) else $fatal(1, "read-before-write hazard not respected");
        @(posedge clk);
        regwren_i = 1'b0; rd_i = '0; datawb_i = '0; ref_regs[5'd4] = 32'hAAAA_AAAA;
        #1; 
        read_check(5'd4, 5'd4);

        //randomized write/read sequence
        for (k = 0; k < 64; k++) begin
            rdx = $urandom_range(0,31);
            dat = $urandom();
            write_reg(rdx, dat);
            a = $urandom_range(0,31);
            b = $urandom_range(0,31);
            read_check(a, b);
        end

        $display("[RF_TB] All tests passed.");
        $finish;
    end
endmodule
