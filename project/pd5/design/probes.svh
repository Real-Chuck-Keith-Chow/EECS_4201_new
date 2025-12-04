// Quick shorthands so the testbench can watch internal pipeline state.
`define PROBE_F_PC          probe_f_pc
`define PROBE_F_INSN        probe_f_insn

`define PROBE_D_PC          probe_d_pc
`define PROBE_D_OPCODE      probe_d_opcode
`define PROBE_D_RD          probe_d_rd
`define PROBE_D_FUNCT3      probe_d_funct3
`define PROBE_D_RS1         probe_d_rs1
`define PROBE_D_RS2         probe_d_rs2
`define PROBE_D_FUNCT7      probe_d_funct7
`define PROBE_D_IMM         probe_d_imm
`define PROBE_D_SHAMT       probe_d_shamt

`define PROBE_R_WRITE_ENABLE      wb_reg_write
`define PROBE_R_WRITE_DESTINATION wb_rd
`define PROBE_R_WRITE_DATA        wb_write_data
`define PROBE_R_READ_RS1          probe_r_read_rs1
`define PROBE_R_READ_RS2          probe_r_read_rs2
`define PROBE_R_READ_RS1_DATA     probe_r_read_rs1_data
`define PROBE_R_READ_RS2_DATA     probe_r_read_rs2_data

`define PROBE_E_PC                probe_e_pc
`define PROBE_E_ALU_RES           probe_e_alu_res
`define PROBE_E_BR_TAKEN          probe_e_br_taken

`define PROBE_M_PC                probe_m_pc
`define PROBE_M_ADDRESS           probe_m_address
`define PROBE_M_SIZE_ENCODED      probe_m_size_encoded
`define PROBE_M_DATA              probe_m_data

`define PROBE_W_PC                probe_w_pc
`define PROBE_W_ENABLE            probe_w_enable
`define PROBE_W_DESTINATION       probe_w_destination
`define PROBE_W_DATA              probe_w_data

// Hook the top module name so the verification harness knows what to instantiate.
`define TOP_MODULE  pd5 


