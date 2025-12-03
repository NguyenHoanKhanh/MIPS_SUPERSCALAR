`ifndef CHOOSE_COMPS_V
`define CHOOSE_COMPS_V
`include "./source/header.vh"

module choose_comps (
    cc_i_ce_1, cc_i_jr_1, cc_i_pc_1, cc_i_jal_1, cc_i_imm_1, cc_i_funct_1, cc_i_opcode_1, cc_i_reg_dst_1,
    cc_i_alu_src_1, cc_i_data_rs_1, cc_i_data_rt_1, cc_i_addr_rd_1, cc_i_addr_rs_1, cc_i_addr_rt_1, 
    cc_i_jal_addr_1, cc_i_memwrite_1, cc_i_memtoreg_1, cc_i_reg_write_1,
    cc_i_ce_2, cc_i_jr_2, cc_i_pc_2, cc_i_jal_2, cc_i_imm_2, cc_i_funct_2, cc_i_opcode_2, cc_i_reg_dst_2,
    cc_i_alu_src_2, cc_i_data_rs_2, cc_i_data_rt_2, cc_i_addr_rd_2, cc_i_addr_rs_2, cc_i_addr_rt_2, 
    cc_i_jal_addr_2, cc_i_memwrite_2, cc_i_memtoreg_2, cc_i_reg_write_2, 
    cc_o_ce, cc_o_jr, cc_o_pc, cc_o_jal, cc_o_imm, cc_o_funct, cc_o_opcode, cc_o_reg_dst, cc_o_alu_src, 
    cc_o_data_rs, cc_o_data_rt, cc_o_addr_rd, cc_o_addr_rs, cc_o_addr_rt, cc_o_jal_addr, cc_o_memwrite, 
    cc_o_memtoreg, cc_o_reg_write, cc_o_we, cc_o_ce_1
);
    input cc_i_ce_1;
    input cc_i_reg_dst_1;
    input cc_i_alu_src_1;
    input cc_i_memwrite_1;
    input cc_i_memtoreg_1;
    input cc_i_reg_write_1;
    input cc_i_jr_1, cc_i_jal_1;
    input [`PC_WIDTH - 1 : 0] cc_i_pc_1;
    input [`IMM_WIDTH - 1 : 0] cc_i_imm_1;
    input [`FUNCT_WIDTH - 1 : 0] cc_i_funct_1;
    input [`OPCODE_WIDTH - 1 : 0] cc_i_opcode_1;
    input [`JUMP_WIDTH - 1 : 0] cc_i_jal_addr_1;
    input [`DWIDTH - 1 : 0] cc_i_data_rs_1, cc_i_data_rt_1;
    input [`AWIDTH - 1 : 0] cc_i_addr_rd_1, cc_i_addr_rs_1, cc_i_addr_rt_1;

    input cc_i_ce_2;
    input cc_i_reg_dst_2;
    input cc_i_alu_src_2;
    input cc_i_memwrite_2;
    input cc_i_memtoreg_2;
    input cc_i_reg_write_2;
    input cc_i_jr_2, cc_i_jal_2;
    input [`PC_WIDTH - 1 : 0] cc_i_pc_2;
    input [`IMM_WIDTH - 1 : 0] cc_i_imm_2;
    input [`FUNCT_WIDTH - 1 : 0] cc_i_funct_2;
    input [`OPCODE_WIDTH - 1 : 0] cc_i_opcode_2;
    input [`JUMP_WIDTH - 1 : 0] cc_i_jal_addr_2;
    input [`DWIDTH - 1 : 0] cc_i_data_rs_2, cc_i_data_rt_2;
    input [`AWIDTH - 1 : 0] cc_i_addr_rd_2, cc_i_addr_rs_2, cc_i_addr_rt_2;

    output cc_o_we;
    output cc_o_ce_1;
    output cc_o_ce;
    output cc_o_reg_dst;
    output cc_o_alu_src;
    output cc_o_memwrite;
    output cc_o_memtoreg;
    output cc_o_reg_write;
    output cc_o_jr, cc_o_jal;
    output [`PC_WIDTH - 1 : 0] cc_o_pc;
    output [`IMM_WIDTH - 1 : 0] cc_o_imm;
    output [`FUNCT_WIDTH - 1 : 0] cc_o_funct;
    output [`OPCODE_WIDTH - 1 : 0] cc_o_opcode;
    output [`JUMP_WIDTH - 1 : 0] cc_o_jal_addr;
    output [`DWIDTH - 1 : 0] cc_o_data_rs, cc_o_data_rt;
    output [`AWIDTH - 1 : 0] cc_o_addr_rd, cc_o_addr_rs, cc_o_addr_rt;

    assign cc_o_we = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? 1'b1 : 1'b0;
    assign cc_o_ce_1 = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? 1'b0 : cc_i_ce_1;
    assign cc_o_ce = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_ce_1 : cc_i_ce_2;
    assign cc_o_reg_dst = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_reg_dst_1 : cc_i_reg_dst_2;
    assign cc_o_alu_src = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_alu_src_1 : cc_i_alu_src_2;
    assign cc_o_memwrite = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_memwrite_1 : cc_i_memwrite_2;
    assign cc_o_memtoreg = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_memtoreg_1 : cc_i_memtoreg_2;
    assign cc_o_reg_write = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_reg_write_1 : cc_i_reg_write_2;
    assign cc_o_jr = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_jr_1 : cc_i_jr_2;
    assign cc_o_jal = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_jal_1 : cc_i_jal_2;
    assign cc_o_pc = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_pc_1 : cc_i_pc_2;
    assign cc_o_imm = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_imm_1 : cc_i_imm_2;
    assign cc_o_funct = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_funct_1 : cc_i_funct_2;
    assign cc_o_opcode = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_opcode_1 : cc_i_opcode_2;
    assign cc_o_jal_addr = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_jal_addr_1 : cc_i_jal_addr_2;
    assign cc_o_data_rs = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_data_rs_1 : cc_i_data_rs_2;
    assign cc_o_data_rt = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_data_rt_1 : cc_i_data_rt_2;
    assign cc_o_addr_rd = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_addr_rd_1 : cc_i_addr_rd_2;
    assign cc_o_addr_rs = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_addr_rs_1 : cc_i_addr_rs_2;
    assign cc_o_addr_rt = (((cc_i_addr_rd_2 == cc_i_addr_rs_1) && (cc_i_addr_rd_2 != cc_i_addr_rt_1)) || 
                        ((cc_i_addr_rd_2 != cc_i_addr_rs_1) && (cc_i_addr_rd_2 == cc_i_addr_rt_1))) ? cc_i_addr_rt_1 : cc_i_addr_rt_2;
endmodule
`endif 