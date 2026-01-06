// ----  Probes  ----
`define PROBE_F_PC               fetch_pc
`define PROBE_F_INSN             fetch_insn

`define PROBE_D_PC               decode_pc
`define PROBE_D_OPCODE           decode_opcode
`define PROBE_D_RD               decode_rd
`define PROBE_D_FUNCT3           decode_funct3
`define PROBE_D_RS1              decode_rs1
`define PROBE_D_RS2              decode_rs2
`define PROBE_D_FUNCT7           decode_funct7
`define PROBE_D_IMM              decode_imm
`define PROBE_D_SHAMT            decode_shamt

`define PROBE_R_WRITE_ENABLE      regwren
`define PROBE_R_WRITE_DESTINATION decode_rd
`define PROBE_R_WRITE_DATA        writeback_data
`define PROBE_R_READ_RS1          decode_rs1
`define PROBE_R_READ_RS2          decode_rs2
`define PROBE_R_READ_RS1_DATA     rf_rs1_data
`define PROBE_R_READ_RS2_DATA     rf_rs2_data

`define PROBE_E_PC                decode_pc
`define PROBE_E_ALU_RES           alu_result
`define PROBE_E_BR_TAKEN          branch_taken

`define PROBE_M_PC                decode_pc
`define PROBE_M_ADDRESS           mem_address
`define PROBE_M_SIZE_ENCODED      mem_size
`define PROBE_M_DATA              mem_stage_data

`define PROBE_W_PC                decode_pc
`define PROBE_W_ENABLE            regwren
`define PROBE_W_DESTINATION       decode_rd
`define PROBE_W_DATA              writeback_data

// ----  Probes  ----

// ----  Top module  ----
`define TOP_MODULE  pd4 
// ----  Top module  ----

