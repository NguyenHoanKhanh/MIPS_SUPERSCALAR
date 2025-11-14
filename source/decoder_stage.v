`ifndef DECODER_STAGE_V
`define DECODER_STAGE_V
`include "./source/decoder.v"
`include "./source/register.v"

module decoder_stage (
    ds_i_clk, ds_i_rst, ds_i_ce, ds_i_instr, ds_i_reg_write, ds_i_addr_rd, ds_i_data_rd, ds_o_addr_rd, 
    ds_o_addr_rt, ds_o_addr_rs, ds_o_opcode, ds_o_funct, ds_o_jal_addr, ds_o_jal, ds_o_jr, ds_o_branch, 
    ds_o_reg_dst, ds_o_alu_src, ds_o_memwrite, ds_o_memtoreg, ds_o_imm, ds_o_ce, ds_o_reg_write, ds_o_data_rs,
    ds_o_data_rt
);
    input ds_i_ce;
    input ds_i_reg_write;
    input ds_i_clk, ds_i_rst;
    input [`IWIDTH - 1 : 0] ds_i_instr;
    input [`AWIDTH - 1 : 0] ds_i_addr_rd;
    input [`DWIDTH - 1 : 0] ds_i_data_rd;
    output ds_o_ce;
    output ds_o_jr;
    output ds_o_jal;
    output ds_o_branch;
    output ds_o_alu_src;
    output ds_o_reg_dst;
    output ds_o_memtoreg;
    output ds_o_memwrite;
    output ds_o_reg_write;
    output [`IMM_WIDTH - 1 : 0] ds_o_imm;
    output [`FUNCT_WIDTH - 1 : 0] ds_o_funct;
    output [`OPCODE_WIDTH - 1 : 0] ds_o_opcode;
    output [`JUMP_WIDTH - 1 : 0] ds_o_jal_addr;
    output [`DWIDTH - 1 : 0] ds_o_data_rs, ds_o_data_rt;
    output [`AWIDTH - 1 : 0] ds_o_addr_rd, ds_o_addr_rs, ds_o_addr_rt;

    decoder d (
        .d_i_ce(ds_i_ce), 
        .d_i_instr(ds_i_instr), 
        .d_o_ce(ds_o_ce), 
        .d_o_jr(ds_o_jr), 
        .d_o_imm(ds_o_imm), 
        .d_o_jal(ds_o_jal), 
        .d_o_funct(ds_o_funct), 
        .d_o_opcode(ds_o_opcode), 
        .d_o_branch(ds_o_branch), 
        .d_o_addr_rs(ds_o_addr_rs), 
        .d_o_addr_rt(ds_o_addr_rt),
        .d_o_addr_rd(ds_o_addr_rd), 
        .d_o_alu_src(ds_o_alu_src), 
        .d_o_reg_dst(ds_o_reg_dst),
        .d_o_reg_wr(ds_o_reg_write), 
        .d_o_memwrite(ds_o_memwrite), 
        .d_o_memtoreg(ds_o_memtoreg), 
        .d_o_jal_addr(ds_o_jal_addr)
    );

    register r_eg (
        .r_clk(ds_i_clk), 
        .r_rst(ds_i_rst), 
        .r_wr_en(ds_i_reg_write), 
        .r_i_addr_rd(ds_i_addr_rd), 
        .r_i_data_rd(ds_i_data_rd), 
        .r_i_addr_rs(ds_o_addr_rs), 
        .r_i_addr_rt(ds_o_addr_rt), 
        .r_o_data_rs(ds_o_data_rs), 
        .r_o_data_rt(ds_o_data_rt) 
    );
endmodule
`endif 