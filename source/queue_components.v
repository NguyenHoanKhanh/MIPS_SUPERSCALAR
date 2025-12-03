`ifndef QUEUE_COMPONENTS_V
`define QUEUE_COMPONENTS_V
`include "./source/header.vh"

module queue_comps (
    qc_clk, qc_rst, qc_i_ce, qc_i_pc, qc_i_jr, qc_i_jal, qc_i_imm, qc_i_funct, qc_i_opcode, 
    qc_i_reg_dst, qc_i_alu_src, qc_i_data_rs, qc_i_data_rt, qc_i_memtoreg, qc_i_memwrite,
    qc_i_jal_addr, qc_i_reg_write, qc_i_addr_rd, qc_i_addr_rs, qc_i_addr_rt, qc_i_we, 
    qc_i_re, qc_i_force_pipe1, qc_o_addr_rd, qc_o_addr_rs, qc_o_addr_rt, qc_o_ce, qc_o_jr, qc_o_jal, 
    qc_o_imm, qc_o_funct, qc_o_opcode, qc_o_reg_dst, qc_o_alu_src, qc_o_data_rs, 
    qc_o_data_rt, qc_o_memtoreg, qc_o_memwrite, qc_o_jal_addr, qc_o_regwrite, qc_o_pc,
    qc_o_force_pipe1
);
    input qc_i_we, qc_i_re;
    input qc_i_force_pipe1;

    input qc_i_ce;
    input qc_i_reg_dst;
    input qc_i_alu_src;
    input qc_i_memtoreg; 
    input qc_i_memwrite;
    input qc_i_reg_write;
    input qc_clk, qc_rst;
    input qc_i_jr, qc_i_jal;
    input [`PC_WIDTH - 1 : 0] qc_i_pc;
    input [`IMM_WIDTH - 1 : 0] qc_i_imm;
    input [`FUNCT_WIDTH - 1 : 0] qc_i_funct;
    input [`OPCODE_WIDTH - 1 : 0] qc_i_opcode;
    input [`JUMP_WIDTH - 1 : 0] qc_i_jal_addr;
    input [`DWIDTH - 1 : 0] qc_i_data_rs, qc_i_data_rt;
    input [`AWIDTH - 1 : 0] qc_i_addr_rd, qc_i_addr_rs, qc_i_addr_rt;

    output qc_o_force_pipe1;
    output qc_o_ce;
    output qc_o_reg_dst;
    output qc_o_alu_src;
    output qc_o_memtoreg; 
    output qc_o_memwrite;
    output qc_o_regwrite;
    output qc_o_jr, qc_o_jal;
    output [`PC_WIDTH - 1 : 0] qc_o_pc;
    output [`IMM_WIDTH - 1 : 0] qc_o_imm;
    output [`FUNCT_WIDTH - 1 : 0] qc_o_funct;
    output [`OPCODE_WIDTH - 1 : 0] qc_o_opcode;
    output [`JUMP_WIDTH - 1 : 0] qc_o_jal_addr;
    output [`DWIDTH - 1 : 0] qc_o_data_rs, qc_o_data_rt;
    output [`AWIDTH - 1 : 0] qc_o_addr_rd, qc_o_addr_rs, qc_o_addr_rt;

    integer i;
    reg [(2 ** `DEPTH) - 1 : 0] count;
    reg [(2 ** `DEPTH) - 1 : 0] from_end, from_begin;
    reg temp_ce [(2 ** `DEPTH) - 1 : 0];
    reg temp_jr [(2 ** `DEPTH) - 1 : 0];
    reg temp_jal [(2 ** `DEPTH) - 1 : 0];
    reg temp_reg_dst [(2 ** `DEPTH) - 1 : 0];
    reg temp_alu_src [(2 ** `DEPTH) - 1 : 0];
    reg temp_memtoreg [(2 ** `DEPTH) - 1 : 0];
    reg temp_memwrite [(2 ** `DEPTH) - 1 : 0];
    reg temp_reg_write [(2 ** `DEPTH) - 1 : 0];
    reg temp_force_pipe1 [(2 ** `DEPTH) - 1 : 0];
    reg [`PC_WIDTH - 1 : 0] temp_pc [(2 ** `DEPTH) - 1 : 0];
    reg [`IMM_WIDTH - 1 : 0] temp_imm [(2 ** `DEPTH) - 1 : 0];
    reg [`DWIDTH - 1 : 0] temp_data_rs [(2 ** `DEPTH) - 1 : 0];
    reg [`DWIDTH - 1 : 0] temp_data_rt [(2 ** `DEPTH) - 1 : 0];
    reg [`AWIDTH - 1 : 0] temp_addr_rd [(2 ** `DEPTH) - 1 : 0];
    reg [`AWIDTH - 1 : 0] temp_addr_rs [(2 ** `DEPTH) - 1 : 0];
    reg [`AWIDTH - 1 : 0] temp_addr_rt [(2 ** `DEPTH) - 1 : 0];
    reg [`FUNCT_WIDTH - 1 : 0] temp_funct [(2 ** `DEPTH) - 1 : 0];
    reg [`OPCODE_WIDTH - 1 : 0] temp_opcode [(2 ** `DEPTH) - 1 : 0];
    reg [`JUMP_WIDTH - 1 : 0] temp_jal_addr [(2 ** `DEPTH) - 1 : 0];

    assign qc_o_ce = temp_ce[from_end];
    assign qc_o_jr = temp_jr[from_end];
    assign qc_o_pc = temp_pc[from_end];
    assign qc_o_imm = temp_imm[from_end];
    assign qc_o_jal = temp_jal[from_end];
    assign qc_o_funct = temp_funct[from_end];
    assign qc_o_opcode = temp_opcode[from_end];
    assign qc_o_addr_rd = temp_addr_rd[from_end];
    assign qc_o_addr_rs = temp_addr_rs[from_end];
    assign qc_o_addr_rt = temp_addr_rt[from_end];
    assign qc_o_data_rs = temp_data_rs[from_end];
    assign qc_o_data_rt = temp_data_rt[from_end];
    assign qc_o_reg_dst = temp_reg_dst[from_end];
    assign qc_o_alu_src = temp_alu_src[from_end];
    assign qc_o_jal_addr = temp_jal_addr[from_end];
    assign qc_o_memtoreg = temp_memtoreg[from_end];
    assign qc_o_memwrite = temp_memwrite[from_end];
    assign qc_o_regwrite = temp_reg_write[from_end];
    assign qc_o_force_pipe1 = temp_force_pipe1[from_end];

    always @(negedge qc_clk, negedge qc_rst) begin
        if (!qc_rst) begin
            for (i = 0; i < (2 ** `DEPTH); i = i + 1) begin
                temp_ce[i] <= 1'b0;
                temp_jr[i] <= 1'b0;
                temp_jal[i] <= 1'b0;
                temp_reg_dst[i] <= 1'b0;
                temp_alu_src[i] <= 1'b0;
                temp_memtoreg[i] <= 1'b0;
                temp_memwrite[i] <= 1'b0;
                temp_reg_write[i] <= 1'b0;
                temp_force_pipe1[i] <= 1'b0;
                temp_pc[i] <= {`PC_WIDTH{1'b0}};
                temp_imm[i] <= {`IMM_WIDTH{1'b0}};
                temp_addr_rd[i] <= {`AWIDTH{1'b0}};
                temp_addr_rs[i] <= {`AWIDTH{1'b0}};
                temp_addr_rt[i] <= {`AWIDTH{1'b0}};
                temp_data_rs[i] <= {`DWIDTH{1'b0}};
                temp_data_rt[i] <= {`DWIDTH{1'b0}};
                temp_funct[i] <= {`FUNCT_WIDTH{1'b0}};
                temp_jal_addr[i] <= {`JUMP_WIDTH{1'b0}};
                temp_opcode[i] <= {`OPCODE_WIDTH{1'b0}};
            end
            count <= 0;
            from_end <= 0;
            from_begin <= 0;
        end
        else begin
            if (qc_i_we) begin
                if (count < 2 ** `DEPTH) begin
                    temp_ce[from_begin] <= qc_i_ce;
                    temp_pc[from_begin] <= qc_i_pc;
                    temp_jr[from_begin] <= qc_i_jr;
                    temp_jal[from_begin] <= qc_i_jal;
                    temp_imm[from_begin] <= qc_i_imm;
                    temp_funct[from_begin] <= qc_i_funct;
                    temp_opcode[from_begin] <= qc_i_opcode;
                    temp_reg_dst[from_begin] <= qc_i_reg_dst;
                    temp_alu_src[from_begin] <= qc_i_alu_src;
                    temp_addr_rd[from_begin] <= qc_i_addr_rd;
                    temp_addr_rs[from_begin] <= qc_i_addr_rs;
                    temp_addr_rt[from_begin] <= qc_i_addr_rt;
                    temp_data_rs[from_begin] <= qc_i_data_rs;
                    temp_data_rt[from_begin] <= qc_i_data_rt;
                    temp_memtoreg[from_begin] <= qc_i_memtoreg;
                    temp_memwrite[from_begin] <= qc_i_memwrite;
                    temp_jal_addr[from_begin] <= qc_i_jal_addr;
                    temp_reg_write[from_begin] <= qc_i_reg_write;
                    temp_force_pipe1[from_begin] <= qc_i_force_pipe1;
                    count <= count + 1;
                    from_begin <= (from_begin == (2 ** `DEPTH) - 1) ? 0 : from_begin + 1;
                end
            end
            if (qc_i_re) begin
                if (count > 0) begin
                    count <= count - 1;
                    from_end <= (from_end == (2 ** `DEPTH) - 1) ? 0 : from_end + 1;
                end
            end
        end
    end
endmodule
`endif
