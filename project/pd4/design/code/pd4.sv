/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

// pd4.sv
// Single-cycle RV32I core (PD4) with probes.

`include "constants.svh"

module pd4 #(
  parameter int DWIDTH = 32
) (
  input  logic clk,
  input  logic reset
);

  // FETCH
  logic [31:0] f_pc, f_pc_plus_4, f_next_pc, f_insn;

  fetch fetch_0 (
    .clk       (clk),
    .reset     (reset),
    .next_pc   (f_next_pc),
    .pc        (f_pc),
    .pc_plus_4 (f_pc_plus_4)
  );

  imemory imem_0 (
    .clock      (clk),
    .read_write (1'b0),
    .address    (f_pc),
    .data_in    ('0),
    .data_out   (f_insn)
  );

  // ECALL terminates simulation
  always_ff @(posedge clk) begin
    if (!reset && f_insn == INSN_ECALL)
      $finish;
  end

  // DECODE
  logic [6:0]  d_opcode;
  logic [2:0]  d_funct3;
  logic [6:0]  d_funct7;
  logic [4:0]  d_rs1, d_rs2, d_rd;
  logic [31:0] d_imm_i, d_imm_s, d_imm_b, d_imm_u, d_imm_j;
  logic [4:0]  d_shamt;

  decode decode_0 (
    .instr (f_insn),

    .opcode (d_opcode),
    .funct3 (d_funct3),
    .funct7 (d_funct7),
    .rs1    (d_rs1),
    .rs2    (d_rs2),
    .rd     (d_rd),

    .imm_i  (d_imm_i),
    .imm_s  (d_imm_s),
    .imm_b  (d_imm_b),
    .imm_u  (d_imm_u),
    .imm_j  (d_imm_j),
    .shamt  (d_shamt)
  );

  // REGISTER FILE
  logic [31:0] r_rs1_data, r_rs2_data;
  logic        r_we, r_we_final;
  logic [31:0] w_wb_data;

  // instance name must be register_file_0
  register_file #(.DWIDTH(DWIDTH)) register_file_0 (
    .clk      (clk),
    .rs1_addr (d_rs1),
    .rs2_addr (d_rs2),
    .rs1_data (r_rs1_data),
    .rs2_data (r_rs2_data),
    .rd_we    (r_we_final),
    .rd_addr  (d_rd),
    .rd_data  (w_wb_data)
  );

  // CONTROL
  alu_op_e    e_alu_op;
  op_a_sel_e  e_op_a_sel;
  op_b_sel_e  e_op_b_sel;
  wb_sel_e    w_wb_sel;

  logic       m_mem_re;
  logic       m_mem_we;
  mem_size_e  m_mem_size;
  logic       m_mem_unsigned;

  br_type_e   e_br_type;
  logic       e_do_jal, e_do_jalr;

  control control_0 (
    .opcode       (d_opcode),
    .funct3       (d_funct3),
    .funct7       (d_funct7),

    .reg_we       (r_we),
    .alu_op       (e_alu_op),
    .op_a_sel     (e_op_a_sel),
    .op_b_sel     (e_op_b_sel),
    .wb_sel       (w_wb_sel),

    .mem_re       (m_mem_re),
    .mem_we       (m_mem_we),
    .mem_size     (m_mem_size),
    .mem_unsigned (m_mem_unsigned),

    .br_type      (e_br_type),
    .do_jal       (e_do_jal),
    .do_jalr      (e_do_jalr)
  );

  assign r_we_final = (!reset) && r_we && (d_rd != 5'd0);

  // EXECUTE + BRANCH
  logic [31:0] e_imm_sel, e_alu_result, e_next_pc;

  always_comb begin
    // pick imm for ALU; branch_control uses its own imm_* for PC
    unique case (d_opcode)
      OPCODE_LUI,
      OPCODE_AUIPC: e_imm_sel = d_imm_u;
      OPCODE_JAL:    e_imm_sel = d_imm_j;
      OPCODE_JALR:   e_imm_sel = d_imm_i;
      OPCODE_BRANCH: e_imm_sel = d_imm_b;
      OPCODE_LOAD:   e_imm_sel = d_imm_i;
      OPCODE_STORE:  e_imm_sel = d_imm_s;
      OPCODE_OP_IMM: e_imm_sel = d_imm_i;
      default:       e_imm_sel = d_imm_i;
    endcase
  end

  execute execute_0 (
    .pc         (f_pc),
    .rs1_val    (r_rs1_data),
    .rs2_val    (r_rs2_data),
    .imm_val    (e_imm_sel),
    .op_a_sel   (e_op_a_sel),
    .op_b_sel   (e_op_b_sel),
    .alu_op     (e_alu_op),
    .alu_result (e_alu_result)
  );

  branch_control branch_control_0 (
    .pc        (f_pc),
    .rs1_val   (r_rs1_data),
    .rs2_val   (r_rs2_data),

    .imm_b     (d_imm_b),
    .imm_j     (d_imm_j),
    .imm_i     (d_imm_i),

    .br_type   (e_br_type),
    .do_jal    (e_do_jal),
    .do_jalr   (e_do_jalr),

    .next_pc   (e_next_pc)
  );

  assign f_next_pc = e_next_pc;

  // semantic branch-taken flag (for probe only)
  logic br_taken_exec;

  always_comb begin
    logic branch_cond;

    branch_cond = 1'b0;
    unique case (e_br_type)
      BR_BEQ : branch_cond = (r_rs1_data == r_rs2_data);
      BR_BNE : branch_cond = (r_rs1_data != r_rs2_data);
      BR_BLT : branch_cond = ($signed(r_rs1_data) <  $signed(r_rs2_data));
      BR_BGE : branch_cond = ($signed(r_rs1_data) >= $signed(r_rs2_data));
      BR_BLTU: branch_cond = (r_rs1_data <  r_rs2_data);
      BR_BGEU: branch_cond = (r_rs1_data >= r_rs2_data);
      default: branch_cond = 1'b0;
    endcase

    br_taken_exec = branch_cond;
  end

  // MEMORY
  logic [31:0] m_addr, m_store_data, m_load_raw;
  logic [1:0]  m_addr_low;
  logic [7:0]  store_byte;

  assign m_addr     = e_alu_result;
  assign m_addr_low = m_addr[1:0];

  always_comb begin
    store_byte = r_rs2_data[7:0];

    unique case (m_mem_size)
      MEM_SIZE_BYTE: begin
        unique case (m_addr_low)
          2'd0: store_byte = r_rs2_data[7:0];
          2'd1: store_byte = r_rs2_data[15:8];
          2'd2: store_byte = r_rs2_data[23:16];
          2'd3: store_byte = r_rs2_data[31:24];
          default: store_byte = r_rs2_data[7:0];
        endcase
      end

      // for HALF/WORD we still write one byte (LSByte) as per interface
      default: store_byte = r_rs2_data[7:0];
    endcase
  end

  assign m_store_data = {24'b0, store_byte};

  dmemory dmem_0 (
    .clock      (clk),
    .read_write (m_mem_we),
    .address    (m_addr),
    .data_in    (m_store_data),
    .data_out   (m_load_raw)
  );

  logic [1:0] mem_size3;
  always_comb begin
    mem_size3 = MEM_SIZE_HALF; // default for non-mem instructions

    unique case (d_opcode)
      OPCODE_LOAD: begin
        unique case (d_funct3)
          FUNCT3_LB,
          FUNCT3_LBU: mem_size3 = MEM_SIZE_BYTE;
          FUNCT3_LH,
          FUNCT3_LHU: mem_size3 = MEM_SIZE_HALF;
          FUNCT3_LW:  mem_size3 = MEM_SIZE_WORD;
          default:     mem_size3 = MEM_SIZE_BYTE;
        endcase
      end

      OPCODE_STORE: begin
        unique case (d_funct3)
          FUNCT3_SB: mem_size3 = MEM_SIZE_BYTE;
          FUNCT3_SH: mem_size3 = MEM_SIZE_HALF;
          FUNCT3_SW: mem_size3 = MEM_SIZE_WORD;
          default:   mem_size3 = MEM_SIZE_BYTE;
        endcase
      end

      default: mem_size3 = MEM_SIZE_BYTE;
    endcase
  end

  // WRITEBACK
  logic [31:0] w_load_ext;

  writeback writeback_0 (
    .wb_sel        (w_wb_sel),
    .pc_plus_4     (f_pc_plus_4),
    .alu_result    (e_alu_result),
    .load_data_raw (m_load_raw),
    .mem_size      (m_mem_size),
    .mem_unsigned  (m_mem_unsigned),
    .addr_low      (m_addr_low),
    .wb_data       (w_wb_data),
    .load_data_ext (w_load_ext)
  );

  // ---------------------------------------------------------------------------
  // PROBES
  // ---------------------------------------------------------------------------

  // Fetch
  logic [31:0] F_PC, F_INSN;
  assign F_PC   = f_pc;
  assign F_INSN = f_insn;

  // Decode
  logic [31:0] D_PC, D_IMM;
  logic [6:0]  D_OPCODE, D_FUNCT7;
  logic [4:0]  D_RD, D_RS1, D_RS2, D_SHAMT;
  logic [2:0]  D_FUNCT3;

  assign D_PC     = f_pc;
  assign D_OPCODE = d_opcode;
  assign D_RD     = d_rd;
  assign D_RS1    = d_rs1;
  assign D_RS2    = d_rs2;
  assign D_FUNCT3 = d_funct3;
  assign D_FUNCT7 = d_funct7;
  assign D_SHAMT  = d_shamt;

  always_comb begin
    unique case (d_opcode)
      OPCODE_LUI,
      OPCODE_AUIPC: D_IMM = d_imm_u;
      OPCODE_JAL:    D_IMM = d_imm_j;
      OPCODE_JALR,
      OPCODE_LOAD,
      OPCODE_OP_IMM: D_IMM = d_imm_i;
      OPCODE_STORE:  D_IMM = d_imm_s;
      OPCODE_BRANCH: D_IMM = d_imm_b;
      default:       D_IMM = 32'b0;
    endcase
  end

  // Regfile probes
  logic        R_WRITE_ENABLE;
  logic [4:0]  R_WRITE_DESTINATION;
  logic [31:0] R_WRITE_DATA;
  logic [4:0]  R_READ_RS1, R_READ_RS2;
  logic [31:0] R_READ_RS1_DATA, R_READ_RS2_DATA;

  assign R_WRITE_ENABLE      = (!reset) && r_we;
  assign R_WRITE_DESTINATION = d_rd;
  assign R_WRITE_DATA        = w_wb_data;
  assign R_READ_RS1          = d_rs1;
  assign R_READ_RS2          = d_rs2;
  assign R_READ_RS1_DATA     = r_rs1_data;
  assign R_READ_RS2_DATA     = r_rs2_data;

  // Execute probes
  logic [31:0] E_PC, E_ALU_RES;
  logic        E_BR_TAKEN;

  assign E_PC       = f_pc;
  assign E_ALU_RES  = e_alu_result;
  assign E_BR_TAKEN = br_taken_exec;

  // Memory probes
  logic [31:0] M_PC, M_ADDRESS, M_DATA;
  logic [1:0]  M_SIZE_ENCODED;

  assign M_PC           = f_pc;
  assign M_ADDRESS      = m_addr;
  assign M_DATA         = m_load_raw; // current value in D-mem at address
  assign M_SIZE_ENCODED = mem_size3;

  // Writeback probes
  logic [31:0] W_PC, W_DATA;
  logic        W_ENABLE;
  logic [4:0]  W_DESTINATION;

  assign W_PC          = f_pc;
  assign W_ENABLE      = (!reset) && r_we;
  assign W_DESTINATION = d_rd;
  assign W_DATA        = w_wb_data;

endmodule
