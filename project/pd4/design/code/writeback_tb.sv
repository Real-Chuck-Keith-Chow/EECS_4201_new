`timescale 1ns/1ps
import constants_pkg::*;

module writeback_tb;

  //DUT io
  logic [ADDR_WIDTH-1:0] pc_i;
  logic [DATA_WIDTH-1:0] alu_res_i;
  logic [DATA_WIDTH-1:0] memory_data_i;
  logic [1:0]        wbsel_i;
  logic              pcsel_i;
  logic              brtaken_i;
  logic [DATA_WIDTH-1:0] writeback_data_o;
  logic [ADDR_WIDTH-1:0] next_pc_o;

  int error_count = 0;

  //DUT
  writeback #(.DWIDTH(DATA_WIDTH), .AWIDTH(ADDR_WIDTH)) dut (
    .pc_i(pc_i),
    .alu_res_i(alu_res_i),
    .memory_data_i(memory_data_i),
    .wbsel_i(wbsel_i),
    .pcsel_i(pcsel_i),
    .brtaken_i(brtaken_i),
    .writeback_data_o(writeback_data_o),
    .next_pc_o(next_pc_o)
  );

  //apply vector
  task automatic apply_vec(
      input logic [ADDR_WIDTH-1:0] pc,
      input logic [DATA_WIDTH-1:0] alu_res,
      input logic [DATA_WIDTH-1:0] mem,
      input logic [1:0]        wbsel,
      input logic              pcsel,
      input logic              brtaken
  );
  begin
    pc_i          = pc;
    alu_res_i     = alu_res;
    memory_data_i = mem;
    wbsel_i       = wbsel;
    pcsel_i       = pcsel;
    brtaken_i     = brtaken;
    #1; // allow combinational settle
  end
  endtask

  //check helper
  task automatic check_case(
      input string                 name,
      input logic [DATA_WIDTH-1:0]     exp_wb,
      input logic [ADDR_WIDTH-1:0]     exp_npc
  );
  begin
    #1;
    if (writeback_data_o !== exp_wb || next_pc_o !== exp_npc) begin
      $display("FAIL: %s", name);
      $display("  got  wb=%h  npc=%h", writeback_data_o, next_pc_o);
      $display("  exp  wb=%h  npc=%h", exp_wb,           exp_npc);
      error_count++;
    end else begin
      $display("PASS: %s", name);
    end
  end
  endtask

  //test sequence
  initial begin
    //wbsel=00 -> ALU, next=pc+4
    apply_vec(32'h1000_0000, 32'h0000_00AA, 32'hDEAD_BEEF, 2'b00, 1'b0, 1'b0);
    check_case("wbsel=00 (ALU), next=pc+4",
               32'h0000_00AA, 32'h1000_0004);

    //wbsel=01 -> MEM, next=pc+4
    apply_vec(32'h2000_0000, 32'h1111_1111, 32'h2222_2222, 2'b01, 1'b0, 1'b0);
    check_case("wbsel=01 (MEM), next=pc+4",
               32'h2222_2222, 32'h2000_0004);

    //wbsel=10 -> PC+4, next=pc+4
    apply_vec(32'h3000_0000, 32'hAAAA_AAAA, 32'hBBBB_BBBB, 2'b10, 1'b0, 1'b0);
    check_case("wbsel=10 (PC+4), next=pc+4",
               32'h3000_0004, 32'h3000_0004);

    //wbsel=11 -> default ALU, next=pc+4
    apply_vec(32'h4000_0000, 32'h1234_5678, 32'hBBBB_BBBB, 2'b11, 1'b0, 1'b0);
    check_case("wbsel=11 (default->ALU), next=pc+4",
               32'h1234_5678, 32'h4000_0004);

    //pcsel=1 -> next=ALU, wb per wbsel (00 => ALU)
    apply_vec(32'h5000_0000, 32'h5555_0008, 32'h0, 2'b00, 1'b1, 1'b0);
    check_case("pcsel=1 -> next=ALU",
               32'h5555_0008, 32'h5555_0008);

    //brtaken=1 -> next=ALU, wb per wbsel (01 => MEM)
    apply_vec(32'h6000_0000, 32'h7777_000C, 32'hABCD_EF01, 2'b01, 1'b0, 1'b1);
    check_case("brtaken=1 -> next=ALU; wb=MEM",
               32'hABCD_EF01, 32'h7777_000C);

    //pcsel=1 & brtaken=1 -> next=ALU, wb per wbsel (10 => PC+4)
    apply_vec(32'h7000_0000, 32'h0000_0040, 32'hFACE_CAFE, 2'b10, 1'b1, 1'b1);
    check_case("pcsel&brtaken -> next=ALU; wb=PC+4",
               32'h7000_0004, 32'h0000_0040);

    if (error_count == 0) begin
      $display("\nALL TESTS PASSED");
    end else begin
      $display("\nFAILED with %0d errors", error_count);
      $fatal(1);
    end
    $finish;
  end

endmodule
