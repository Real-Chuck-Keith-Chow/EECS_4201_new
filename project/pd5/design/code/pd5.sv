/*
 * Module: pd5
 *
 * Description: Top level module - 5-stage RV32I pipelined CPU.
 * Stages: IF (Fetch), ID (Decode), EX (Execute), MEM (Memory), WB (Writeback)
 * Features: Data forwarding, load-use stall, branch/jump flush
 */
`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // Wire declarations for probe signals

    // Fetch stage probes
    logic [AWIDTH-1:0] probe_f_pc;
    logic [DWIDTH-1:0] probe_f_insn;
    
    // Decode stage probes
    logic [AWIDTH-1:0] probe_d_pc;
    logic [6:0] probe_d_opcode;
    logic [4:0] probe_d_rd;
    logic [2:0] probe_d_funct3;
    logic [4:0] probe_d_rs1;
    logic [4:0] probe_d_rs2;
    logic [6:0] probe_d_funct7;
    logic [DWIDTH-1:0] probe_d_imm;
    logic [4:0] probe_d_shamt;
    
    // Register file read probes (in Decode stage)
    logic [4:0] probe_r_read_rs1;
    logic [4:0] probe_r_read_rs2;
    logic [DWIDTH-1:0] probe_r_read_rs1_data;
    logic [DWIDTH-1:0] probe_r_read_rs2_data;
    
    // Execute stage probes
    logic [AWIDTH-1:0] probe_e_pc;
    logic [DWIDTH-1:0] probe_e_alu_res;
    logic probe_e_br_taken;
    
    // Memory stage probes
    logic [AWIDTH-1:0] probe_m_pc;
    logic [AWIDTH-1:0] probe_m_address;
    logic [1:0] probe_m_size_encoded;
    logic [DWIDTH-1:0] probe_m_data;
    
    // Writeback stage probes
    logic [AWIDTH-1:0] probe_w_pc;
    logic probe_w_enable;
    logic [4:0] probe_w_destination;
    logic [DWIDTH-1:0] probe_w_data;

    // Pipeline control signals
    logic stall_if;           // Stall IF stage
    logic stall_id;           // Stall ID stage
    logic flush_id;           // Flush ID stage (insert bubble)
    logic flush_ex;           // Flush EX stage (insert bubble)
    
    // Forwarding select signals
    logic [1:0] forward_a;    // Forwarding for ALU input A
    logic [1:0] forward_b;    // Forwarding for ALU input B
    logic [1:0] forward_br_a; // Forwarding for branch comparator A
    logic [1:0] forward_br_b; // Forwarding for branch comparator B

    // IF Stage Signals
    logic [AWIDTH-1:0] if_pc;
    logic [AWIDTH-1:0] if_pc_next;
    logic [DWIDTH-1:0] if_insn;
    
    // IF/ID Pipeline Register
    reg [AWIDTH-1:0] id_pc;
    reg [DWIDTH-1:0] id_insn;
    
    // ID Stage Signals
    // Decoded instruction fields
    logic [6:0] id_opcode;
    logic [4:0] id_rd;
    logic [2:0] id_funct3;
    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [6:0] id_funct7;
    logic [4:0] id_shamt;
    logic [DWIDTH-1:0] id_imm;
    logic [2:0] id_imm_type;
    
    // Control signals from decode
    logic [3:0] id_alu_op;
    logic [1:0] id_alu_src1;
    logic [1:0] id_alu_src2;
    logic id_reg_write;
    logic id_mem_read;
    logic id_mem_write;
    logic [1:0] id_wb_src;
    logic id_branch;
    logic id_jump;
    logic id_jalr;
    
    // Register file read data
    logic [DWIDTH-1:0] id_rs1_data;
    logic [DWIDTH-1:0] id_rs2_data;
    
    // ID/EX Pipeline Register
    reg [AWIDTH-1:0] ex_pc;
    reg [DWIDTH-1:0] ex_rs1_data;
    reg [DWIDTH-1:0] ex_rs2_data;
    reg [DWIDTH-1:0] ex_imm;
    reg [4:0] ex_rd;
    reg [4:0] ex_rs1;
    reg [4:0] ex_rs2;
    reg [2:0] ex_funct3;
    reg [6:0] ex_funct7;
    reg [4:0] ex_shamt;
    reg [3:0] ex_alu_op;
    reg [1:0] ex_alu_src1;
    reg [1:0] ex_alu_src2;
    reg ex_reg_write;
    reg ex_mem_read;
    reg ex_mem_write;
    reg [1:0] ex_wb_src;
    reg ex_branch;
    reg ex_jump;
    reg ex_jalr;
    reg [6:0] ex_opcode;
    
    // EX Stage Signals
    logic [DWIDTH-1:0] ex_alu_operand_a;
    logic [DWIDTH-1:0] ex_alu_operand_b;
    logic [DWIDTH-1:0] ex_alu_result;
    logic ex_branch_taken;
    logic [AWIDTH-1:0] ex_branch_target;
    logic [DWIDTH-1:0] ex_forwarded_rs1;
    logic [DWIDTH-1:0] ex_forwarded_rs2;
    
    // EX/MEM Pipeline Register
    reg [AWIDTH-1:0] mem_pc;
    reg [DWIDTH-1:0] mem_alu_result;
    reg [DWIDTH-1:0] mem_rs2_data;
    reg [4:0] mem_rd;
    reg [4:0] mem_rs2;           // Track rs2 for store data forwarding
    reg [2:0] mem_funct3;
    reg mem_reg_write;
    reg mem_mem_read;
    reg mem_mem_write;
    reg [1:0] mem_wb_src;
    reg [6:0] mem_opcode;
    
    // MEM Stage Signals
    logic [DWIDTH-1:0] mem_read_data;
    logic [1:0] mem_size;
    logic mem_sign_extend;
    logic [DWIDTH-1:0] mem_store_data;
    logic [DWIDTH-1:0] mem_forward_data;  // Value to use when forwarding from MEM stage
    logic [AWIDTH-1:0] mem_pc_plus4;       // Used for JAL/JALR forwarding
    
    // MEM/WB Pipeline Register
    reg [AWIDTH-1:0] wb_pc;
    reg [DWIDTH-1:0] wb_alu_result;
    reg [DWIDTH-1:0] wb_mem_data;
    reg [4:0] wb_rd;
    reg wb_reg_write;
    reg [1:0] wb_wb_src;
    
    // WB Stage Signals
    logic [DWIDTH-1:0] wb_write_data;
    
    // Memory instance for instruction fetch (read-only)
    logic [DWIDTH-1:0] data_out;  // For instruction fetch
    
    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) imem (
        .clk(clk),
        .rst(reset),
        .addr_i(if_pc),
        .data_i(32'b0),
        .read_en_i(1'b1),
        .write_en_i(1'b0),
        .size_i(2'b10),  // Word access
        .sign_extend_i(1'b0),
        .data_o(if_insn)
    );
    
    assign data_out = if_insn;  // For program termination logic
    
    // Data Memory instance
    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) dmem (
        .clk(clk),
        .rst(reset),
        .addr_i(mem_alu_result),
        .data_i(mem_store_data),
        .read_en_i(mem_mem_read),
        .write_en_i(mem_mem_write),
        .size_i(mem_size),
        .sign_extend_i(mem_sign_extend),
        .data_o(mem_read_data)
    );
    
    // Register File instance
    logic [DWIDTH-1:0] rf_rs1_data;      // Register file output (with write-first bypass)
    logic [DWIDTH-1:0] rf_rs2_data;      // Register file output (with write-first bypass)
    logic [DWIDTH-1:0] rf_rs1_data_raw;  // Raw register file output (for probes)
    logic [DWIDTH-1:0] rf_rs2_data_raw;  // Raw register file output (for probes)
    
    register_file #(
        .DWIDTH(DWIDTH)
    ) register_file_0 (
        .clk(clk),
        .rst(reset),
        .rs1_addr_i(id_rs1),
        .rs1_data_o(rf_rs1_data),
        .rs2_addr_i(id_rs2),
        .rs2_data_o(rf_rs2_data),
        .rs1_data_raw_o(rf_rs1_data_raw),
        .rs2_data_raw_o(rf_rs2_data_raw),
        .write_en_i(wb_reg_write),
        .rd_addr_i(wb_rd),
        .rd_data_i(wb_write_data)
    );
    
    // WB-to-ID Forwarding (Internal Register File Bypass)
    // If WB is writing to the same register that ID is reading, bypass the
    // stale register file value and use the new value from WB directly.
    // This handles the case where reg file write (sequential) hasn't completed
    // but we need the new value in ID (combinational read).
    always_comb begin
        // RS1 bypass
        if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == id_rs1)) begin
            id_rs1_data = wb_write_data;
        end else begin
            id_rs1_data = rf_rs1_data;
        end
        
        // RS2 bypass
        if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == id_rs2)) begin
            id_rs2_data = wb_write_data;
        end else begin
            id_rs2_data = rf_rs2_data;
        end
    end
    
    // Instruction Decoder instance
    decode decoder (
        .insn_i(id_insn),
        .opcode_o(id_opcode),
        .rd_o(id_rd),
        .funct3_o(id_funct3),
        .rs1_o(id_rs1),
        .rs2_o(id_rs2),
        .funct7_o(id_funct7),
        .shamt_o(id_shamt)
    );
    
    // Control Unit instance
    control ctrl (
        .opcode_i(id_opcode),
        .funct3_i(id_funct3),
        .funct7_i(id_funct7),
        .alu_op_o(id_alu_op),
        .alu_src1_o(id_alu_src1),
        .alu_src2_o(id_alu_src2),
        .reg_write_o(id_reg_write),
        .mem_read_o(id_mem_read),
        .mem_write_o(id_mem_write),
        .wb_src_o(id_wb_src),
        .branch_o(id_branch),
        .jump_o(id_jump),
        .jalr_o(id_jalr),
        .imm_type_o(id_imm_type)
    );
    
    // Immediate Generator instance
    igen imm_gen (
        .insn_i(id_insn),
        .imm_type_i(id_imm_type),
        .imm_o(id_imm)
    );
    
    // ALU instance
    execute alu (
        .alu_op_i(ex_alu_op),
        .operand_a_i(ex_alu_operand_a),
        .operand_b_i(ex_alu_operand_b),
        .shamt_i(ex_shamt),
        .alu_result_o(ex_alu_result)
    );
    
    // Branch Comparator instance
    logic branch_cmp_result;
    branch_control br_ctrl (
        .funct3_i(ex_funct3),
        .rs1_data_i(ex_forwarded_rs1),
        .rs2_data_i(ex_forwarded_rs2),
        .branch_i(ex_branch),
        .branch_taken_o(branch_cmp_result)
    );
    
    // Writeback MUX instance
    writeback wb_mux (
        .pc_i(wb_pc),
        .alu_res_i(wb_alu_result),
        .memory_data_i(wb_mem_data),
        .wb_src_i(wb_wb_src),
        .writeback_data_o(wb_write_data)
    );
    
    // IF Stage: Fetch
    
    // keep the PC moving unless reset or stall kicks in
    always_ff @(posedge clk) begin
        if (reset) begin
            if_pc <= PC_START;
        end else if (!stall_if) begin
            if_pc <= if_pc_next;
        end
    end
    
    // cheap next-PC chooser (branch wins, otherwise just +4)
    always_comb begin
        if (ex_branch_taken || ex_jump) begin
            if_pc_next = ex_branch_target;
        end else begin
            if_pc_next = if_pc + 4;
        end
    end
    
    // IF/ID Pipeline Register
    // stash fetched insn unless flushed/stalled
    always_ff @(posedge clk) begin
        if (reset) begin
            id_pc <= 32'b0;  // Bubble: PC=0 on reset
            id_insn <= 32'b0;  // Bubble: all zeros on reset (opcode=0)
        end else if (flush_id) begin
            // Insert bubble on flush - keep existing id_pc (the flushed instruction's PC)
            // id_pc stays unchanged (holds value of instruction that was in ID)
            id_insn <= NOP_INSN;  // NOP instruction (0x00000013)
        end else if (!stall_id) begin
            id_pc <= if_pc;
            id_insn <= if_insn;
        end
        // If stalled or flushed, id_pc holds current value
    end
    
    // ID/EX Pipeline Register
    // lots of bookkeeping here; keep the values flowing forward
    always_ff @(posedge clk) begin
        if (reset) begin
            // Reset: all zeros including PC and opcode
            ex_pc <= 32'b0;
            ex_rs1_data <= 32'b0;
            ex_rs2_data <= 32'b0;
            ex_imm <= 32'b0;
            ex_rd <= 5'b0;
            ex_rs1 <= 5'b0;
            ex_rs2 <= 5'b0;
            ex_funct3 <= 3'b0;
            ex_funct7 <= 7'b0;
            ex_shamt <= 5'b0;
            ex_alu_op <= ALU_ADD;
            ex_alu_src1 <= ALU_SRC_REG;
            ex_alu_src2 <= ALU_SRC_REG;
            ex_reg_write <= 1'b0;
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_wb_src <= WB_SRC_ALU;
            ex_branch <= 1'b0;
            ex_jump <= 1'b0;
            ex_jalr <= 1'b0;
            ex_opcode <= 7'b0;
        end else if (flush_ex) begin
            // Flush: preserve PC for visibility, insert NOP that writes to x0
            // Pattern checker expects reg_write=1 with rd=x0 (harmless write)
            ex_pc <= id_pc;  // Keep the flushed PC
            ex_rs1_data <= 32'b0;
            ex_rs2_data <= 32'b0;
            ex_imm <= 32'b0;
            ex_rd <= 5'b0;           // Destination = x0 (writes are ignored)
            ex_rs1 <= 5'b0;
            ex_rs2 <= 5'b0;
            ex_funct3 <= 3'b0;
            ex_funct7 <= 7'b0;
            ex_shamt <= 5'b0;
            ex_alu_op <= ALU_ADD;
            ex_alu_src1 <= ALU_SRC_ZERO;  // ALU computes 0+0=0
            ex_alu_src2 <= ALU_SRC_ZERO;
            ex_reg_write <= 1'b1;    // Enable write (but to x0, so harmless)
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_wb_src <= WB_SRC_ALU;
            ex_branch <= 1'b0;
            ex_jump <= 1'b0;
            ex_jalr <= 1'b0;
            ex_opcode <= 7'b0010011;  // NOP opcode (I-type ALU)
        end else if (stall_id) begin
            // Load-use stall: insert bubble into EX (instruction stays in ID)
            // Bubble is a NOP with no side effects
            ex_pc <= id_pc;  // Show stalled instruction's PC for debugging
            ex_rs1_data <= 32'b0;
            ex_rs2_data <= 32'b0;
            ex_imm <= 32'b0;
            ex_rd <= 5'b0;           // No destination
            ex_rs1 <= 5'b0;
            ex_rs2 <= 5'b0;
            ex_funct3 <= 3'b0;
            ex_funct7 <= 7'b0;
            ex_shamt <= 5'b0;
            ex_alu_op <= ALU_ADD;
            ex_alu_src1 <= ALU_SRC_ZERO;
            ex_alu_src2 <= ALU_SRC_ZERO;
            ex_reg_write <= 1'b0;    // No register write for stall bubble
            ex_mem_read <= 1'b0;
            ex_mem_write <= 1'b0;
            ex_wb_src <= WB_SRC_ALU;
            ex_branch <= 1'b0;
            ex_jump <= 1'b0;
            ex_jalr <= 1'b0;
            ex_opcode <= 7'b0010011;  // NOP opcode
        end else begin
            ex_pc <= id_pc;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm <= id_imm;
            ex_rd <= id_rd;
            ex_rs1 <= id_rs1;
            ex_rs2 <= id_rs2;
            ex_funct3 <= id_funct3;
            ex_funct7 <= id_funct7;
            ex_shamt <= id_shamt;
            ex_alu_op <= id_alu_op;
            ex_alu_src1 <= id_alu_src1;
            ex_alu_src2 <= id_alu_src2;
            ex_reg_write <= id_reg_write;
            ex_mem_read <= id_mem_read;
            ex_mem_write <= id_mem_write;
            ex_wb_src <= id_wb_src;
            ex_branch <= id_branch;
            ex_jump <= id_jump;
            ex_jalr <= id_jalr;
            ex_opcode <= id_opcode;
        end
    end
    
    // EX Stage: Execute
    
    // Forwarding MUX for RS1 (just a tiny mux tree)
    always_comb begin : forward_rs1_mux
        // Prefer EX/MEM data when legal, otherwise fall back to WB or original reg.
        case (forward_a)
            FWD_EX_MEM: ex_forwarded_rs1 = mem_forward_data;
            FWD_MEM_WB: ex_forwarded_rs1 = wb_write_data;
            default:    ex_forwarded_rs1 = ex_rs1_data;
        endcase
    end
    
    // Forwarding MUX for RS2 (same idea)
    always_comb begin : forward_rs2_mux
        // Same priority scheme for rs2.
        case (forward_b)
            FWD_EX_MEM: ex_forwarded_rs2 = mem_forward_data;
            FWD_MEM_WB: ex_forwarded_rs2 = wb_write_data;
            default:    ex_forwarded_rs2 = ex_rs2_data;
        endcase
    end
    
    // ALU operand A selection
    always_comb begin
        case (ex_alu_src1)
            ALU_SRC_REG:  ex_alu_operand_a = ex_forwarded_rs1;
            ALU_SRC_PC:   ex_alu_operand_a = ex_pc;
            ALU_SRC_ZERO: ex_alu_operand_a = 32'b0;
            default:      ex_alu_operand_a = ex_forwarded_rs1;
        endcase
    end
    
    // ALU operand B selection
    always_comb begin
        case (ex_alu_src2)
            ALU_SRC_REG:  ex_alu_operand_b = ex_forwarded_rs2;
            ALU_SRC_IMM:  ex_alu_operand_b = ex_imm;
            ALU_SRC_PC:   ex_alu_operand_b = ex_pc;
            ALU_SRC_ZERO: ex_alu_operand_b = 32'b0;
            default:      ex_alu_operand_b = ex_forwarded_rs2;
        endcase
    end
    
    // Branch taken logic
    assign ex_branch_taken = branch_cmp_result;
    
    // Branch/Jump target calculation
    always_comb begin : branch_target_calc
        // JALR needs the LSB cleared, everything else already came from the ALU.
        if (ex_jalr) begin
            // JALR: target = (rs1 + imm) & ~1
            ex_branch_target = (ex_forwarded_rs1 + ex_imm) & ~32'b1;
        end else begin
            // JAL/Branch: target = PC + imm (already calculated by ALU for branches)
            ex_branch_target = ex_alu_result;
        end
    end
    
    // EX/MEM Pipeline Register
    // capture ALU results heading into MEM
    always_ff @(posedge clk) begin
        if (reset) begin
            mem_pc <= 32'b0;  // Bubble: PC=0 on reset
            mem_alu_result <= 32'b0;
            mem_rs2_data <= 32'b0;
            mem_rd <= 5'b0;
            mem_rs2 <= 5'b0;
            mem_funct3 <= 3'b0;
            mem_reg_write <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_wb_src <= WB_SRC_ALU;
            mem_opcode <= 7'b0;  // Opcode=0 for reset bubbles
        end else begin
            mem_pc <= ex_pc;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data <= ex_forwarded_rs2;
            mem_rd <= ex_rd;
            mem_rs2 <= ex_rs2;
            mem_funct3 <= ex_funct3;
            mem_reg_write <= ex_reg_write;
            mem_mem_read <= ex_mem_read;
            mem_mem_write <= ex_mem_write;
            mem_wb_src <= ex_wb_src;
            mem_opcode <= ex_opcode;
        end
    end
    
    // MEM Stage: Memory Access
    
    // Memory size encoding from funct3
    // figure out store data size the casual way
    always_comb begin
        case (mem_funct3[1:0])
            2'b00: mem_size = 2'b00;  // Byte
            2'b01: mem_size = 2'b01;  // Halfword
            2'b10: mem_size = 2'b10;  // Word
            default: mem_size = 2'b10;
        endcase
    end
    
    // Sign extension for loads
    assign mem_sign_extend = ~mem_funct3[2];  // LB, LH are signed; LBU, LHU are unsigned
    
    // Store data forwarding (WB -> MEM for store after load)
    // Forward from WB to MEM when store's rs2 matches WB's rd
    // store data forwarding (mainly for WB -> MEM), nothing fancy
    always_comb begin
        if (mem_mem_write && wb_reg_write && (wb_rd != 5'b0) && (wb_rd == mem_rs2)) begin
            // Forward from WB to store data
            mem_store_data = wb_write_data;
        end else begin
            mem_store_data = mem_rs2_data;
        end
    end

    // Precompute PC+4 once for MEM stage (needed for JAL/JALR forwarding)
    assign mem_pc_plus4 = mem_pc + 32'd4;

    // Select the actual value that will be written back from MEM stage.
    // Non-load instructions can be forwarded directly to EX/branch compare.
    always_comb begin
        case (mem_wb_src)
            WB_SRC_PC4: mem_forward_data = mem_pc_plus4;
            default:    mem_forward_data = mem_alu_result;
        endcase
    end
    
    // MEM/WB Pipeline Register
    // final latch before writeback happens
    always_ff @(posedge clk) begin
        if (reset) begin
            wb_pc <= 32'b0;  // Bubble: PC=0 on reset
            wb_alu_result <= 32'b0;
            wb_mem_data <= 32'b0;
            wb_rd <= 5'b0;
            wb_reg_write <= 1'b0;
            wb_wb_src <= WB_SRC_ALU;
        end else begin
            wb_pc <= mem_pc;
            wb_alu_result <= mem_alu_result;
            wb_mem_data <= mem_read_data;
            wb_rd <= mem_rd;
            wb_reg_write <= mem_reg_write;
            wb_wb_src <= mem_wb_src;
        end
    end
    
    // Hazard Detection Unit (Load-Use Stall)
    logic load_use_hazard;
    
    // Determine if ID stage instruction uses rs1 and/or rs2
    // JAL and U-type (LUI, AUIPC) don't use source registers
    logic id_uses_rs1;
    logic id_uses_rs2;
    
    // quick and dirty decoding of who actually uses rs1/rs2
    always_comb begin
        // Default: assume both are used
        id_uses_rs1 = 1'b1;
        id_uses_rs2 = 1'b1;
        
        case (id_opcode)
            OP_LUI, OP_AUIPC, OP_JAL: begin
                // No source registers
                id_uses_rs1 = 1'b0;
                id_uses_rs2 = 1'b0;
            end
            OP_JALR, OP_LOAD, OP_IMM: begin
                // Only uses rs1
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b0;
            end
            // OP_REG, OP_BRANCH, OP_STORE use both rs1 and rs2
            default: begin
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b1;
            end
        endcase
    end
    
    // hazard unit just checks for load-use and hollers
    always_comb begin : load_use_detector
        // default to "no stall" and only flip when the next insn needs the load.
        load_use_hazard = 1'b0;
        
        // Check if EX stage has a load and ID stage uses its result
        if (ex_mem_read && (ex_rd != 5'b0)) begin
            // Only check hazard for source registers that are actually used
            if ((id_uses_rs1 && (ex_rd == id_rs1)) || (id_uses_rs2 && (ex_rd == id_rs2))) begin
                load_use_hazard = 1'b1;
            end
        end
    end
    
    // Stall signals
    assign stall_if = load_use_hazard;
    assign stall_id = load_use_hazard;
    
    // Flush signals
    // On branch/jump: flush both IF/ID and ID/EX
    // Note: load_use_hazard uses stall_id to insert a stall bubble (reg_write=0)
    //       branch/jump uses flush_ex to insert a flush bubble (reg_write=1, rd=0)
    assign flush_id = ex_branch_taken || ex_jump;  // Flush IF/ID on branch/jump
    assign flush_ex = ex_branch_taken || ex_jump;  // Flush ID/EX on branch/jump only (NOT load-use)

    // Forwarding Unit
    
    // Forward to EX stage ALU operand A (RS1)
    // Note: Don't forward from MEM if it's a load (mem_mem_read), because the
    // loaded data isn't available yet. Loads use WB forwarding after stall.
    always_comb begin
        forward_a = FWD_NONE;
        
        // EX/MEM hazard (priority) - only for non-load instructions
        if (mem_reg_write && !mem_mem_read && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
            forward_a = FWD_EX_MEM;
        end
        // MEM/WB hazard
        else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
            forward_a = FWD_MEM_WB;
        end
    end
    
    // Forward to EX stage ALU operand B (RS2)
    always_comb begin
        forward_b = FWD_NONE;
        
        // EX/MEM hazard (priority) - only for non-load instructions
        if (mem_reg_write && !mem_mem_read && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
            forward_b = FWD_EX_MEM;
        end
        // MEM/WB hazard
        else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
            forward_b = FWD_MEM_WB;
        end
    end
    
    // Probe Assignments
    
    // F stage probes
    assign probe_f_pc = if_pc;
    assign probe_f_insn = if_insn;
    
    // D stage probes  
    assign probe_d_pc = id_pc;
    assign probe_d_opcode = id_opcode;
    assign probe_d_rd = id_rd;
    assign probe_d_funct3 = id_funct3;
    assign probe_d_rs1 = id_rs1;
    assign probe_d_rs2 = id_rs2;
    assign probe_d_funct7 = id_funct7;
    assign probe_d_imm = id_imm;
    assign probe_d_shamt = id_shamt;
    
    // R stage probes (register file reads - in decode stage)
    assign probe_r_read_rs1 = id_rs1;
    assign probe_r_read_rs2 = id_rs2;
    assign probe_r_read_rs1_data = rf_rs1_data_raw;  // Show raw register file output (no bypass)
    assign probe_r_read_rs2_data = rf_rs2_data_raw;  // Show raw register file output (no bypass)
    
    // E stage probes
    assign probe_e_pc = ex_pc;
    assign probe_e_alu_res = ex_alu_result;
    assign probe_e_br_taken = ex_branch_taken || ex_jump;
    
    // M stage probes
    assign probe_m_pc = mem_pc;
    assign probe_m_address = mem_alu_result;
    assign probe_m_size_encoded = mem_size;
    // Always show the store data (rs2 value) - for non-stores this will be the rs2 field
    assign probe_m_data = mem_store_data;
    
    // W stage probes
    assign probe_w_pc = wb_pc;
    assign probe_w_enable = wb_reg_write;
    assign probe_w_destination = wb_rd;
    assign probe_w_data = wb_write_data;

    // Program Termination Logic
reg is_program = 0;
always_ff @(posedge clk) begin
        if (data_out == 32'h00000073) $finish;  // Terminate on ECALL
        if (data_out == 32'h00008067) is_program = 1;  // RET instruction marks program test
    if (is_program && (register_file_0.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
end

endmodule : pd5
