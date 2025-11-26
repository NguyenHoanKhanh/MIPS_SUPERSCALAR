`ifndef MUX_COMPONENTS_V
`define MUX_COMPONENTS_V
`include "./source/header.vh"

module mux_comps (
    choose_comp, m1_i_ce, m1_i_pc, m1_i_reg_dst, m1_i_alu_src, m1_i_reg_write, m1_i_jr, m1_i_jal, m1_i_memtoreg,
    m1_i_memwrite, m1_i_imm, m1_i_funct, m1_i_jal_addr, m1_i_opcode, m1_i_data_rs, m1_i_data_rt, m1_i_addr_rd, 
    m1_i_addr_rs, m1_i_addr_rt, m2_i_ce, m2_i_reg_dst, m2_i_alu_src, m2_i_reg_write, m2_i_jr, m2_i_jal, m2_i_memtoreg,
    m2_i_memwrite, m2_i_imm, m2_i_pc, m2_i_funct, m2_i_jal_addr, m2_i_opcode, m2_i_data_rs, m2_i_data_rt, m2_i_addr_rd, m2_i_addr_rs,
    m2_i_addr_rt, mc_o_ce, mc_o_pc, mc_o_reg_dst, mc_o_alu_src, mc_o_reg_write, mc_o_jr, mc_o_jal, mc_o_memtoreg, mc_o_memwrite, 
    mc_o_imm, mc_o_funct, mc_o_jal_addr, mc_o_opcode, mc_o_data_rs, mc_o_data_rt, mc_o_addr_rd, mc_o_addr_rs, mc_o_addr_rt
);
    input choose_comp;

    input m1_i_ce;
    input m1_i_reg_dst;
    input m1_i_alu_src;
    input m1_i_reg_write;
    input m1_i_jr, m1_i_jal;
    input [`PC_WIDTH - 1 : 0] m1_i_pc;
    input m1_i_memtoreg, m1_i_memwrite;
    input [`IMM_WIDTH - 1 : 0] m1_i_imm;
    input [`FUNCT_WIDTH - 1 : 0] m1_i_funct;
    input [`JUMP_WIDTH - 1 : 0] m1_i_jal_addr;
    input [`OPCODE_WIDTH - 1 : 0] m1_i_opcode;
    input [`DWIDTH - 1 : 0] m1_i_data_rs, m1_i_data_rt;
    input [`AWIDTH - 1 : 0] m1_i_addr_rd, m1_i_addr_rs, m1_i_addr_rt;
    
    input m2_i_ce;
    input m2_i_reg_dst;
    input m2_i_alu_src;
    input m2_i_reg_write;
    input m2_i_jr, m2_i_jal;
    input [`PC_WIDTH - 1 : 0] m2_i_pc;
    input m2_i_memtoreg, m2_i_memwrite;
    input [`IMM_WIDTH - 1 : 0] m2_i_imm;
    input [`FUNCT_WIDTH - 1 : 0] m2_i_funct;
    input [`JUMP_WIDTH - 1 : 0] m2_i_jal_addr;
    input [`OPCODE_WIDTH - 1 : 0] m2_i_opcode;
    input [`DWIDTH - 1 : 0] m2_i_data_rs, m2_i_data_rt;
    input [`AWIDTH - 1 : 0] m2_i_addr_rd, m2_i_addr_rs, m2_i_addr_rt;

    output reg mc_o_ce;
    output reg mc_o_reg_dst;
    output reg mc_o_alu_src;
    output reg mc_o_reg_write;
    output reg mc_o_jr, mc_o_jal;
    output reg [`PC_WIDTH - 1 : 0] mc_o_pc;
    output reg mc_o_memtoreg, mc_o_memwrite;
    output reg [`IMM_WIDTH - 1 : 0] mc_o_imm;
    output reg [`FUNCT_WIDTH - 1 : 0] mc_o_funct;
    output reg [`JUMP_WIDTH - 1 : 0] mc_o_jal_addr;
    output reg [`OPCODE_WIDTH - 1 : 0] mc_o_opcode;
    output reg [`DWIDTH - 1 : 0] mc_o_data_rs, mc_o_data_rt;
    output reg [`AWIDTH - 1 : 0] mc_o_addr_rd, mc_o_addr_rs, mc_o_addr_rt;

    always @(*) begin
        mc_o_jr = 1'b0;
        mc_o_ce = 1'b0;
        mc_o_jal = 1'b0;
        mc_o_reg_dst = 1'b0;
        mc_o_alu_src = 1'b0;
        mc_o_memtoreg = 1'b0;
        mc_o_memwrite = 1'b0;
        mc_o_reg_write = 1'b0;
        mc_o_pc = {`PC_WIDTH{1'b0}};
        mc_o_imm = {`IMM_WIDTH{1'b0}};
        mc_o_data_rs = {`DWIDTH{1'b0}};
        mc_o_data_rt = {`DWIDTH{1'b0}};
        mc_o_addr_rd = {`AWIDTH{1'b0}};
        mc_o_addr_rs = {`AWIDTH{1'b0}};
        mc_o_addr_rt = {`AWIDTH{1'b0}};
        mc_o_funct = {`FUNCT_WIDTH{1'b0}};
        mc_o_jal_addr = {`JUMP_WIDTH{1'b0}};
        mc_o_opcode = {`OPCODE_WIDTH{1'b0}};
        if (choose_comp) begin
            mc_o_jr = m1_i_jr;
            mc_o_ce = m1_i_ce;
            mc_o_pc = m1_i_pc;
            mc_o_jal = m1_i_jal;
            mc_o_imm = m1_i_imm;
            mc_o_funct = m1_i_funct;
            mc_o_opcode = m1_i_opcode;
            mc_o_reg_dst = m1_i_reg_dst;
            mc_o_alu_src = m1_i_alu_src;
            mc_o_data_rs = m1_i_data_rs;
            mc_o_data_rt = m1_i_data_rt;
            mc_o_addr_rd = m1_i_addr_rd;
            mc_o_addr_rs = m1_i_addr_rs;
            mc_o_addr_rt = m1_i_addr_rt;
            mc_o_memtoreg = m1_i_memtoreg;
            mc_o_memwrite = m1_i_memwrite;
            mc_o_jal_addr = m1_i_jal_addr;
            mc_o_reg_write = m1_i_reg_write;
        end
        else begin
            mc_o_jr = m2_i_jr;
            mc_o_ce = m2_i_ce;
            mc_o_pc = m2_i_pc;
            mc_o_jal = m2_i_jal;
            mc_o_imm = m2_i_imm;
            mc_o_funct = m2_i_funct;
            mc_o_opcode = m2_i_opcode;
            mc_o_reg_dst = m2_i_reg_dst;
            mc_o_alu_src = m2_i_alu_src;
            mc_o_data_rs = m2_i_data_rs;
            mc_o_data_rt = m2_i_data_rt;
            mc_o_addr_rd = m2_i_addr_rd;
            mc_o_addr_rs = m2_i_addr_rs;
            mc_o_addr_rt = m2_i_addr_rt;
            mc_o_memtoreg = m2_i_memtoreg;
            mc_o_memwrite = m2_i_memwrite;
            mc_o_jal_addr = m2_i_jal_addr;
            mc_o_reg_write = m2_i_reg_write;
        end
    end
endmodule
`endif 