`timescale 1ns/1ps

module execute_tb;
    localparam int DWIDTH = 32;
    localparam int AWIDTH = 32;

    //DUT encodings
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_SLL  = 4'b0010;
    localparam logic [3:0] ALU_SLT  = 4'b0011;
    localparam logic [3:0] ALU_SLTU = 4'b0100;
    localparam logic [3:0] ALU_XOR  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_OR   = 4'b1000;
    localparam logic [3:0] ALU_AND  = 4'b1001;
    localparam logic [3:0] ALU_PASS = 4'b1010;

    localparam logic [6:0] OP_JAL     = 7'b1101111;
    localparam logic [6:0] OP_JALR    = 7'b1100111;
    localparam logic [6:0] OP_BRANCH  = 7'b1100011;

    //DUT signals
    logic [AWIDTH-1:0] pc_i;
    logic [DWIDTH-1:0] rs1_i, rs2_i, imm_i;
    logic [2:0]        funct3_i;
    logic [6:0]        funct7_i; //unused
    logic [6:0]        opcode_i;
    logic [3:0]        alusel_i;
    logic              breq_i, brlt_i;
    logic [DWIDTH-1:0] res_o;
    logic              brtaken_o;

    //instantiate DUT
    alu #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) dut (
        .pc_i(pc_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .funct3_i(funct3_i),
        .funct7_i(funct7_i),
        .opcode_i(opcode_i),
        .alusel_i(alusel_i),
        .imm_i(imm_i),
        .breq_i(breq_i),
        .brlt_i(brlt_i),
        .res_o(res_o),
        .brtaken_o(brtaken_o)
    );

    //compute signed less-than in TB
    function logic signed_lt(input logic [31:0] a, input logic [31:0] b);
        logic signed [31:0] sa, sb; begin sa=a; sb=b; return (sa < sb); end
    endfunction

    task drive_default;
        begin
            pc_i = 32'h1000_0000;
            rs1_i = 32'h0; rs2_i = 32'h0; imm_i = 32'h0;
            funct3_i = 3'b000; funct7_i = 7'h00;
            opcode_i = 7'h00;
            alusel_i = ALU_ADD;
            breq_i = 1'b0; brlt_i = 1'b0;
        end
    endtask

    task check_result(input string name, input logic [31:0] exp_res);
        begin
            #1; //allow combinational settle
            assert(res_o === exp_res)
                else $fatal(1, "%s: res mismatch exp=0x%08x got=0x%08x", name, exp_res, res_o);
        end
    endtask

    task check_branch_taken(input string name, input logic exp);
        begin
            #1;
            assert(brtaken_o === exp)
                else $fatal(1, "%s: brtaken mismatch exp=%0d got=%0d", name, exp, brtaken_o);
        end
    endtask

    initial begin
        int t;
        logic signed [31:0] sa;
        $display("[EX_TB] Starting execute/ALU tests...");
        $dumpfile("execute_tb.vcd");
        $dumpvars(0, execute_tb);

        drive_default();

        //ALU ops (opcode != branch/jump)
        opcode_i = 7'h00;
        rs1_i = 32'h0000_0003; rs2_i = 32'h0000_0004; alusel_i = ALU_ADD; check_result("ADD", 32'h0000_0007);
        alusel_i = ALU_SUB; check_result("SUB", 32'hFFFF_FFFF);
        rs1_i = 32'h0000_0001; rs2_i = 32'h0000_0008; alusel_i = ALU_SLL; check_result("SLL", 32'h0000_0100);
        rs1_i = 32'hFFFF_FFFF; rs2_i = 32'h0000_0001; alusel_i = ALU_SLT; check_result("SLT", 32'h0000_0001); // -1 < +1
        rs1_i = 32'hFFFF_FFFF; rs2_i = 32'h0000_0001; alusel_i = ALU_SLTU; check_result("SLTU", 32'h0000_0000);
        rs1_i = 32'h0F0F_F0F0; rs2_i = 32'h00FF_00FF; alusel_i = ALU_XOR; check_result("XOR", 32'h0FF0_F00F);
        rs1_i = 32'h8000_0000; rs2_i = 32'd1;       alusel_i = ALU_SRL; check_result("SRL", 32'h4000_0000);
        rs1_i = 32'h8000_0000; rs2_i = 32'd1;       alusel_i = ALU_SRA; check_result("SRA", 32'hC000_0000);
        rs1_i = 32'h0F00_F0F0; rs2_i = 32'h00FF_0F00; alusel_i = ALU_OR;  check_result("OR",  32'h0FFF_FFF0);
        rs1_i = 32'h0F0F_F0F0; rs2_i = 32'h00FF_00FF; alusel_i = ALU_AND; check_result("AND", 32'h000F_00F0);
        rs1_i = 32'h1234_5678; rs2_i = 32'h89AB_CDEF; alusel_i = ALU_PASS; check_result("PASS", 32'h89AB_CDEF);

        //branch target in result for branch/jump opcodes
        pc_i = 32'h2000_0000; imm_i = 32'h0000_0010; rs1_i = 32'h0100_0003;

        //OP_BRANCH -> res = pc + imm, brtaken depends on funct3/breq/brlt
        opcode_i = OP_BRANCH; funct3_i = 3'b000; // BEQ
        breq_i = 1; brlt_i = 0; check_result("BRANCH_BEQ_res", 32'h2000_0010); check_branch_taken("BRANCH_BEQ_t", 1);
        breq_i = 0; check_branch_taken("BRANCH_BEQ_f", 0);

        funct3_i = 3'b001; // BNE
        breq_i = 0; check_branch_taken("BRANCH_BNE_t", 1);
        breq_i = 1; check_branch_taken("BRANCH_BNE_f", 0);

        funct3_i = 3'b100; // BLT (signed)
        breq_i = 0; brlt_i = 1; check_branch_taken("BRANCH_BLT_t", 1);
        brlt_i = 0; check_branch_taken("BRANCH_BLT_f", 0);

        funct3_i = 3'b101; // BGE (signed)
        brlt_i = 0; check_branch_taken("BRANCH_BGE_t", 1);
        brlt_i = 1; check_branch_taken("BRANCH_BGE_f", 0);

        funct3_i = 3'b110; // BLTU (unsigned)
        brlt_i = 1; check_branch_taken("BRANCH_BLTU_t", 1);
        brlt_i = 0; check_branch_taken("BRANCH_BLTU_f", 0);

        funct3_i = 3'b111; // BGEU (unsigned)
        brlt_i = 0; check_branch_taken("BRANCH_BGEU_t", 1);
        brlt_i = 1; check_branch_taken("BRANCH_BGEU_f", 0);

        //JAL -> res = pc + imm, brtaken should remain 0
        opcode_i = OP_JAL; check_result("JAL_res", 32'h2000_0010); check_branch_taken("JAL_brtaken", 0);

        //JALR -> res = (rs1 + imm) & ~1
        opcode_i = OP_JALR; rs1_i = 32'h0000_0101; imm_i = 32'd4; check_result("JALR_res", (32'h0000_0101 + 32'd4) & 32'hFFFF_FFFE); check_branch_taken("JALR_brtaken", 0);

        //random spot checks on ALU arithmetic
        opcode_i = 7'h00; // back to pure ALU outputs
        for (t = 0; t < 100; t++) begin
            rs1_i = $urandom(); rs2_i = $urandom();
            unique case ($urandom_range(0,9))
                0: begin alusel_i = ALU_ADD;  check_result("RAND_ADD", rs1_i + rs2_i); end
                1: begin alusel_i = ALU_SUB;  check_result("RAND_SUB", rs1_i - rs2_i); end
                2: begin alusel_i = ALU_SLL;  check_result("RAND_SLL", rs1_i << rs2_i[4:0]); end
                3: begin alusel_i = ALU_SLT;  check_result("RAND_SLT", signed_lt(rs1_i, rs2_i) ? 32'd1 : 32'd0); end
                4: begin alusel_i = ALU_SLTU; check_result("RAND_SLTU", (rs1_i < rs2_i) ? 32'd1 : 32'd0); end
                5: begin alusel_i = ALU_XOR;  check_result("RAND_XOR", rs1_i ^ rs2_i); end
                6: begin alusel_i = ALU_SRL;  check_result("RAND_SRL", rs1_i >> rs2_i[4:0]); end
                7: begin alusel_i = ALU_SRA;  sa = rs1_i; check_result("RAND_SRA", sa >>> rs2_i[4:0]); end
                8: begin alusel_i = ALU_OR;   check_result("RAND_OR", rs1_i | rs2_i); end
                9: begin alusel_i = ALU_AND;  check_result("RAND_AND", rs1_i & rs2_i); end
            endcase
        end

        $display("[EX_TB] All tests passed.");
        $finish;
    end
endmodule
