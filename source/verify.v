`ifndef VERIFY_V
`define VERIFY_V
`include "./source/imem.v"
`include "./source/mux_des.v"
`include "./source/check_dup_rd.v"
`include "./source/decoder_stage.v"
`include "./source/program_counter.v"
`include "./source/execute_stage.v"
`include "./source/queue_instr.v"
module verify (
    v_clk, v_rst, v_i_ce, v_o_instr_1, v_o_instr_2, v_o_pc_1, v_o_pc_2,
    v_o_change_instr
);
    input v_clk, v_rst;
    input v_i_ce;
    output v_o_change_instr;
    output [`PC_WIDTH - 1 : 0] v_o_pc_1, v_o_pc_2;
    output [`IWIDTH - 1 : 0] v_o_instr_1, v_o_instr_2;

    wire [`PC_WIDTH - 1 : 0] pc_i_pc_1, pc_i_pc_2;
    wire pc_i_change_pc_1, pc_i_change_pc_2;
    wire pc_im_o_ce;
    program_counter pc (
        .pc_i_clk(v_clk), 
        .pc_i_rst(v_rst), 
        .pc_i_ce(v_i_ce), 
        .pc_i_pc_1(pc_i_pc_1),
        .pc_i_pc_2(pc_i_pc_2), 
        .pc_i_change_pc_1(pc_i_change_pc_1),
        .pc_i_change_pc_2(pc_i_change_pc_2), 
        .pc_i_change_instr(v_o_change_instr),
        .pc_o_pc_1(v_o_pc_1),
        .pc_o_pc_2(v_o_pc_2), 
        .pc_o_ce(pc_im_o_ce)
    );

    wire im_o_ce;
    wire im_i_change_instr;
    imem im (
        .im_clk(v_clk), 
        .im_rst(v_rst), 
        .im_i_ce(pc_im_o_ce), 
        .im_i_addr_1(v_o_pc_1),
        .im_i_addr_2(v_o_pc_2), 
        .im_o_instr_1(v_o_instr_1), 
        .im_o_instr_2(v_o_instr_2), 
        .im_o_ce(im_o_ce)
    );

    wire ds1_o_ce;
    wire ds1_o_jr;
    wire ds1_o_jal;
    wire ds1_o_branch;
    wire ds1_o_alu_src;
    wire ds1_o_reg_write;
    wire ds1_mx1_o_reg_dst;
    wire [`AWIDTH - 1 : 0] v_i_addr_rd_1;
    wire [`DWIDTH - 1 : 0] v_i_data_rd_1;
    wire [`IMM_WIDTH - 1 : 0] ds1_o_imm;
    wire ds1_o_memtoreg, ds1_o_memwrite;
    wire [`AWIDTH - 1 : 0] ds1_o_addr_rs;
    wire [`FUNCT_WIDTH - 1 : 0] ds1_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds1_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds1_o_jal_addr;
    wire [`DWIDTH - 1 : 0] ds1_o_data_rs, ds1_o_data_rt;
    wire [`AWIDTH - 1 : 0] ds1_mx1_o_addr_rd, ds1_mx1_o_addr_rt;

    decoder_stage ds_1 (
        .ds_i_clk(v_clk), 
        .ds_i_rst(v_rst), 
        .ds_i_ce(im_o_ce), 
        .ds_i_instr(v_o_instr_1), 
        .ds_i_reg_write(v_i_reg_write), 
        .ds_i_addr_rd(v_i_addr_rd_1), 
        .ds_i_data_rd(v_i_data_rd_1), 
        .ds_o_addr_rd(ds1_mx1_o_addr_rd), 
        .ds_o_addr_rt(ds1_mx1_o_addr_rt), 
        .ds_o_addr_rs(ds1_o_addr_rs), 
        .ds_o_opcode(ds1_o_opcode), 
        .ds_o_funct(ds1_o_funct), 
        .ds_o_jal_addr(ds1_o_jal_addr), 
        .ds_o_jal(ds1_o_jal), 
        .ds_o_jr(ds1_o_jr), 
        .ds_o_branch(ds1_o_branch), 
        .ds_o_reg_dst(ds1_mx1_o_reg_dst), 
        .ds_o_alu_src(ds1_o_alu_src), 
        .ds_o_memwrite(ds1_o_memwrite), 
        .ds_o_memtoreg(ds1_o_memtoreg), 
        .ds_o_imm(ds1_o_imm), 
        .ds_o_ce(ds1_o_ce), 
        .ds_o_reg_write(ds1_o_reg_write), 
        .ds_o_data_rs(ds1_o_data_rs),
        .ds_o_data_rt(ds1_o_data_rt)        
    );

    wire [`AWIDTH - 1 : 0] mx1_check_o_addr_rd;
    mux_des md_1 (
        .md_reg_dst(ds1_mx1_o_reg_dst), 
        .md_i_addr_rd(ds1_mx1_o_addr_rd), 
        .md_i_addr_rt(ds1_mx1_o_addr_rt), 
        .md_o_addr_rd(mx1_check_o_addr_rd)
    );

    wire ds2_o_ce;
    wire ds2_o_jr;
    wire ds2_o_jal;
    wire ds2_o_branch;
    wire ds2_o_alu_src;
    wire ds2_o_reg_write;
    wire ds2_mx2_o_reg_dst;
    wire [`AWIDTH - 1 : 0] v_i_addr_rd_2;
    wire [`DWIDTH - 1 : 0] v_i_data_rd_2;
    wire [`IMM_WIDTH - 1 : 0] ds2_o_imm;
    wire ds2_o_memtoreg, ds2_o_memwrite;
    wire [`AWIDTH - 1 : 0] ds2_o_addr_rs;
    wire [`FUNCT_WIDTH - 1 : 0] ds2_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds2_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds2_o_jal_addr;
    wire [`DWIDTH - 1 : 0] ds2_o_data_rs, ds2_o_data_rt;
    wire [`AWIDTH - 1 : 0] ds2_mx2_o_addr_rd, ds2_mx2_o_addr_rt;

    decoder_stage ds_2 (
        .ds_i_clk(v_clk), 
        .ds_i_rst(v_rst), 
        .ds_i_ce(im_o_ce), 
        .ds_i_instr(v_o_instr_2), 
        .ds_i_reg_write(v_i_reg_write), 
        .ds_i_addr_rd(v_i_addr_rd_2), 
        .ds_i_data_rd(v_i_data_rd_2), 
        .ds_o_addr_rd(ds2_mx2_o_addr_rd), 
        .ds_o_addr_rt(ds2_mx2_o_addr_rt), 
        .ds_o_addr_rs(ds2_o_addr_rs), 
        .ds_o_opcode(ds2_o_opcode), 
        .ds_o_funct(ds2_o_funct), 
        .ds_o_jal_addr(ds2_o_jal_addr), 
        .ds_o_jal(ds2_o_jal), 
        .ds_o_jr(ds2_o_jr), 
        .ds_o_branch(ds2_o_branch), 
        .ds_o_reg_dst(ds2_mx2_o_reg_dst), 
        .ds_o_alu_src(ds2_o_alu_src), 
        .ds_o_memwrite(ds2_o_memwrite), 
        .ds_o_memtoreg(ds2_o_memtoreg), 
        .ds_o_imm(ds2_o_imm), 
        .ds_o_ce(ds2_o_ce), 
        .ds_o_reg_write(ds2_o_reg_write), 
        .ds_o_data_rs(ds2_o_data_rs),
        .ds_o_data_rt(ds2_o_data_rt)        
    );

    wire v_o_change_instr;
    check_dup cd (
        .cd_i_addr_rd_1(mx1_check_o_addr_rd), 
        .cd_i_addr_rs_2(ds2_o_addr_rs),
        .cd_i_addr_rt_2(ds2_mx2_o_addr_rt),
        .cd_o_change_instr(v_o_change_instr)
    );

    
    queue q (
        .q_clk(v_clk), 
        .q_rst(v_rst), 
        .q_i_instr(v_o_instr_2), 
        .q_i_we(), q_i_re, q_o_instr
    )
endmodule  
`endif 