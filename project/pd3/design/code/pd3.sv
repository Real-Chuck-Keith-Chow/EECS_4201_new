/*
 * Module: pd3
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd3 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

    localparam logic [AWIDTH-1:0] MEM_BASE_ADDR = 32'h0100_0000;
    localparam logic [AWIDTH-1:0] WORD_BYTES = {{(AWIDTH-3){1'b0}}, 3'd4};

    `ifndef LINE_COUNT
        `define LINE_COUNT 1024
    `endif

    `ifndef MEM_PATH
        `define MEM_PATH "test.x"
    `endif

    typedef logic [DWIDTH-1:0] word_t;

    //fetch + Instruction memory
    logic [AWIDTH-1:0] fetch_pc;
    logic [DWIDTH-1:0] imem_data;
    logic [DWIDTH-1:0] fetch_insn;

    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(MEM_BASE_ADDR)
    ) fetch_inst (
        .clk(clk),
        .rst(reset),
        .pc_o(fetch_pc),
        .insn_o()
    );

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(MEM_BASE_ADDR)
    ) instr_mem (
        .clk(clk),
        .rst(reset),
        .addr_i(fetch_pc),
        .data_i('0),
        .read_en_i(1'b1),
        .write_en_i(1'b0),
        .data_o(imem_data)
    );

    assign fetch_insn = imem_data;

    //decode stage
    logic [AWIDTH-1:0] decode_pc;
    logic [DWIDTH-1:0] decode_insn;
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
    ) decode_inst (
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
    ) control_inst (
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

    //register file (signal declare)
    word_t rf_rs1_data;
    word_t rf_rs2_data;

    //branch control
    logic branch_eq;
    logic branch_lt;

    branch_control #(
        .DWIDTH(DWIDTH)
    ) branch_control_inst (
        .opcode_i(decode_opcode),
        .funct3_i(decode_funct3),
        .rs1_i(rf_rs1_data),
        .rs2_i(rf_rs2_data),
        .breq_o(branch_eq),
        .brlt_o(branch_lt)
    );


    //ALU operand selection
    word_t alu_op_a;
    word_t alu_op_b;

    assign alu_op_a = rs1sel ? decode_pc : rf_rs1_data;
    assign alu_op_b = immsel ? decode_imm : rf_rs2_data;

    //execute (ALU)
    word_t alu_result;
    logic branch_taken;

    alu #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) alu_inst (
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

    //data memory (associative array)
    word_t data_mem [logic [AWIDTH-1:0]];

    initial begin : init_data_mem
        integer idx;
        word_t init_words [0:`LINE_COUNT-1];
        $readmemh(`MEM_PATH, init_words);
        for (idx = 0; idx < `LINE_COUNT; idx++) begin
            data_mem[MEM_BASE_ADDR + (idx * DWIDTH/8)] = init_words[idx];
        end
    end

    logic [AWIDTH-1:0] mem_addr;
    logic [AWIDTH-1:0] mem_addr_aligned;
    logic [1:0] mem_byte_offset;
    logic mem_addr_valid;
    word_t mem_word;
    word_t load_data;

    assign mem_addr = alu_result;
    assign mem_addr_aligned = {mem_addr[AWIDTH-1:2], 2'b00};
    assign mem_byte_offset = mem_addr[1:0];
    assign mem_addr_valid = !$isunknown(mem_addr_aligned);

    always_comb begin
        if (!mem_addr_valid) begin
            mem_word = '0;
        end else if (data_mem.exists(mem_addr_aligned)) begin
            mem_word = data_mem[mem_addr_aligned];
        end else begin
            mem_word = '0;
        end
    end

    always_comb begin
        load_data = '0;
        if (memren && mem_addr_valid) begin
            int shift_bytes;
            logic [7:0] byte_val;
            logic [15:0] half_val;
            shift_bytes = mem_byte_offset * 8;
            byte_val = (mem_word >> shift_bytes) & 8'hFF;
            half_val = mem_byte_offset[1] ? mem_word[31:16] : mem_word[15:0];
            unique case (decode_funct3)
                3'b000: load_data = {{24{byte_val[7]}}, byte_val};  //LB
                3'b001: load_data = {{16{half_val[15]}}, half_val}; //LH
                3'b010: load_data = mem_word;                       //LW
                3'b100: load_data = {24'b0, byte_val};              //LBU
                3'b101: load_data = {16'b0, half_val};              //LHU
                default: load_data = mem_word;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (!reset && memwren && mem_addr_valid) begin
            word_t current_word;
            word_t updated_word;
            int shift_bytes;
            current_word = mem_word;
            updated_word = current_word;
            shift_bytes = mem_byte_offset * 8;
            unique case (decode_funct3)
                3'b000: begin // SB
                    word_t byte_mask;
                    byte_mask = ~(word_t'(32'hFF) << shift_bytes);
                    updated_word = (current_word & byte_mask) | (word_t'({{24{1'b0}}, rf_rs2_data[7:0]}) << shift_bytes);
                end
                3'b001: begin // SH
                    int shift_half;
                    word_t half_mask;
                    shift_half = mem_byte_offset[1] ? 16 : 0;
                    half_mask = ~(word_t'(32'hFFFF) << shift_half);
                    updated_word = (current_word & half_mask) | (word_t'({{16{1'b0}}, rf_rs2_data[15:0]}) << shift_half);
                end
                default: begin // SW
                    updated_word = rf_rs2_data;
                end
            endcase
            data_mem[mem_addr_aligned] = updated_word;
        end
    end

    //writeback selection
    word_t pc_plus4;
    word_t wb_data;

    assign pc_plus4 = decode_pc + WORD_BYTES;

    always_comb begin
        unique case (wbsel)
            2'b00: wb_data = alu_result;
            2'b01: wb_data = load_data;
            2'b10: wb_data = pc_plus4;
            default: wb_data = alu_result;
        endcase
    end

    //register file with writeback connections
    register_file #(
        .DWIDTH(DWIDTH)
    ) registers (
        .clk(clk),
        .rst(reset),
        .rs1_i(decode_rs1),
        .rs2_i(decode_rs2),
        .rd_i(decode_rd),
        .datawb_i(wb_data),
        .regwren_i(regwren),
        .rs1data_o(rf_rs1_data),
        .rs2data_o(rf_rs2_data)
    );

endmodule : pd3
