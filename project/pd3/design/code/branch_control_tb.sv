`timescale 1ns/1ps

module branch_control_tb;
    localparam int DWIDTH = 32;

    //DUT signals
    logic [6:0]       opcode_i;
    logic [2:0]       funct3_i;
    logic [DWIDTH-1:0] rs1_i, rs2_i;
    logic             breq_o, brlt_o;

    //instantiate DUT
    branch_control #(.DWIDTH(DWIDTH)) dut (
        .opcode_i(opcode_i),
        .funct3_i(funct3_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .breq_o(breq_o),
        .brlt_o(brlt_o)
    );

    //functions for signed/unsigned compares
    function logic signed_lt(input logic [DWIDTH-1:0] a, input logic [DWIDTH-1:0] b);
        logic signed [DWIDTH-1:0] sa, sb;
        begin sa = a; sb = b; signed_lt = (sa < sb); end
    endfunction

    initial begin
        int i;
        $display("[BC_TB] Starting branch_control tests...");
        $dumpfile("branch_control_tb.vcd");
        $dumpvars(0, branch_control_tb);

        opcode_i = 7'b1100011; // BRANCH

        //directed checks
        rs1_i = 32'd5; rs2_i = 32'd5; funct3_i = 3'b000; #1;
        assert(breq_o === 1) else $fatal(1, "BEQ equality failed");

        rs1_i = 32'd5; rs2_i = 32'd7; #1;
        assert(breq_o === 0) else $fatal(1, "BEQ inequality failed");

        //signed compare (BLT/BGE)
        rs1_i = 32'hFFFF_FFFF; // -1
        rs2_i = 32'd1;         // +1
        funct3_i = 3'b100;     // BLT (signed)
        #1; assert(brlt_o === 1) else $fatal(1, "Signed BLT failed");

        rs1_i = 32'h8000_0000; // -2147483648
        rs2_i = 32'h7FFF_FFFF; // +2147483647
        #1; assert(brlt_o === 1) else $fatal(1, "Signed BLT boundary failed");

        //unsigned compare (BLTU/BGEU)
        rs1_i = 32'hFFFF_FFFF;
        rs2_i = 32'd0;
        funct3_i = 3'b110;     // BLTU (unsigned)
        #1; assert(brlt_o === 0) else $fatal(1, "Unsigned BLTU failed");

        rs1_i = 32'd0;
        rs2_i = 32'd1;
        #1; assert(brlt_o === 1) else $fatal(1, "Unsigned BLTU small values failed");

        //randomized checks across signed/unsigned
        for (i = 0; i < 200; i++) begin
            rs1_i = $urandom();
            rs2_i = $urandom();
            // Randomly pick signed or unsigned mode via funct3
            funct3_i = ($urandom_range(0,1) ? 3'b110 : 3'b100);
            #1;
            if (funct3_i == 3'b110 || funct3_i == 3'b111) begin
                //unsigned compare expected
                assert(brlt_o === (rs1_i < rs2_i))
                    else $fatal(1, "Rand unsigned compare mismatch a=0x%08x b=0x%08x got=%0d", rs1_i, rs2_i, brlt_o);
            end else begin
                //signed compare expected
                assert(brlt_o === signed_lt(rs1_i, rs2_i))
                    else $fatal(1, "Rand signed compare mismatch a=0x%08x b=0x%08x got=%0d", rs1_i, rs2_i, brlt_o);
            end
            assert(breq_o === (rs1_i == rs2_i)) else $fatal(1, "Rand equality mismatch");
        end

        $display("[BC_TB] All tests passed.");
        $finish;
    end
endmodule
