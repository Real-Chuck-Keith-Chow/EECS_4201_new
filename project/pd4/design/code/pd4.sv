import constants_pkg::*;

/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd4 #(
    parameter int AWIDTH = ADDR_WIDTH,
    parameter int DWIDTH = DATA_WIDTH)(
    input logic clk,
    input logic reset
);

    typedef logic [DWIDTH-1:0] word_t;


    //fetch stage
    logic [AWIDTH-1:0] fetch_pc;
    word_t fetch_insn;
    logic [AWIDTH-1:0] next_pc;

    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(MEM_BASE_ADDR)
    ) fetch_0 (
        .clk(clk),
        .rst(reset),
        .next_pc_i(next_pc),
        .pc_o(fetch_pc),
        .insn_o(fetch_insn)
    );

    //decode stage
    logic [AWIDTH-1:0] decode_pc;
    word_t decode_insn;
    logic [6:0] decode_opcode;
    logic [4:0] decode_rd;
    logic [4:0] decode_rs1;
    logic [4:0] decode_rs2;
    logic [6:0] decode_funct7;
    logic [2:0] decode_funct3;
    logic [4:0] decode_shamt;
    word_t decode_imm;

    decode #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) decode_0 (
        .clk(clk),
        .rst(reset),
        .insn_i(fetch_insn),
        .pc_i(fetch_pc),
        .pc_o(decode_pc),
        .insn_o(decode_insn),
        .opcode_o(decode_opcode),
        .rd_o(decode_rd),
        .rs1_o(decode_rs1),
        .rs2_o(decode_rs2),
        .funct7_o(decode_funct7),
        .funct3_o(decode_funct3),
        .shamt_o(decode_shamt),
        .imm_o(decode_imm)
    );

    //control stage
    logic pcsel;
    logic immsel;
    logic regwren;
    logic rs1sel;
    logic rs2sel;
    logic memren;
    logic memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

    control #(
        .DWIDTH(DWIDTH)
    ) control_0 (
        .insn_i(decode_insn),
        .opcode_i(decode_opcode),
        .funct7_i(decode_funct7),
        .funct3_i(decode_funct3),
        .pcsel_o(pcsel),
        .immsel_o(immsel),
        .regwren_o(regwren),
        .rs1sel_o(rs1sel),
        .rs2sel_o(rs2sel),
        .memren_o(memren),
        .memwren_o(memwren),
        .wbsel_o(wbsel),
        .alusel_o(alusel)
    );

    //register file
    word_t rf_rs1_data;
    word_t rf_rs2_data;

    word_t writeback_data;

    register_file #(
        .DWIDTH(DWIDTH)
    ) register_file_0 (
        .clk(clk),
        .rst(reset),
        .rs1_i(decode_rs1),
        .rs2_i(decode_rs2),
        .rd_i(decode_rd),
        .datawb_i(writeback_data),
        .regwren_i(regwren),
        .rs1data_o(rf_rs1_data),
        .rs2data_o(rf_rs2_data)
    );

    //branch control
    logic branch_eq;
    logic branch_lt;

    branch_control #(
        .DWIDTH(DWIDTH)
    ) branch_control_0 (
        .opcode_i(decode_opcode),
        .funct3_i(decode_funct3),
        .rs1_i(rf_rs1_data),
        .rs2_i(rf_rs2_data),
        .breq_o(branch_eq),
        .brlt_o(branch_lt)
    );

    //execute (ALU)
    word_t alu_op_a;
    word_t alu_op_b;
    word_t alu_result;
    logic branch_taken;

    assign alu_op_a = rs1sel ? decode_pc : rf_rs1_data;
    assign alu_op_b = immsel ? decode_imm : rf_rs2_data;

    alu #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) alu_0 (
        .pc_i(decode_pc),
        .rs1_i(alu_op_a),
        .rs2_i(alu_op_b),
        .funct3_i(decode_funct3),
        .funct7_i(decode_funct7),
        .opcode_i(decode_opcode),
        .alusel_i(alusel),
        .imm_i(decode_imm),
        .breq_i(branch_eq),
        .brlt_i(branch_lt),
        .res_o(alu_result),
        .brtaken_o(branch_taken)
    );


    //memory signals
    logic [1:0] mem_size;
    logic mem_unsigned_load;
    word_t dmem_read_data;
    word_t dmem_probe_data;
    logic [AWIDTH-1:0] mem_address;

    assign mem_address = alu_result[AWIDTH-1:0];

    always_comb begin
        mem_size = decode_funct3[1:0];   //default: 13:12
        mem_unsigned_load = 1'b1;
        unique case (decode_opcode)
            OP_LOAD: begin
                unique case (decode_funct3)
                    3'b000: begin //LB
                        mem_size = MEM_SIZE_BYTE;
                        mem_unsigned_load = 1'b0;
                    end
                    3'b001: begin //LH
                        mem_size = MEM_SIZE_HALF;
                        mem_unsigned_load = 1'b0;
                    end
                    3'b010: begin //LW
                        mem_size = MEM_SIZE_WORD;
                        mem_unsigned_load = 1'b0;
                    end
                    3'b100: begin //LBU
                        mem_size = MEM_SIZE_BYTE;
                        mem_unsigned_load = 1'b1;
                    end
                    3'b101: begin //LHU
                        mem_size = MEM_SIZE_HALF;
                        mem_unsigned_load = 1'b1;
                    end
                    default: begin
                        mem_size = MEM_SIZE_WORD;
                        mem_unsigned_load = 1'b0;
                    end
                endcase
            end
            OP_STORE: begin
                mem_unsigned_load = 1'b1;
                unique case (decode_funct3)
                    3'b000: mem_size = MEM_SIZE_BYTE; //SB
                    3'b001: mem_size = MEM_SIZE_HALF; //SH
                    default: mem_size = MEM_SIZE_WORD; //SW
                endcase
            end
            default: begin
                mem_size = decode_funct3[1:0];
                mem_unsigned_load = 1'b1;
            end
        endcase
    end

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(MEM_BASE_ADDR)
    ) data_memory (
        .clk(clk),
        .rst(reset),
        .addr_i(mem_address),
        .data_i(rf_rs2_data),
        .read_en_i(memren),
        .write_en_i(memwren),
        .size_i(mem_size),
        .unsigned_load_i(mem_unsigned_load),
        .data_o(dmem_read_data),
        .probe_data_o(dmem_probe_data)
    );

    //write-back stage
    writeback #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) writeback_0 (
        .pc_i(decode_pc),
        .alu_res_i(alu_result),
        .memory_data_i(dmem_read_data),
        .wbsel_i(wbsel),
        .pcsel_i(pcsel),
        .brtaken_i(branch_taken),
        .writeback_data_o(writeback_data),
        .next_pc_o(next_pc)
    );

    //helper signal
    word_t mem_stage_data;
    assign mem_stage_data = dmem_probe_data;

    word_t data_out;
    assign data_out = fetch_insn;

    //program termination logic
    reg is_program = 0;
    always_ff @(posedge clk) begin
        if (data_out == 32'h00000073) $finish;  //ecall
        if (data_out == 32'h00008067) is_program = 1;  //ret instruction
        if (is_program && (register_file_0.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
    end

endmodule : pd4
