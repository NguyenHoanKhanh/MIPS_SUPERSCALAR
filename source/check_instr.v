`ifndef CHECK_INSTR_V
`define CHECK_INSTR_V
`include "./source/header.vh"

module check_instr (
    ci_clk, ci_rst, ci_i_ce_2, ci_i_jr_2, ci_i_pc_2, ci_i_jal_2, ci_i_imm_2, ci_i_funct_2, ci_i_opcode_2,
    ci_i_reg_dst_2, ci_i_alu_src_2, ci_i_data_rs_2, ci_i_data_rt_2, ci_i_jal_addr_2, ci_i_memwrite_2, 
    ci_i_memtoreg_2, ci_i_regwrite_2, ci_i_addr_rd_1, ci_i_addr_rd_2, ci_i_addr_rs_1, ci_i_addr_rs_2, 
    ci_i_addr_rt_1, ci_i_addr_rt_2, ci_o_addr_rd, ci_o_addr_rs, ci_o_addr_rt, ci_o_reg_dst, 
    ci_o_ce, ci_o_jr, ci_o_jal, ci_o_pc, ci_o_imm, ci_o_funct, ci_o_opcode, ci_o_alu_src, 
    ci_o_data_rs, ci_o_data_rt, ci_o_jal_addr, ci_o_memwrite, ci_o_memtoreg, ci_o_regwrite 
);
    input ci_i_ce_2;
    input ci_clk, ci_rst;
    input ci_i_reg_dst_2;
    input ci_i_alu_src_2;
    input ci_i_memwrite_2;
    input ci_i_memtoreg_2;
    input ci_i_regwrite_2;
    input ci_i_jr_2, ci_i_jal_2;
    input [`PC_WIDTH - 1 : 0] ci_i_pc_2;
    input [`IMM_WIDTH - 1 : 0] ci_i_imm_2;
    input [`FUNCT_WIDTH - 1 : 0] ci_i_funct_2;
    input [`OPCODE_WIDTH - 1 : 0] ci_i_opcode_2;
    input [`JUMP_WIDTH - 1 : 0] ci_i_jal_addr_2;
    input [`AWIDTH - 1 : 0] ci_i_addr_rd_1, ci_i_addr_rd_2;
    input [`AWIDTH - 1 : 0] ci_i_addr_rs_1, ci_i_addr_rs_2;
    input [`AWIDTH - 1 : 0] ci_i_addr_rt_1, ci_i_addr_rt_2;
    input [`DWIDTH - 1 : 0] ci_i_data_rs_2, ci_i_data_rt_2;
    output ci_o_ce;
    output ci_o_reg_dst;
    output ci_o_alu_src;
    output ci_o_memwrite;
    output ci_o_memtoreg;
    output ci_o_regwrite;
    output ci_o_jr, ci_o_jal;
    output [`PC_WIDTH - 1 : 0] ci_o_pc;
    output [`IMM_WIDTH - 1 : 0] ci_o_imm;
    output [`FUNCT_WIDTH - 1 : 0] ci_o_funct;
    output [`OPCODE_WIDTH - 1 : 0] ci_o_opcode;
    output [`JUMP_WIDTH - 1 : 0] ci_o_jal_addr;
    output [`DWIDTH - 1 : 0] ci_o_data_rs, ci_o_data_rt;
    output [`AWIDTH - 1 : 0] ci_o_addr_rd, ci_o_addr_rs, ci_o_addr_rt;
    integer i;
    reg check;
    reg [(2 ** `DEPTH) - 1 : 0] counter;
    reg [`AWIDTH - 1 : 0] addr_rd [(2 ** `DEPTH) - 1 : 0];
    reg [`AWIDTH - 1 : 0] addr_rs [(2 ** `DEPTH) - 1 : 0];
    reg [`AWIDTH - 1 : 0] addr_rt [(2 ** `DEPTH) - 1 : 0];
    always @(posedge ci_clk, negedge ci_rst) begin
        if (!ci_rst) begin
            for (i = 0; i < (2 ** `DEPTH); i = i + 1) begin
                addr_rd[i] <= {`AWIDTH{1'b0}};
                addr_rs[i] <= {`AWIDTH{1'b0}};
                addr_rt[i] <= {`AWIDTH{1'b0}};
            end
            counter <= 0;
        end
        else begin
            if (counter < 2 ** `DEPTH) begin
                addr_rd[counter] <= ci_i_addr_rd_1;
                addr_rs[counter] <= ci_i_addr_rs_1;
                addr_rt[counter] <= ci_i_addr_rt_1;
                counter <= counter + 1;
            end
        end
    end

    always @(*) begin
        check = 1'b0;
        for (i = 0; i < 2 ** `DEPTH; i = i + 1) begin
            if (i < counter) begin
                if((ci_i_addr_rd_2 == addr_rd[i]) && (ci_i_addr_rs_2 == addr_rs[i]) 
                    && (ci_i_addr_rt_2 == addr_rt[i])) begin
                        check = 1'b1;
                    end
                else begin
                    check = 1'b0;
                end
            end
        end
    end

    assign ci_o_ce = (check) ? 1'b0 : ci_i_ce_2;
    assign ci_o_jr = (check) ? 1'b0 : ci_i_jr_2;
    assign ci_o_jal = (check) ? 1'b0 : ci_i_jal_2;
    assign ci_o_alu_src = (check) ? 1'b0 : ci_i_alu_src_2;
    assign ci_o_reg_dst = (check) ? 1'b0 : ci_i_reg_dst_2;
    assign ci_o_memwrite = (check) ? 1'b0 : ci_i_memwrite_2;
    assign ci_o_memtoreg = (check) ? 1'b0 : ci_i_memtoreg_2;
    assign ci_o_regwrite = (check) ? 1'b0 : ci_i_regwrite_2;
    assign ci_o_pc = (check) ? {`PC_WIDTH{1'b0}} : ci_i_pc_2;
    assign ci_o_imm = (check) ? {`IMM_WIDTH{1'b0}} : ci_i_imm_2;
    assign ci_o_data_rs = (check) ? {`DWIDTH{1'b0}} : ci_i_data_rs_2;
    assign ci_o_data_rt = (check) ? {`DWIDTH{1'b0}} : ci_i_data_rt_2;
    assign ci_o_addr_rd = (check) ? {`AWIDTH{1'b0}} : ci_i_addr_rd_2;
    assign ci_o_addr_rs = (check) ? {`AWIDTH{1'b0}} : ci_i_addr_rs_2;
    assign ci_o_addr_rt = (check) ? {`AWIDTH{1'b0}} : ci_i_addr_rt_2;
    assign ci_o_funct = (check) ? {`FUNCT_WIDTH{1'b0}} : ci_i_funct_2;
    assign ci_o_opcode = (check) ? {`OPCODE_WIDTH{1'b0}} : ci_i_opcode_2;
    assign ci_o_jal_addr = (check) ? {`JUMP_WIDTH{1'b0}} : ci_i_jal_addr_2;
endmodule
`endif 