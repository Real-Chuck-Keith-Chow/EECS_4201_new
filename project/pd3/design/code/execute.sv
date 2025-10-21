//============================================================
// execute.sv (inlined): ALU + branch target/decision (comb)
//============================================================
`include "constants.svh"

module execute (
  input  logic [31:0] pc_i,

  input  logic [31:0] rs1_i,
  input  logic [31:0] rhs_i,         // rs2 or immediate (selected in top)

  input  logic [2:0]  funct3_i,
  input  logic [6:0]  funct7_i,      // reserved for SUB/SRA if needed
  input  logic [3:0]  alu_sel_i,     // from control/igen

  input  logic        is_branch_i,
  input  logic        is_jal_i,
  input  logic        is_jalr_i,

  input  logic [31:0] imm_b_i,       // B-type formed
  input  logic [31:0] imm_j_i,       // J-type
  input  logic [31:0] imm_i_i,       // I-type (JALR target)

  output logic [31:0] alu_res_o,
  output logic        br_taken_o,
  output logic [31:0] redirect_target_o
);
  // ---------- ALU ----------
  logic [31:0] add_res  = rs1_i + rhs_i;
  logic [31:0] sub_res  = rs1_i - rhs_i;
  logic [31:0] and_res  = rs1_i & rhs_i;
  logic [31:0] or_res   = rs1_i | rhs_i;
  logic [31:0] xor_res  = rs1_i ^ rhs_i;
  logic [4:0]  shamt    = rhs_i[4:0];
  logic [31:0] sll_res  = rs1_i << shamt;
  logic [31:0] srl_res  = rs1_i >> shamt;
  logic [31:0] sra_res  = $signed(rs1_i) >>> shamt;
  logic        slt_res  = $signed(rs1_i) <  $signed(rhs_i);
  logic        sltu_res = rs1_i < rhs_i;

  always_comb begin
    unique case (alu_sel_i)
      ALU_ADD : alu_res_o = add_res;
      ALU_SUB : alu_res_o = sub_res;
      ALU_AND : alu_res_o = and_res;
      ALU_OR  : alu_res_o = or_res;
      ALU_XOR : alu_res_o = xor_res;
      ALU_SLL : alu_res_o = sll_res;
      ALU_SRL : alu_res_o = srl_res;
      ALU_SRA : alu_res_o = sra_res;
      ALU_SLT : alu_res_o = {31'b0, slt_res};
      ALU_SLTU: alu_res_o = {31'b0, sltu_res};
      default : alu_res_o = 32'h0000_0000;
    endcase
  end

  // ---------- Branch decision ----------
  logic beq  = (rs1_i == rhs_i);
  logic bne  = ~beq;
  logic blt  = $signed(rs1_i) <  $signed(rhs_i);
  logic bge  = ~blt;
  logic bltu = (rs1_i < rhs_i);
  logic bgeu = ~bltu;

  always_comb begin
    br_taken_o = 1'b0;
    if (is_branch_i) begin
      unique case (funct3_i)
        F3_BEQ  : br_taken_o = beq;
        F3_BNE  : br_taken_o = bne;
        F3_BLT  : br_taken_o = blt;
        F3_BGE  : br_taken_o = bge;
        F3_BLTU : br_taken_o = bltu;
        F3_BGEU : br_taken_o = bgeu;
        default : br_taken_o = 1'b0;
      endcase
    end
  end

  // ---------- Next PC target ----------
  // Branch: PC + imm_b; JAL: PC + imm_j; JALR: (rs1 + imm_i) & ~1
  logic [31:0] branch_tgt = pc_i + imm_b_i;
  logic [31:0] jal_tgt    = pc_i + imm_j_i;
  logic [31:0] jalr_tgt   = (rs1_i + imm_i_i) & 32'hFFFF_FFFE;

  always_comb begin
    if (is_branch_i && br_taken_o)      redirect_target_o = branch_tgt;
    else if (is_jal_i)                  redirect_target_o = jal_tgt;
    else if (is_jalr_i)                 redirect_target_o = jalr_tgt;
    else                                redirect_target_o = 32'h0;
  end

  // synthesis translate_off
  always @* begin
    if (^pc_i  === 1'bx) $warning("execute: X on pc_i");
    if (^rs1_i === 1'bx) $warning("execute: X on rs1_i");
    if (^rhs_i === 1'bx) $warning("execute: X on rhs_i");
  end
  // synthesis translate_on
endmodule
