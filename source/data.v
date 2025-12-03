`ifndef DATA_V
`define DATA_V
`include "./source/mux.v"
`include "./source/imem.v"
`include "./source/regis.v"
`include "./source/mux2_1.v"
`include "./source/mux3_1.v"
`include "./source/memory.v"
`include "./source/check_dup.v"
`include "./source/decoder_s.v"
`include "./source/forwarding.v"
`include "./source/treat_load.v"
`include "./source/check_instr.v"
`include "./source/treat_store.v"
`include "./source/choose_comps.v"
`include "./source/mux_components.v"
`include "./source/control_hazard.v"
`include "./source/execute_stage_1.v"
`include "./source/program_counter.v"
`include "./source/queue_components.v"
`include "./source/mux2_1_check_queue.v"
//Compared to the previous architecture, the queue of the current one will be moved after the ds_es register to reduce latency
module datapath (
    d_clk, d_rst, d_i_ce, wb_ds1_o_data_rd, wb_ds2_o_data_rd, pc_o_pc_1, pc_o_pc_2
);
    input d_i_ce;
    input d_clk, d_rst;
    output [`PC_WIDTH - 1 : 0] pc_o_pc_1, pc_o_pc_2;
    output [`DWIDTH - 1 : 0] wb_ds1_o_data_rd, wb_ds2_o_data_rd;

    wire pc_o_ce;
    reg pc_im_o_ce;
    reg [`PC_WIDTH - 1 : 0] pc_im_o_pc_1, pc_im_o_pc_2;
    program_counter pc (
        .pc_i_clk(d_clk), 
        .pc_i_rst(d_rst), 
        .pc_i_ce(d_i_ce), 
        .pc_i_pc_1(ctrl1_o_pc), 
        .pc_i_pc_2(ctrl2_o_pc), 
        .pc_i_change_pc_1(ctrl1_o_change_pc), 
        .pc_i_change_pc_2(ctrl2_o_change_pc), 
        .pc_o_pc_1(pc_o_pc_1), 
        .pc_o_pc_2(pc_o_pc_2), 
        .pc_o_ce(pc_o_ce)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            pc_im_o_ce <= 1'b0;
            pc_im_o_pc_1 <= {`PC_WIDTH{1'b0}};
            pc_im_o_pc_2 <= {`PC_WIDTH{1'b0}};
        end
        else begin
            pc_im_o_ce <= pc_o_ce;
            pc_im_o_pc_1 <= pc_o_pc_1;
            pc_im_o_pc_2 <= pc_o_pc_2;
        end
    end

    wire im_o_ce;
    wire [`IWIDTH - 1 : 0] im_o_instr_1, im_o_instr_2; 
    reg im_ds1_o_ce, im_ds2_o_ce;
    reg [`PC_WIDTH - 1 : 0] im_ds1_o_pc, im_ds2_o_pc;
    reg [`IWIDTH - 1 : 0] im_ds1_o_instr, im_ds2_o_instr;
    wire ds2_issue_stall;
    imem im (
        .im_clk(d_clk), 
        .im_rst(d_rst), 
        .im_i_ce(pc_im_o_ce), 
        .im_i_addr_1(pc_im_o_pc_1), 
        .im_i_addr_2(pc_im_o_pc_2), 
        .im_o_instr_1(im_o_instr_1), 
        .im_o_instr_2(im_o_instr_2), 
        .im_o_ce(im_o_ce)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            im_ds1_o_ce <= 1'b0;
            im_ds1_o_pc <= {`PC_WIDTH{1'b0}};
            im_ds1_o_instr <= {`IWIDTH{1'b0}};
        end
        else begin  
            if (!fw1_o_stall) begin
                im_ds1_o_ce <= im_o_ce;
                im_ds1_o_pc <= pc_im_o_pc_1;           
                im_ds1_o_instr <= im_o_instr_1;
            end
            else begin
                im_ds1_o_ce <= im_ds1_o_ce;
                im_ds1_o_pc <= im_ds1_o_pc;     
                im_ds1_o_instr <= im_ds1_o_instr;
            end
end
    end

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            im_ds2_o_ce <= 1'b0;
            im_ds2_o_pc <= {`PC_WIDTH{1'b0}};
            im_ds2_o_instr <= {`IWIDTH{1'b0}};
        end
        else begin
            if (!ds2_issue_stall) begin
                im_ds2_o_ce <= im_o_ce;
                im_ds2_o_pc <= pc_im_o_pc_2;
                im_ds2_o_instr <= im_o_instr_2;
            end
            else begin
                im_ds2_o_ce <= im_ds2_o_ce;
                im_ds2_o_pc <= im_ds2_o_pc;
                im_ds2_o_instr <= im_ds2_o_instr;
            end
        end
    end

    wire ds1_o_ce;
    wire ds1_o_jr;
    wire ds1_o_jal;
    wire ds1_o_branch;
    wire ds1_o_reg_dst;
    wire ds1_o_alu_src;
    wire ds1_o_memtoreg;
    wire ds1_o_memwrite;
    wire ds1_o_reg_write;
    wire [`IMM_WIDTH - 1 : 0] ds1_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] ds1_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds1_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds1_o_jal_addr;
    wire [`AWIDTH - 1 : 0] ds1_o_addr_rd, ds1_o_addr_rs, ds1_o_addr_rt;
    decoder_stage ds1 (
        .ds_i_clk(d_clk), 
        .ds_i_rst(d_rst), 
        .ds_i_ce(im_ds1_o_ce), 
        .ds_i_instr(im_ds1_o_instr), 
        .ds_o_ce(ds1_o_ce), 
        .ds_o_jr(ds1_o_jr), 
        .ds_o_jal(ds1_o_jal), 
        .ds_o_imm(ds1_o_imm), 
        .ds_o_funct(ds1_o_funct), 
        .ds_o_opcode(ds1_o_opcode), 
        .ds_o_branch(ds1_o_branch), 
        .ds_o_addr_rd(ds1_o_addr_rd), 
        .ds_o_addr_rt(ds1_o_addr_rt), 
        .ds_o_addr_rs(ds1_o_addr_rs), 
        .ds_o_reg_dst(ds1_o_reg_dst), 
        .ds_o_alu_src(ds1_o_alu_src), 
        .ds_o_jal_addr(ds1_o_jal_addr), 
        .ds_o_memwrite(ds1_o_memwrite), 
        .ds_o_memtoreg(ds1_o_memtoreg), 
        .ds_o_reg_write(ds1_o_reg_write)
    );

    wire ds2_o_ce;
    wire ds2_o_jr;
    wire ds2_o_jal;
    wire ds2_o_branch;
    wire ds2_o_reg_dst;
    wire ds2_o_alu_src;
    wire ds2_o_memtoreg;
    wire ds2_o_memwrite;
    wire ds2_o_reg_write;
    wire [`IMM_WIDTH - 1 : 0] ds2_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] ds2_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds2_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds2_o_jal_addr;
    wire [`AWIDTH - 1 : 0] ds2_o_addr_rd, ds2_o_addr_rs, ds2_o_addr_rt;
    decoder_stage ds2 (
        .ds_i_clk(d_clk), 
        .ds_i_rst(d_rst), 
        .ds_i_ce(im_ds2_o_ce), 
        .ds_i_instr(im_ds2_o_instr), 
        .ds_o_ce(ds2_o_ce), 
        .ds_o_jr(ds2_o_jr), 
        .ds_o_jal(ds2_o_jal), 
        .ds_o_imm(ds2_o_imm), 
        .ds_o_funct(ds2_o_funct), 
        .ds_o_opcode(ds2_o_opcode), 
        .ds_o_branch(ds2_o_branch), 
        .ds_o_addr_rd(ds2_o_addr_rd), 
        .ds_o_addr_rt(ds2_o_addr_rt), 
        .ds_o_addr_rs(ds2_o_addr_rs), 
        .ds_o_reg_dst(ds2_o_reg_dst), 
        .ds_o_alu_src(ds2_o_alu_src), 
        .ds_o_jal_addr(ds2_o_jal_addr), 
        .ds_o_memwrite(ds2_o_memwrite), 
        .ds_o_memtoreg(ds2_o_memtoreg),
.ds_o_reg_write(ds2_o_reg_write)
    );

    wire [`DWIDTH - 1 : 0] r_o_data_rs_1, r_o_data_rt_1;
    wire [`DWIDTH - 1 : 0] r_o_data_rs_2, r_o_data_rt_2;
    regis r_eg (
        .r_clk(d_clk), 
        .r_rst(d_rst), 
        .r_wr_en_1(ms_wb1_o_regwrite), 
        .r_wr_en_2(ms_wb2_o_regwrite), 
        .r_i_addr_rs_1(ds1_o_addr_rs), 
        .r_i_addr_rt_1(ds1_o_addr_rt), 
        .r_i_addr_rs_2(ds2_o_addr_rs), 
        .r_i_addr_rt_2(ds2_o_addr_rt), 
        .r_i_addr_rd_1(ms_wb1_o_addr_rd), 
        .r_i_data_rd_1(wb_ds1_o_data_rd), 
        .r_i_addr_rd_2(ms_wb2_o_addr_rd), 
        .r_i_data_rd_2(wb_ds2_o_data_rd), 
        .r_o_data_rs_1(r_o_data_rs_1), 
        .r_o_data_rt_1(r_o_data_rt_1), 
        .r_o_data_rs_2(r_o_data_rs_2), 
        .r_o_data_rt_2(r_o_data_rt_2) 
    );

    wire ctrl1_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] ctrl1_o_pc;
    control_hazard ctrl_1 (
        .i_pc(im_ds1_o_pc), 
        .i_imm(ds1_o_imm), 
        .i_branch(ds1_o_branch), 
        .i_opcode(ds1_o_opcode), 
        .i_data_r1(r_o_data_rs_1), 
        .i_data_r2(r_o_data_rt_1), 
        .i_es_o_pc(es1_ctrl1_o_alu_pc), 
        .i_es_o_change_pc(es1_ctrl1_o_change_pc), 
        .o_pc(ctrl1_o_pc), 
        .o_compare(ctrl1_o_change_pc)
    );

    wire ctrl2_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] ctrl2_o_pc;
    control_hazard ctrl_2 (
        .i_pc(im_ds2_o_pc), 
        .i_imm(ds2_o_imm), 
        .i_branch(ds2_o_branch), 
        .i_opcode(ds2_o_opcode), 
        .i_data_r1(r_o_data_rs_2), 
        .i_data_r2(r_o_data_rt_2), 
        .i_es_o_pc(es2_ctrl2_o_alu_pc), 
        .i_es_o_change_pc(es2_ctrl2_o_change_pc), 
        .o_pc(ctrl2_o_pc), 
        .o_compare(ctrl2_o_change_pc)
    );

    //Check for conflicts before passing the value to the ds_es register and convert 
    //the queue_instr to queue_comps

    wire cd1_o_we;  
    wire cd1_o_force_pipe1;
    reg cd1_q1_o_we;
    reg cd1_q1_force_pipe1;
    check_dup cd1 (
        .cd_i_addr_rd_1(ds1_o_addr_rd), 
        .cd_i_addr_rs_2(ds2_o_addr_rs), 
        .cd_i_addr_rt_2(ds2_o_addr_rt), 
        .cd_i_opcode_2(ds1_o_opcode), 
        .cd_o_we(cd1_o_we),
        .cd_o_force_pipe1(cd1_o_force_pipe1)
    );

    wire cd2_o_we;
    wire cd2_o_force_pipe1;
    reg cd2_q2_o_we;
    reg cd2_q2_force_pipe1;
    check_dup cd2 (
        .cd_i_addr_rd_1(ds2_es2_o_addr_rd), 
        .cd_i_addr_rs_2(ds1_o_addr_rs), 
        .cd_i_addr_rt_2(ds1_o_addr_rt), 
        .cd_i_opcode_2(ds2_o_opcode), 
        .cd_o_we(cd2_o_we),
        .cd_o_force_pipe1(cd2_o_force_pipe1)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            cd1_q1_o_we <= 1'b0;
            cd2_q2_o_we <= 1'b0;
            cd1_q1_force_pipe1 <= 1'b0;
            cd2_q2_force_pipe1 <= 1'b0;
        end
        else begin
            cd1_q1_o_we <= cd1_o_we;
            cd2_q2_o_we <= cd2_o_we;
            cd1_q1_force_pipe1 <= cd1_o_force_pipe1;
            cd2_q2_force_pipe1 <= cd2_o_force_pipe1;
        end
    end

    reg ds1_es1_o_ce;
    reg ds1_es1_o_jr;
    reg ds1_es1_o_jal;
    reg ds1_es1_o_reg_dst;
    reg ds1_es1_o_alu_src;
    reg ds1_es1_o_memtoreg;
    reg ds1_es1_o_memwrite;
    reg ds1_es1_o_reg_write;
    reg [`PC_WIDTH - 1 : 0] ds1_es1_o_pc;
    reg [`IMM_WIDTH - 1 : 0] ds1_es1_o_imm;
    reg [`FUNCT_WIDTH - 1 : 0] ds1_es1_o_funct;
reg [`OPCODE_WIDTH - 1 : 0] ds1_es1_o_opcode;
    reg [`JUMP_WIDTH - 1 : 0] ds1_es1_o_jal_addr;
    reg [`DWIDTH - 1 : 0] ds1_es1_o_data_rs, ds1_es1_o_data_rt;
    reg [`AWIDTH - 1 : 0] ds1_es1_o_addr_rd, ds1_es1_o_addr_rs, ds1_es1_o_addr_rt;

    reg ds2_es2_o_ce;
    reg ds2_es2_o_jr;
    reg ds2_es2_o_jal;
    reg ds2_es2_o_reg_dst;
    reg ds2_es2_o_alu_src;
    reg ds2_es2_o_memtoreg;
    reg ds2_es2_o_memwrite;
    reg ds2_es2_o_reg_write;
    reg [`PC_WIDTH - 1 : 0] ds2_es2_o_pc;
    reg [`IMM_WIDTH - 1 : 0] ds2_es2_o_imm;
    reg [`FUNCT_WIDTH - 1 : 0] ds2_es2_o_funct;
    reg [`OPCODE_WIDTH - 1 : 0] ds2_es2_o_opcode;
    reg [`JUMP_WIDTH - 1 : 0] ds2_es2_o_jal_addr;
    reg [`DWIDTH - 1 : 0] ds2_es2_o_data_rs, ds2_es2_o_data_rt;
    reg [`AWIDTH - 1 : 0] ds2_es2_o_addr_rd, ds2_es2_o_addr_rs, ds2_es2_o_addr_rt;
    
    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            ds1_es1_o_ce <= 1'b0;
            ds1_es1_o_jr <= 1'b0;
            ds1_es1_o_jal <= 1'b0;
            ds1_es1_o_reg_dst <= 1'b0;
            ds1_es1_o_alu_src <= 1'b0;
            ds1_es1_o_memtoreg <= 1'b0;
            ds1_es1_o_memwrite <= 1'b0;
            ds1_es1_o_reg_write <= 1'b0;
            ds1_es1_o_pc <= {`PC_WIDTH{1'b0}};
            ds1_es1_o_imm <= {`IMM_WIDTH{1'b0}};
            ds1_es1_o_data_rs <= {`DWIDTH{1'b0}};
            ds1_es1_o_data_rt <= {`DWIDTH{1'b0}};
            ds1_es1_o_addr_rd <= {`AWIDTH{1'b0}};
            ds1_es1_o_addr_rs <= {`AWIDTH{1'b0}};
            ds1_es1_o_addr_rt <= {`AWIDTH{1'b0}};
            ds1_es1_o_funct <= {`FUNCT_WIDTH{1'b0}};
            ds1_es1_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            ds1_es1_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
        end
        else begin
            if (!fw1_o_stall) begin
                ds1_es1_o_ce <= ds1_o_ce;
                ds1_es1_o_jr <= ds1_o_jr;
                ds1_es1_o_jal <= ds1_o_jal;
                ds1_es1_o_imm <= ds1_o_imm;
                ds1_es1_o_pc <= im_ds1_o_pc;
                ds1_es1_o_funct <= ds1_o_funct;
                ds1_es1_o_opcode <= ds1_o_opcode;
                ds1_es1_o_reg_dst <= ds1_o_reg_dst;
                ds1_es1_o_alu_src <= ds1_o_alu_src;
                ds1_es1_o_data_rs <= r_o_data_rs_1;
                ds1_es1_o_data_rt <= r_o_data_rt_1;
                ds1_es1_o_addr_rd <= ds1_o_addr_rd;
                ds1_es1_o_addr_rs <= ds1_o_addr_rs;
                ds1_es1_o_addr_rt <= ds1_o_addr_rt;
                ds1_es1_o_memtoreg <= ds1_o_memtoreg;
                ds1_es1_o_memwrite <= ds1_o_memwrite;
                ds1_es1_o_jal_addr <= ds1_o_jal_addr;
                ds1_es1_o_reg_write <= ds1_o_reg_write;
            end
            else begin
                ds1_es1_o_ce <= ds1_es1_o_ce;
                ds1_es1_o_jr <= ds1_es1_o_jr;
                ds1_es1_o_pc <= ds1_es1_o_pc;
                ds1_es1_o_jal <= ds1_es1_o_jal;
                ds1_es1_o_imm <= ds1_es1_o_imm;
ds1_es1_o_funct <= ds1_es1_o_funct;
                ds1_es1_o_opcode <= ds1_es1_o_opcode;
                ds1_es1_o_reg_dst <= ds1_es1_o_reg_dst;
                ds1_es1_o_alu_src <= ds1_es1_o_alu_src;
                ds1_es1_o_data_rs <= ds1_es1_o_data_rs;
                ds1_es1_o_data_rt <= ds1_es1_o_data_rt;
                ds1_es1_o_addr_rd <= ds1_es1_o_addr_rd;
                ds1_es1_o_addr_rs <= ds1_es1_o_addr_rs;
                ds1_es1_o_addr_rt <= ds1_es1_o_addr_rt;
                ds1_es1_o_jal_addr <= ds1_es1_o_jal_addr;
                ds1_es1_o_memtoreg <= ds1_es1_o_memtoreg;
                ds1_es1_o_memwrite <= ds1_es1_o_memwrite;
                ds1_es1_o_reg_write <= ds1_es1_o_reg_write;
            end
        end
    end

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            ds2_es2_o_ce <= 1'b0;
            ds2_es2_o_jr <= 1'b0;
            ds2_es2_o_jal <= 1'b0;
            ds2_es2_o_reg_dst <= 1'b0;
            ds2_es2_o_alu_src <= 1'b0;
            ds2_es2_o_memtoreg <= 1'b0;
            ds2_es2_o_memwrite <= 1'b0;
            ds2_es2_o_reg_write <= 1'b0;
            ds2_es2_o_pc <= {`PC_WIDTH{1'b0}};
            ds2_es2_o_imm <= {`IMM_WIDTH{1'b0}};
            ds2_es2_o_data_rs <= {`DWIDTH{1'b0}};
            ds2_es2_o_data_rt <= {`DWIDTH{1'b0}};
            ds2_es2_o_addr_rd <= {`AWIDTH{1'b0}};
            ds2_es2_o_addr_rs <= {`AWIDTH{1'b0}};
            ds2_es2_o_addr_rt <= {`AWIDTH{1'b0}};
            ds2_es2_o_funct <= {`FUNCT_WIDTH{1'b0}};
            ds2_es2_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            ds2_es2_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
        end
        else begin
            if (!ds2_issue_stall) begin
                ds2_es2_o_ce <= ds2_o_ce;
                ds2_es2_o_jr <= ds2_o_jr;
                ds2_es2_o_jal <= ds2_o_jal;
                ds2_es2_o_imm <= ds2_o_imm;
                ds2_es2_o_pc <= im_ds2_o_pc;
                ds2_es2_o_funct <= ds2_o_funct;
                ds2_es2_o_opcode <= ds2_o_opcode;
                ds2_es2_o_reg_dst <= ds2_o_reg_dst;
                ds2_es2_o_alu_src <= ds2_o_alu_src;
                ds2_es2_o_data_rs <= r_o_data_rs_2;
                ds2_es2_o_data_rt <= r_o_data_rt_2;
                ds2_es2_o_addr_rd <= ds2_o_addr_rd;
                ds2_es2_o_addr_rs <= ds2_o_addr_rs;
                ds2_es2_o_addr_rt <= ds2_o_addr_rt;
                ds2_es2_o_memtoreg <= ds2_o_memtoreg;
                ds2_es2_o_memwrite <= ds2_o_memwrite;
                ds2_es2_o_jal_addr <= ds2_o_jal_addr;
                ds2_es2_o_reg_write <= ds2_o_reg_write;
            end
            else begin
                ds2_es2_o_ce <= ds2_es2_o_ce;
                ds2_es2_o_jr <= ds2_es2_o_jr;
                ds2_es2_o_pc <= ds2_es2_o_pc;
                ds2_es2_o_jal <= ds2_es2_o_jal;
                ds2_es2_o_imm <= ds2_es2_o_imm;
                ds2_es2_o_funct <= ds2_es2_o_funct;
                ds2_es2_o_opcode <= ds2_es2_o_opcode;
ds2_es2_o_reg_dst <= ds2_es2_o_reg_dst;
                ds2_es2_o_alu_src <= ds2_es2_o_alu_src;
                ds2_es2_o_data_rs <= ds2_es2_o_data_rs;
                ds2_es2_o_data_rt <= ds2_es2_o_data_rt;
                ds2_es2_o_addr_rd <= ds2_es2_o_addr_rd;
                ds2_es2_o_addr_rs <= ds2_es2_o_addr_rs;
                ds2_es2_o_addr_rt <= ds2_es2_o_addr_rt;
                ds2_es2_o_memtoreg <= ds2_es2_o_memtoreg;
                ds2_es2_o_memwrite <= ds2_es2_o_memwrite;
                ds2_es2_o_jal_addr <= ds2_es2_o_jal_addr;
                ds2_es2_o_reg_write <= ds2_es2_o_reg_write;
            end
        end
    end

    reg es1_o_qc1, es2_o_qc2;
    reg qc1_i_cd1, qc2_i_cd2;
    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            es1_o_qc1 <= 1'b0;
            es2_o_qc2 <= 1'b0;
            qc1_i_cd1 <= 1'b0;
            qc2_i_cd2 <= 1'b0;
        end 
        else begin
            qc1_i_cd1 <= cd1_q1_o_we;
            qc2_i_cd2 <= cd2_q2_o_we;
            es1_o_qc1 <= es1_queue2_o_fetch;
            es2_o_qc2 <= es2_queue1_o_fetch;
        end
    end

    wire qc1_o_ce;
    wire qc1_o_reg_dst;
    wire qc1_o_alu_src;
    wire qc1_o_regwrite;
    wire qc1_o_memtoreg;
    wire qc1_o_memwrite;
    wire qc1_o_jr, qc1_o_jal;
    wire [`PC_WIDTH - 1 : 0] qc1_o_pc;
    wire [`IMM_WIDTH - 1 : 0] qc1_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] qc1_o_funct;
    wire [`JUMP_WIDTH - 1 : 0] qc1_o_jal_addr;
    wire [`OPCODE_WIDTH - 1 : 0] qc1_o_opcode;
    wire [`DWIDTH - 1 : 0] qc1_o_data_rs, qc1_o_data_rt;
    wire [`AWIDTH - 1 : 0] qc1_o_addr_rd, qc1_o_addr_rs, qc1_o_addr_rt;
    wire qc1_o_force_pipe1;
    queue_comps qc1 (
        .qc_clk(d_clk), 
        .qc_rst(d_rst), 
        .qc_i_re(es1_o_qc1), 
        .qc_i_we(cd1_q1_o_we), 
        .qc_i_force_pipe1(cd1_q1_force_pipe1),
        .qc_i_ce(ds2_es2_o_ce), 
        .qc_i_jr(ds2_es2_o_jr), 
        .qc_i_pc(ds2_es2_o_pc),
        .qc_i_jal(ds2_es2_o_jal), 
        .qc_i_imm(ds2_es2_o_imm), 
        .qc_i_funct(ds2_es2_o_funct), 
        .qc_i_opcode(ds2_es2_o_opcode), 
        .qc_i_reg_dst(ds2_es2_o_reg_dst), 
        .qc_i_alu_src(ds2_es2_o_alu_src), 
        .qc_i_data_rs(ds2_es2_o_data_rs), 
        .qc_i_data_rt(ds2_es2_o_data_rt), 
        .qc_i_addr_rd(ds2_es2_o_addr_rd), 
        .qc_i_addr_rs(ds2_es2_o_addr_rs), 
        .qc_i_addr_rt(ds2_es2_o_addr_rt), 
        .qc_i_memtoreg(ds2_es2_o_memtoreg), 
        .qc_i_memwrite(ds2_es2_o_memwrite),
        .qc_i_jal_addr(ds2_es2_o_jal_addr), 
        .qc_i_reg_write(ds2_es2_o_reg_write), 
        .qc_o_ce(qc1_o_ce), 
        .qc_o_jr(qc1_o_jr), 
        .qc_o_pc(qc1_o_pc),
        .qc_o_jal(qc1_o_jal), 
        .qc_o_imm(qc1_o_imm), 
        .qc_o_funct(qc1_o_funct), 
        .qc_o_opcode(qc1_o_opcode), 
        .qc_o_addr_rd(qc1_o_addr_rd), 
        .qc_o_addr_rs(qc1_o_addr_rs), 
        .qc_o_addr_rt(qc1_o_addr_rt), 
        .qc_o_reg_dst(qc1_o_reg_dst), 
        .qc_o_alu_src(qc1_o_alu_src), 
        .qc_o_data_rs(qc1_o_data_rs),
.qc_o_data_rt(qc1_o_data_rt), 
        .qc_o_memtoreg(qc1_o_memtoreg), 
        .qc_o_memwrite(qc1_o_memwrite), 
        .qc_o_jal_addr(qc1_o_jal_addr), 
        .qc_o_regwrite(qc1_o_regwrite),
        .qc_o_force_pipe1(qc1_o_force_pipe1)
    );
    // Register queue outputs to stabilize inputs to muxes (avoid racing with negedge sampling)
    reg qc1_o_ce_r;
    reg qc1_o_jr_r;
    reg qc1_o_jal_r;
    reg [`PC_WIDTH - 1 : 0] qc1_o_pc_r;
    reg qc1_o_memtoreg_r, qc1_o_memwrite_r;
    reg [`IMM_WIDTH - 1 : 0] qc1_o_imm_r;
    reg [`FUNCT_WIDTH - 1 : 0] qc1_o_funct_r;
    reg [`JUMP_WIDTH - 1 : 0] qc1_o_jal_addr_r;
    reg [`OPCODE_WIDTH - 1 : 0] qc1_o_opcode_r;
    reg [`DWIDTH - 1 : 0] qc1_o_data_rs_r, qc1_o_data_rt_r;
    reg [`AWIDTH - 1 : 0] qc1_o_addr_rd_r, qc1_o_addr_rs_r, qc1_o_addr_rt_r;
    reg qc1_o_reg_dst_r;
    reg qc1_o_alu_src_r;
    reg qc1_o_regwrite_r;
    reg qc1_o_force_pipe1_r;

    // capture queue outputs on posedge so combinational mux downstream sees stable values
    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            qc1_o_ce_r <= 1'b0;
            qc1_o_jr_r <= 1'b0;
            qc1_o_jal_r <= 1'b0;
            qc1_o_reg_dst_r <= 1'b0;
            qc1_o_alu_src_r <= 1'b0;
            qc1_o_memtoreg_r <= 1'b0;
            qc1_o_memwrite_r <= 1'b0;
            qc1_o_regwrite_r <= 1'b0;
            qc1_o_force_pipe1_r <= 1'b0;
            qc1_o_pc_r <= {`PC_WIDTH{1'b0}};
            qc1_o_imm_r <= {`IMM_WIDTH{1'b0}};
            qc1_o_data_rs_r <= {`DWIDTH{1'b0}};
            qc1_o_data_rt_r <= {`DWIDTH{1'b0}};
            qc1_o_addr_rd_r <= {`AWIDTH{1'b0}};
            qc1_o_addr_rs_r <= {`AWIDTH{1'b0}};
            qc1_o_addr_rt_r <= {`AWIDTH{1'b0}};
            qc1_o_funct_r <= {`FUNCT_WIDTH{1'b0}};
            qc1_o_jal_addr_r <= {`JUMP_WIDTH{1'b0}};
            qc1_o_opcode_r <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            qc1_o_ce_r <= qc1_o_ce;
            qc1_o_jr_r <= qc1_o_jr;
            qc1_o_pc_r <= qc1_o_pc;
            qc1_o_jal_r <= qc1_o_jal;
            qc1_o_imm_r <= qc1_o_imm;
            qc1_o_funct_r <= qc1_o_funct;
            qc1_o_opcode_r <= qc1_o_opcode;
            qc1_o_data_rs_r <= qc1_o_data_rs;
            qc1_o_data_rt_r <= qc1_o_data_rt;
            qc1_o_addr_rd_r <= qc1_o_addr_rd;
            qc1_o_addr_rs_r <= qc1_o_addr_rs;
            qc1_o_addr_rt_r <= qc1_o_addr_rt;
            qc1_o_reg_dst_r <= qc1_o_reg_dst;
            qc1_o_alu_src_r <= qc1_o_alu_src;
            qc1_o_jal_addr_r <= qc1_o_jal_addr;
            qc1_o_memtoreg_r <= qc1_o_memtoreg;
            qc1_o_memwrite_r <= qc1_o_memwrite;
            qc1_o_regwrite_r <= qc1_o_regwrite;
            qc1_o_force_pipe1_r <= qc1_o_force_pipe1;
        end
    end

    wire mc1_o_ce;
    wire mc1_o_reg_dst;
    wire mc1_o_alu_src;
    wire mc1_o_reg_write;
    wire mc1_o_jr, mc1_o_jal;
    wire [`PC_WIDTH - 1 : 0] mc1_o_pc;
    wire mc1_o_memtoreg, mc1_o_memwrite;
    wire [`IMM_WIDTH - 1 : 0] mc1_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] mc1_o_funct;
    wire [`JUMP_WIDTH - 1 : 0] mc1_o_jal_addr;
wire [`OPCODE_WIDTH - 1 : 0] mc1_o_opcode;
    wire [`DWIDTH - 1 : 0] mc1_o_data_rs, mc1_o_data_rt;
    wire [`AWIDTH - 1 : 0] mc1_o_addr_rd, mc1_o_addr_rs, mc1_o_addr_rt;
    // chooser: select queue when ES1 has signaled fetch; force selection if the entry must run on pipe 1
    wire choose_mux_1 = (es1_o_qc1) && (qc1_o_force_pipe1_r || qc1_i_cd1);
    mux_comps mc1 (
        .choose_comp(choose_mux_1), 
        .m1_i_ce(qc1_o_ce_r), 
        .m1_i_jr(qc1_o_jr_r), 
        .m1_i_pc(qc1_o_pc_r),
        .m1_i_jal(qc1_o_jal_r), 
        .m1_i_imm(qc1_o_imm_r), 
        .m1_i_funct(qc1_o_funct_r), 
        .m1_i_opcode(qc1_o_opcode_r), 
        .m1_i_reg_dst(qc1_o_reg_dst_r), 
        .m1_i_alu_src(qc1_o_alu_src_r), 
        .m1_i_data_rs(qc1_o_data_rs_r), 
        .m1_i_data_rt(qc1_o_data_rt_r), 
        .m1_i_addr_rd(qc1_o_addr_rd_r), 
        .m1_i_addr_rs(qc1_o_addr_rs_r), 
        .m1_i_addr_rt(qc1_o_addr_rt_r), 
        .m1_i_jal_addr(qc1_o_jal_addr_r), 
        .m1_i_memwrite(qc1_o_memwrite_r), 
        .m1_i_memtoreg(qc1_o_memtoreg_r),
        .m1_i_reg_write(qc1_o_regwrite_r), 
        .m2_i_ce(ds1_es1_o_ce), 
        .m2_i_pc(ds1_es1_o_pc),
        .m2_i_jr(ds1_es1_o_jr), 
        .m2_i_jal(ds1_es1_o_jal), 
        .m2_i_imm(ds1_es1_o_imm), 
        .m2_i_funct(ds1_es1_o_funct), 
        .m2_i_opcode(ds1_es1_o_opcode), 
        .m2_i_reg_dst(ds1_es1_o_reg_dst), 
        .m2_i_alu_src(ds1_es1_o_alu_src), 
        .m2_i_data_rs(ds1_es1_o_data_rs), 
        .m2_i_data_rt(ds1_es1_o_data_rt), 
        .m2_i_addr_rd(ds1_es1_o_addr_rd), 
        .m2_i_addr_rs(ds1_es1_o_addr_rs),
        .m2_i_addr_rt(ds1_es1_o_addr_rt), 
        .m2_i_jal_addr(ds1_es1_o_jal_addr), 
        .m2_i_memwrite(ds1_es1_o_memwrite), 
        .m2_i_memtoreg(ds1_es1_o_memtoreg),
        .m2_i_reg_write(ds1_es1_o_reg_write), 
        .mc_o_ce(mc1_o_ce), 
        .mc_o_jr(mc1_o_jr), 
        .mc_o_pc(mc1_o_pc),
        .mc_o_jal(mc1_o_jal), 
        .mc_o_imm(mc1_o_imm), 
        .mc_o_funct(mc1_o_funct), 
        .mc_o_opcode(mc1_o_opcode), 
        .mc_o_reg_dst(mc1_o_reg_dst), 
        .mc_o_alu_src(mc1_o_alu_src), 
        .mc_o_data_rs(mc1_o_data_rs), 
        .mc_o_data_rt(mc1_o_data_rt), 
        .mc_o_addr_rd(mc1_o_addr_rd), 
        .mc_o_addr_rs(mc1_o_addr_rs), 
        .mc_o_addr_rt(mc1_o_addr_rt),
        .mc_o_jal_addr(mc1_o_jal_addr), 
        .mc_o_memwrite(mc1_o_memwrite), 
        .mc_o_memtoreg(mc1_o_memtoreg), 
        .mc_o_reg_write(mc1_o_reg_write)
    );

    mux_comps mc3 (
        .choose_comp(cc_qc2_o_we), 
        .m1_i_ce(cc_qc2_o_ce), 
        .m1_i_pc(cc_qc2_o_pc), 
        .m1_i_jr(cc_qc2_o_jr), 
        .m1_i_jal(cc_qc2_o_jal), 
        .m1_i_imm(cc_qc2_o_imm), 
        .m1_i_funct(cc_qc2_o_funct), 
        .m1_i_opcode(cc_qc2_o_opcode), 
        .m1_i_reg_dst(cc_qc2_o_reg_dst), 
        .m1_i_alu_src(cc_qc2_o_alu_src), 
        .m1_i_data_rs(cc_qc2_o_data_rs), 
        .m1_i_data_rt(cc_qc2_o_data_rt), 
        .m1_i_addr_rd(cc_qc2_o_addr_rd),
.m1_i_addr_rs(cc_qc2_o_addr_rs), 
        .m1_i_addr_rt(cc_qc2_o_addr_rt), 
        .m1_i_memwrite(cc_qc2_o_memwrite), 
        .m1_i_memtoreg(cc_qc2_o_memtoreg),
        .m1_i_jal_addr(cc_qc2_o_jal_addr), 
        .m1_i_reg_write(cc_qc2_o_reg_write), 
        .m2_i_jr(ds1_es1_o_jr), 
        .m2_i_ce(ds1_es1_o_ce), 
        .m2_i_jal(ds1_es1_o_jal), 
        .m2_i_reg_dst(ds1_es1_o_reg_dst), 
        .m2_i_alu_src(ds1_es1_o_alu_src), 
        .m2_i_memtoreg(ds1_es1_o_memtoreg),
        .m2_i_reg_write(ds1_es1_o_reg_write), 
        .m2_i_memwrite(ds1_es1_o_memwrite), 
        .m2_i_imm(ds1_es1_o_imm), 
        .m2_i_pc(ds1_es1_o_pc), 
        .m2_i_funct(ds1_es1_o_funct), 
        .m2_i_jal_addr(ds1_es1_o_jal_addr), 
        .m2_i_opcode(ds1_es1_o_opcode), 
        .m2_i_data_rs(ds1_es1_o_data_rs), 
        .m2_i_data_rt(ds1_es1_o_data_rt), 
        .m2_i_addr_rd(ds1_es1_o_addr_rd), 
        .m2_i_addr_rs(ds1_es1_o_addr_rs),
        .m2_i_addr_rt(ds1_es1_o_addr_rt),
        .mc_o_ce(mc_o_ce), 
        .mc_o_pc(mc_o_pc), 
        .mc_o_jr(mc_o_jr), 
        .mc_o_jal(mc_o_jal), 
        .mc_o_imm(mc_o_imm), 
        .mc_o_funct(mc_o_funct), 
        .mc_o_opcode(mc_o_opcode), 
        .mc_o_alu_src(mc_o_alu_src), 
        .mc_o_reg_dst(mc_o_reg_dst), 
        .mc_o_data_rs(mc_o_data_rs), 
        .mc_o_data_rt(mc_o_data_rt), 
        .mc_o_addr_rd(mc_o_addr_rd), 
        .mc_o_addr_rs(mc_o_addr_rs), 
        .mc_o_addr_rt(mc_o_addr_rt),
        .mc_o_memwrite(mc_o_memwrite), 
        .mc_o_memtoreg(mc_o_memtoreg), 
        .mc_o_jal_addr(mc_o_jal_addr), 
        .mc_o_reg_write(mc_o_reg_write) 
    );

    wire mc_o_ce;
    wire mc_o_jr;
    wire mc_o_jal;
    wire mc_o_reg_dst;
    wire mc_o_alu_src;
    wire mc_o_memtoreg;
    wire mc_o_memwrite;
    wire mc_o_reg_write;
    wire [`PC_WIDTH - 1 : 0] mc_o_pc;
    wire [`IMM_WIDTH - 1 : 0] mc_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] mc_o_funct;
    wire [`JUMP_WIDTH - 1 : 0] mc_o_jal_addr;
    wire [`OPCODE_WIDTH - 1 : 0] mc_o_opcode;
    wire [`DWIDTH - 1 : 0] mc_o_data_rs, mc_o_data_rt;
    wire [`AWIDTH - 1 : 0] mc_o_addr_rd, mc_o_addr_rs, mc_o_addr_rt;

    wire qc2_o_ce;
    wire qc2_o_reg_dst;
    wire qc2_o_alu_src;
    wire qc2_o_regwrite;
    wire qc2_o_jr, qc2_o_jal;
    wire [`PC_WIDTH - 1 : 0] qc2_o_pc;
    wire qc2_o_memtoreg, qc2_o_memwrite;
    wire [`IMM_WIDTH - 1 : 0] qc2_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] qc2_o_funct;
    wire [`JUMP_WIDTH - 1 : 0] qc2_o_jal_addr;
    wire [`OPCODE_WIDTH - 1 : 0] qc2_o_opcode;
    wire [`DWIDTH - 1 : 0] qc2_o_data_rs, qc2_o_data_rt;
    wire [`AWIDTH - 1 : 0] qc2_o_addr_rd, qc2_o_addr_rs, qc2_o_addr_rt;
    wire qc2_o_force_pipe1;
    queue_comps qc2 (
        .qc_clk(d_clk), 
        .qc_rst(d_rst), 
        .qc_i_we(cd2_q2_o_we), 
        .qc_i_ce(ds1_es1_o_ce), 
        .qc_i_jr(ds1_es1_o_jr), 
        .qc_i_pc(ds1_es1_o_pc),
        .qc_i_jal(ds1_es1_o_jal), 
        .qc_i_imm(ds1_es1_o_imm), 
        .qc_i_re(es2_o_qc2), 
        .qc_i_force_pipe1(cd2_q2_force_pipe1),
        .qc_i_funct(ds1_es1_o_funct),
.qc_i_opcode(ds1_es1_o_opcode), 
        .qc_i_reg_dst(ds1_es1_o_reg_dst), 
        .qc_i_alu_src(ds1_es1_o_alu_src), 
        .qc_i_data_rs(ds1_es1_o_data_rs), 
        .qc_i_data_rt(ds1_es1_o_data_rt), 
        .qc_i_addr_rd(ds1_es1_o_addr_rd), 
        .qc_i_addr_rs(ds1_es1_o_addr_rs), 
        .qc_i_addr_rt(ds1_es1_o_addr_rt), 
        .qc_i_memtoreg(ds1_es1_o_memtoreg), 
        .qc_i_memwrite(ds1_es1_o_memwrite),
        .qc_i_jal_addr(ds1_es1_o_jal_addr), 
        .qc_i_reg_write(ds1_es1_o_reg_write), 
        .qc_o_ce(qc2_o_ce), 
        .qc_o_jr(qc2_o_jr), 
        .qc_o_pc(qc2_o_pc),
        .qc_o_jal(qc2_o_jal), 
        .qc_o_imm(qc2_o_imm), 
        .qc_o_funct(qc2_o_funct), 
        .qc_o_opcode(qc2_o_opcode), 
        .qc_o_addr_rd(qc2_o_addr_rd), 
        .qc_o_addr_rs(qc2_o_addr_rs), 
        .qc_o_addr_rt(qc2_o_addr_rt), 
        .qc_o_reg_dst(qc2_o_reg_dst), 
        .qc_o_alu_src(qc2_o_alu_src), 
        .qc_o_data_rs(qc2_o_data_rs), 
        .qc_o_data_rt(qc2_o_data_rt), 
        .qc_o_memtoreg(qc2_o_memtoreg), 
        .qc_o_memwrite(qc2_o_memwrite), 
        .qc_o_jal_addr(qc2_o_jal_addr), 
        .qc_o_regwrite(qc2_o_regwrite),
        .qc_o_force_pipe1(qc2_o_force_pipe1)
    );

    // Register queue outputs for qc2 to stabilize inputs to mux2
    reg qc2_o_ce_r;
    reg qc2_o_jr_r;
    reg qc2_o_jal_r;
    reg qc2_o_reg_dst_r;
    reg qc2_o_alu_src_r;
    reg qc2_o_regwrite_r;
    reg qc2_o_memtoreg_r;
    reg qc2_o_memwrite_r;
    reg [`PC_WIDTH - 1 : 0] qc2_o_pc_r;
    reg [`IMM_WIDTH - 1 : 0] qc2_o_imm_r;
    reg [`FUNCT_WIDTH - 1 : 0] qc2_o_funct_r;
    reg [`JUMP_WIDTH - 1 : 0] qc2_o_jal_addr_r;
    reg [`OPCODE_WIDTH - 1 : 0] qc2_o_opcode_r;
    reg [`DWIDTH - 1 : 0] qc2_o_data_rs_r, qc2_o_data_rt_r;
    reg [`AWIDTH - 1 : 0] qc2_o_addr_rd_r, qc2_o_addr_rs_r, qc2_o_addr_rt_r;
    
    // capture queue outputs for qc2 on posedge so combinational mux downstream sees stable values
    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            qc2_o_ce_r <= 1'b0;
            qc2_o_jr_r <= 1'b0;
            qc2_o_jal_r <= 1'b0;
            qc2_o_alu_src_r <= 1'b0;
            qc2_o_reg_dst_r <= 1'b0;
            qc2_o_memtoreg_r <= 1'b0;
            qc2_o_memwrite_r <= 1'b0;
            qc2_o_regwrite_r <= 1'b0;
            qc2_o_pc_r <= {`PC_WIDTH{1'b0}};
            qc2_o_imm_r <= {`IMM_WIDTH{1'b0}};
            qc2_o_data_rs_r <= {`DWIDTH{1'b0}};
            qc2_o_data_rt_r <= {`DWIDTH{1'b0}};
            qc2_o_addr_rd_r <= {`AWIDTH{1'b0}};
            qc2_o_addr_rs_r <= {`AWIDTH{1'b0}};
            qc2_o_addr_rt_r <= {`AWIDTH{1'b0}};
            qc2_o_funct_r <= {`FUNCT_WIDTH{1'b0}};
            qc2_o_jal_addr_r <= {`JUMP_WIDTH{1'b0}};
            qc2_o_opcode_r <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            qc2_o_ce_r <= qc2_o_ce;
            qc2_o_jr_r <= qc2_o_jr;
            qc2_o_pc_r <= qc2_o_pc;
            qc2_o_jal_r <= qc2_o_jal;
            qc2_o_imm_r <= qc2_o_imm;
qc2_o_funct_r <= qc2_o_funct;
            qc2_o_opcode_r <= qc2_o_opcode;
            qc2_o_data_rs_r <= qc2_o_data_rs;
            qc2_o_data_rt_r <= qc2_o_data_rt;
            qc2_o_addr_rd_r <= qc2_o_addr_rd;
            qc2_o_addr_rs_r <= qc2_o_addr_rs;
            qc2_o_addr_rt_r <= qc2_o_addr_rt;
            qc2_o_reg_dst_r <= qc2_o_reg_dst;
            qc2_o_alu_src_r <= qc2_o_alu_src;
            qc2_o_jal_addr_r <= qc2_o_jal_addr;
            qc2_o_memtoreg_r <= qc2_o_memtoreg;
            qc2_o_memwrite_r <= qc2_o_memwrite;
            qc2_o_regwrite_r <= qc2_o_regwrite;
        end
    end
    // TODO:
    wire ci_o_ce;
    wire ci_o_reg_dst;
    wire ci_o_alu_src;
    wire ci_o_memwrite;
    wire ci_o_memtoreg;
    wire ci_o_regwrite;
    wire ci_o_jr, ci_o_jal;
    wire [`PC_WIDTH - 1 : 0] ci_o_pc;
    wire [`IMM_WIDTH - 1 : 0] ci_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] ci_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ci_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ci_o_jal_addr;
    wire [`DWIDTH - 1 : 0] ci_o_data_rs, ci_o_data_rt;
    wire [`AWIDTH - 1 : 0] ci_o_addr_rd, ci_o_addr_rs, ci_o_addr_rt;
    check_instr ci (
        .ci_clk(d_clk), 
        .ci_rst(d_rst), 
        .ci_i_ce_2(qc2_o_ce_r), 
        .ci_i_jr_2(qc2_o_jr_r), 
        .ci_i_pc_2(qc2_o_pc_r), 
        .ci_i_jal_2(qc2_o_jal_r), 
        .ci_i_imm_2(qc2_o_imm_r), 
        .ci_i_funct_2(qc2_o_funct_r), 
        .ci_i_opcode_2(qc2_o_opcode_r),
        .ci_i_reg_dst_2(qc2_o_reg_dst_r), 
        .ci_i_alu_src_2(qc2_o_alu_src_r), 
        .ci_i_data_rs_2(qc2_o_data_rs_r), 
        .ci_i_data_rt_2(qc2_o_data_rt_r), 
        .ci_i_addr_rd_2(qc2_o_addr_rd_r), 
        .ci_i_addr_rs_2(qc2_o_addr_rs_r), 
        .ci_i_addr_rt_2(qc2_o_addr_rt_r),
        .ci_i_jal_addr_2(qc2_o_jal_addr_r), 
        .ci_i_memwrite_2(qc2_o_memwrite_r), 
        .ci_i_memtoreg_2(qc2_o_memtoreg_r), 
        .ci_i_regwrite_2(qc2_o_regwrite_r), 
        .ci_i_addr_rd_1(mc1_o_addr_rd), 
        .ci_i_addr_rs_1(mc1_o_addr_rs), 
        .ci_i_addr_rt_1(mc1_o_addr_rt), 
        .ci_o_ce(ci_o_ce), 
        .ci_o_jr(ci_o_jr), 
        .ci_o_jal(ci_o_jal), 
        .ci_o_pc(ci_o_pc), 
        .ci_o_imm(ci_o_imm), 
        .ci_o_funct(ci_o_funct), 
        .ci_o_opcode(ci_o_opcode), 
        .ci_o_alu_src(ci_o_alu_src), 
        .ci_o_data_rs(ci_o_data_rs), 
        .ci_o_data_rt(ci_o_data_rt), 
        .ci_o_addr_rd(ci_o_addr_rd), 
        .ci_o_addr_rs(ci_o_addr_rs), 
        .ci_o_addr_rt(ci_o_addr_rt), 
        .ci_o_reg_dst(ci_o_reg_dst), 
        .ci_o_jal_addr(ci_o_jal_addr), 
        .ci_o_memwrite(ci_o_memwrite), 
        .ci_o_memtoreg(ci_o_memtoreg), 
        .ci_o_regwrite(ci_o_regwrite) 
    );
    
    wire mc2_o_ce;
    wire mc2_o_reg_dst;
    wire mc2_o_alu_src;
    wire mc2_o_reg_write;
    wire mc2_o_jr, mc2_o_jal;
    wire [`PC_WIDTH - 1 : 0] mc2_o_pc;
    wire mc2_o_memtoreg, mc2_o_memwrite;
    wire [`IMM_WIDTH - 1 : 0] mc2_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] mc2_o_funct;
wire [`JUMP_WIDTH - 1 : 0] mc2_o_jal_addr;
    wire [`OPCODE_WIDTH - 1 : 0] mc2_o_opcode;
    wire [`DWIDTH - 1 : 0] mc2_o_data_rs, mc2_o_data_rt;
    wire [`AWIDTH - 1 : 0] mc2_o_addr_rd, mc2_o_addr_rs, mc2_o_addr_rt;
    // chooser for mc2
    wire choose_mux_2 = (es2_o_qc2) && qc2_i_cd2;
    wire block_ds2_direct_issue = cd1_o_force_pipe1;
    mux_comps mc2 (
        .choose_comp(choose_mux_2), 
        .m1_i_ce(ci_o_ce), 
        .m1_i_jr(ci_o_jr), 
        .m1_i_pc(ci_o_pc),
        .m1_i_jal(ci_o_jal), 
        .m1_i_imm(ci_o_imm), 
        .m1_i_funct(ci_o_funct), 
        .m1_i_opcode(ci_o_opcode), 
        .m1_i_reg_dst(ci_o_reg_dst), 
        .m1_i_alu_src(ci_o_alu_src), 
        .m1_i_data_rs(ci_o_data_rs), 
        .m1_i_data_rt(ci_o_data_rt), 
        .m1_i_addr_rd(ci_o_addr_rd), 
        .m1_i_addr_rs(ci_o_addr_rs), 
        .m1_i_addr_rt(ci_o_addr_rt), 
        .m1_i_jal_addr(ci_o_jal_addr), 
        .m1_i_memwrite(ci_o_memwrite), 
        .m1_i_memtoreg(ci_o_memtoreg),
        .m1_i_reg_write(ci_o_regwrite), 
        .m2_i_ce(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_ce), 
        .m2_i_pc(block_ds2_direct_issue ? {`PC_WIDTH{1'b0}} : ds2_es2_o_pc),
        .m2_i_jr(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_jr), 
        .m2_i_jal(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_jal), 
        .m2_i_imm(block_ds2_direct_issue ? {`IMM_WIDTH{1'b0}} : ds2_es2_o_imm), 
        .m2_i_funct(block_ds2_direct_issue ? {`FUNCT_WIDTH{1'b0}} : ds2_es2_o_funct), 
        .m2_i_opcode(block_ds2_direct_issue ? {`OPCODE_WIDTH{1'b0}} : ds2_es2_o_opcode), 
        .m2_i_reg_dst(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_reg_dst), 
        .m2_i_alu_src(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_alu_src), 
        .m2_i_data_rs(block_ds2_direct_issue ? {`DWIDTH{1'b0}} : ds2_es2_o_data_rs), 
        .m2_i_data_rt(block_ds2_direct_issue ? {`DWIDTH{1'b0}} : ds2_es2_o_data_rt), 
        .m2_i_addr_rd(block_ds2_direct_issue ? {`AWIDTH{1'b0}} : ds2_es2_o_addr_rd), 
        .m2_i_addr_rs(block_ds2_direct_issue ? {`AWIDTH{1'b0}} : ds2_es2_o_addr_rs),
        .m2_i_addr_rt(block_ds2_direct_issue ? {`AWIDTH{1'b0}} : ds2_es2_o_addr_rt), 
        .m2_i_jal_addr(block_ds2_direct_issue ? {`JUMP_WIDTH{1'b0}} : ds2_es2_o_jal_addr), 
        .m2_i_memwrite(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_memwrite), 
        .m2_i_memtoreg(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_memtoreg),
        .m2_i_reg_write(block_ds2_direct_issue ? 1'b0 : ds2_es2_o_reg_write), 
        .mc_o_ce(mc2_o_ce), 
        .mc_o_jr(mc2_o_jr), 
        .mc_o_pc(mc2_o_pc),
        .mc_o_jal(mc2_o_jal), 
        .mc_o_imm(mc2_o_imm), 
        .mc_o_funct(mc2_o_funct), 
        .mc_o_opcode(mc2_o_opcode), 
        .mc_o_reg_dst(mc2_o_reg_dst), 
        .mc_o_alu_src(mc2_o_alu_src), 
        .mc_o_data_rs(mc2_o_data_rs), 
        .mc_o_data_rt(mc2_o_data_rt), 
        .mc_o_addr_rd(mc2_o_addr_rd), 
        .mc_o_addr_rs(mc2_o_addr_rs), 
        .mc_o_addr_rt(mc2_o_addr_rt),
        .mc_o_jal_addr(mc2_o_jal_addr), 
        .mc_o_memwrite(mc2_o_memwrite), 
        .mc_o_memtoreg(mc2_o_memtoreg), 
        .mc_o_reg_write(mc2_o_reg_write)
    );

    wire cc_o_we;
    wire cc_o_ce;
    wire cc_o_jr;
    wire cc_o_jal;
    wire cc_o_ce_1;
    wire cc_o_reg_dst;
    wire cc_o_alu_src;
    wire cc_o_memwrite;
    wire cc_o_memtoreg;
    wire cc_o_reg_write;
    wire [`PC_WIDTH - 1 : 0] cc_o_pc;
    wire [`IMM_WIDTH - 1 : 0] cc_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] cc_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] cc_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] cc_o_jal_addr;
    wire [`DWIDTH - 1 : 0] cc_o_data_rs, cc_o_data_rt;
    wire [`AWIDTH - 1 : 0] cc_o_addr_rd, cc_o_addr_rs, cc_o_addr_rt;
    choose_comps cc (
        .cc_i_ce_1(mc1_o_ce),
.cc_i_jr_1(mc1_o_jr), 
        .cc_i_pc_1(mc1_o_pc), 
        .cc_i_jal_1(mc1_o_jal), 
        .cc_i_imm_1(mc1_o_imm), 
        .cc_i_funct_1(mc1_o_funct), 
        .cc_i_opcode_1(mc1_o_opcode), 
        .cc_i_reg_dst_1(mc1_o_reg_dst),
        .cc_i_alu_src_1(mc1_o_alu_src), 
        .cc_i_data_rs_1(mc1_o_data_rs), 
        .cc_i_data_rt_1(mc1_o_data_rt), 
        .cc_i_addr_rd_1(mc1_o_addr_rd), 
        .cc_i_addr_rs_1(mc1_o_addr_rs), 
        .cc_i_addr_rt_1(mc1_o_addr_rt), 
        .cc_i_jal_addr_1(mc1_o_jal_addr), 
        .cc_i_memwrite_1(mc1_o_memwrite), 
        .cc_i_memtoreg_1(mc1_o_memtoreg), 
        .cc_i_reg_write_1(mc1_o_reg_write),
        .cc_i_ce_2(mc2_o_ce), 
        .cc_i_jr_2(mc2_o_jr), 
        .cc_i_pc_2(mc2_o_pc),
        .cc_i_jal_2(mc2_o_jal), 
        .cc_i_imm_2(mc2_o_imm), 
        .cc_i_funct_2(mc2_o_funct), 
        .cc_i_opcode_2(mc2_o_opcode), 
        .cc_i_reg_dst_2(mc2_o_reg_dst),
        .cc_i_alu_src_2(mc2_o_alu_src), 
        .cc_i_data_rs_2(mc2_o_data_rs), 
        .cc_i_data_rt_2(mc2_o_data_rt), 
        .cc_i_addr_rd_2(mc2_o_addr_rd), 
        .cc_i_addr_rs_2(mc2_o_addr_rs), 
        .cc_i_addr_rt_2(mc2_o_addr_rt), 
        .cc_i_jal_addr_2(mc2_o_jal_addr), 
        .cc_i_memwrite_2(mc2_o_memwrite), 
        .cc_i_memtoreg_2(mc2_o_memtoreg), 
        .cc_i_reg_write_2(mc2_o_reg_write), 
        .cc_o_we(cc_o_we), 
        .cc_o_ce(cc_o_ce), 
        .cc_o_jr(cc_o_jr), 
        .cc_o_pc(cc_o_pc), 
        .cc_o_jal(cc_o_jal), 
        .cc_o_imm(cc_o_imm), 
        .cc_o_ce_1(cc_o_ce_1),
        .cc_o_funct(cc_o_funct), 
        .cc_o_opcode(cc_o_opcode), 
        .cc_o_reg_dst(cc_o_reg_dst), 
        .cc_o_alu_src(cc_o_alu_src), 
        .cc_o_data_rs(cc_o_data_rs), 
        .cc_o_data_rt(cc_o_data_rt), 
        .cc_o_addr_rd(cc_o_addr_rd), 
        .cc_o_addr_rs(cc_o_addr_rs), 
        .cc_o_addr_rt(cc_o_addr_rt), 
        .cc_o_jal_addr(cc_o_jal_addr), 
        .cc_o_memwrite(cc_o_memwrite), 
        .cc_o_memtoreg(cc_o_memtoreg), 
        .cc_o_reg_write(cc_o_reg_write)
    );  

    reg cc_qc2_o_we;
    reg cc_qc2_o_ce;
    reg cc_qc2_o_jr;
    reg cc_qc2_o_jal;
    reg cc_qc2_o_ce_1;
    reg cc_qc2_o_reg_dst;
    reg cc_qc2_o_alu_src;
    reg cc_qc2_o_memwrite;
    reg cc_qc2_o_memtoreg;
    reg cc_qc2_o_reg_write;
    reg [`PC_WIDTH - 1 : 0] cc_qc2_o_pc;
    reg [`IMM_WIDTH - 1 : 0] cc_qc2_o_imm;
    reg [`FUNCT_WIDTH - 1 : 0] cc_qc2_o_funct;
    reg [`OPCODE_WIDTH - 1 : 0] cc_qc2_o_opcode;
    reg [`JUMP_WIDTH - 1 : 0] cc_qc2_o_jal_addr;
    reg [`DWIDTH - 1 : 0] cc_qc2_o_data_rs, cc_qc2_o_data_rt;
    reg [`AWIDTH - 1 : 0] cc_qc2_o_addr_rd, cc_qc2_o_addr_rs, cc_qc2_o_addr_rt;
    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            cc_qc2_o_we <= 1'b0;
            cc_qc2_o_ce <= 1'b0;
            cc_qc2_o_jr <= 1'b0;
            cc_qc2_o_jal <= 1'b0;
            cc_qc2_o_ce_1 <= 1'b0;
            cc_qc2_o_reg_dst <= 1'b0;
            cc_qc2_o_alu_src <= 1'b0;
cc_qc2_o_memwrite <= 1'b0;
            cc_qc2_o_memtoreg <= 1'b0;
            cc_qc2_o_reg_write <= 1'b0;
            cc_qc2_o_pc <= {`PC_WIDTH{1'b0}};
            cc_qc2_o_imm <= {`IMM_WIDTH{1'b0}};
            cc_qc2_o_data_rs <= {`DWIDTH{1'b0}};
            cc_qc2_o_data_rt <= {`DWIDTH{1'b0}};
            cc_qc2_o_addr_rd <= {`AWIDTH{1'b0}};
            cc_qc2_o_addr_rs <= {`AWIDTH{1'b0}}; 
            cc_qc2_o_addr_rt <= {`AWIDTH{1'b0}};
            cc_qc2_o_funct <= {`FUNCT_WIDTH{1'b0}};
            cc_qc2_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            cc_qc2_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
        end
        else begin
            cc_qc2_o_we <= cc_o_we;
            cc_qc2_o_ce <= cc_o_ce;
            cc_qc2_o_pc <= cc_o_pc;
            cc_qc2_o_jr <= cc_o_jr;
            cc_qc2_o_jal <= cc_o_jal;
            cc_qc2_o_imm <= cc_o_imm;
            cc_qc2_o_ce_1 <= cc_o_ce_1;
            cc_qc2_o_funct <= cc_o_funct;
            cc_qc2_o_opcode <= cc_o_opcode;
            cc_qc2_o_data_rs <= cc_o_data_rs;
            cc_qc2_o_data_rt <= cc_o_data_rt;
            cc_qc2_o_addr_rd <= cc_o_addr_rd;
            cc_qc2_o_addr_rs <= cc_o_addr_rs; 
            cc_qc2_o_addr_rt <= cc_o_addr_rt;
            cc_qc2_o_reg_dst <= cc_o_reg_dst;
            cc_qc2_o_alu_src <= cc_o_alu_src;
            cc_qc2_o_jal_addr <= cc_o_jal_addr;
            cc_qc2_o_memwrite <= cc_o_memwrite;
            cc_qc2_o_memtoreg <= cc_o_memtoreg;
            cc_qc2_o_reg_write <= cc_o_reg_write;
        end
    end

    wire [`AWIDTH - 1 : 0] es1_i_addr_rd;
    mux2_1 m1 (
        .mx_i_addr_rd(mc1_o_addr_rd), 
        .mx_i_addr_rt(mc1_o_addr_rt), 
        .mx_i_reg_dst(mc1_o_reg_dst), 
        .mx_o_addr_rd(es1_i_addr_rd)
    );

    wire [`AWIDTH - 1 : 0] es2_i_addr_rd;
    mux2_1 m2 (
        .mx_i_addr_rd(mc2_o_addr_rd), 
        .mx_i_addr_rt(mc2_o_addr_rt), 
        .mx_i_reg_dst(mc2_o_reg_dst), 
        .mx_o_addr_rd(es2_i_addr_rd)
    );

    // TODO: How to know when The system uses alu_value 1 or alu_value 2
    // Add some conditions to check when system uses es1 or es2, Maybe when es1 is trigged
    // TODO: Check lệnh ở luồng 1 đưa ra xem có trùng với lệnh ở luồng 2 tính toán không nếu có thì lệnh 1 sẽ 
    // được đưa về queue 2, thêm một tín hiệu ghi bảo ghi vào 2, tín hiệu này 
    // sẽ điều khiển việc tắt es1

    wire [`DWIDTH - 1 : 0] mx31_1_o_data_rs;
    mux3_1 mux31_1(
        .data(mc1_o_data_rs), 
        .alu_value(es1_ms_o_alu_value), 
        .cross_data(es2_o_alu_value),
        .write_back_data(wb_ds1_o_data_rd), 
        .forwarding(fw1_o_data_rs), 
        .data_out(mx31_1_o_data_rs)
    );

    wire [`DWIDTH - 1 : 0] mx31_1_o_data_rt;
    mux3_1 mux31_2(
        .data(mc1_o_data_rt),
        .alu_value(es1_ms_o_alu_value), 
        .cross_data(es2_o_alu_value),
        .write_back_data(wb_ds1_o_data_rd), 
        .forwarding(fw1_o_data_rt), 
        .data_out(mx31_1_o_data_rt)
    );

    wire [`DWIDTH - 1 : 0] mx31_2_o_data_rs;
    mux3_1 mux31_3(
        .data(mc2_o_data_rs), 
        .alu_value(es2_ms_o_alu_value), 
        .cross_data(es1_o_alu_value),
        .write_back_data(wb_ds2_o_data_rd), 
        .forwarding(fw2_o_data_rs), 
        .data_out(mx31_2_o_data_rs)
    );

    wire [`DWIDTH - 1 : 0] mx31_2_o_data_rt;
    mux3_1 mux31_4(
        .data(mc2_o_data_rt), 
        .alu_value(es2_ms_o_alu_value), 
        .cross_data(es1_o_alu_value),
        .write_back_data(wb_ds2_o_data_rd), 
        .forwarding(fw2_o_data_rt), 
        .data_out(mx31_2_o_data_rt)
    );

    reg es1_ms_o_ce;
    reg es1_ms_o_memwrite;
    reg es1_ms_o_memtoreg;
    reg es1_ms_o_regwrite;
    reg es1_queue2_o_fetch;
    reg es1_ctrl1_o_change_pc;
    reg [`AWIDTH - 1 : 0] es1_ms_o_addr_rd;
    reg [`DWIDTH - 1 : 0] es1_ms_o_alu_value;
    reg [`PC_WIDTH - 1 : 0] es1_ctrl1_o_alu_pc;
    reg [`OPCODE_WIDTH - 1 : 0] es1_ms_o_opcode;
    wire es1_o_ce;
    wire es1_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] es1_o_alu_pc;
    wire [`DWIDTH - 1 : 0] es1_o_alu_value;
    wire [`OPCODE_WIDTH - 1 : 0] es1_o_opcode;
    wire es1_o_fetch_queue;
    wire [`AWIDTH - 1 : 0] es1_o_addr_rd;
    execute_stage es1 (
        .es_i_ce(mc1_o_ce), 
        .es_i_jr(mc1_o_jr), 
        .es_i_jal(mc1_o_jal), 
        .es_i_fetch_queue(cd1_o_we), 
        .es_i_jal_addr(mc1_o_jal_addr), 
        .es_i_pc(mc1_o_pc), 
        .es_i_alu_src(mc1_o_alu_src), 
        .es_i_imm(mc1_o_imm), 
        .es_i_alu_op(mc1_o_opcode), 
        .es_i_alu_funct(mc1_o_funct),
        .es_i_addr_rd(es1_i_addr_rd),
        .es_i_data_rs(mx31_1_o_data_rs), 
        .es_i_data_rt(mx31_1_o_data_rt), 
        .es_o_ce(es1_o_ce), 
        .es_o_alu_pc(es1_o_alu_pc), 
        .es_o_opcode(es1_o_opcode), 
        .es_o_change_pc(es1_o_change_pc), 
        .es_o_alu_value(es1_o_alu_value), 
        .es_o_fetch_queue(es1_o_fetch_queue),
        .es_o_addr_rd(es1_o_addr_rd)
    );

    reg es2_ms_o_ce;
    reg es2_ms_o_memwrite;
    reg es2_ms_o_memtoreg;
    reg es2_ms_o_regwrite;
    reg es2_queue1_o_fetch;
    reg es2_ctrl2_o_change_pc;
    reg [`AWIDTH - 1 : 0] es2_ms_o_addr_rd;
    reg [`OPCODE_WIDTH - 1 : 0] es2_ms_o_opcode;
    reg [`DWIDTH - 1 : 0] es2_ms_o_alu_value;
    reg [`PC_WIDTH - 1 : 0] es2_ctrl2_o_alu_pc;
    wire es2_o_ce;
    wire es2_o_change_pc;
    wire es2_o_fetch_queue;
    wire [`PC_WIDTH - 1 : 0] es2_o_alu_pc;
    wire [`DWIDTH - 1 : 0] es2_o_alu_value;
    wire [`OPCODE_WIDTH - 1 : 0] es2_o_opcode;
    wire [`AWIDTH - 1 : 0] es2_o_addr_rd;
    wire es1_ex_regwrite = mc1_o_ce && mc1_o_reg_write;
    wire es1_ex_memread = mc1_o_ce && mc1_o_memtoreg;
    wire es2_ex_regwrite = mc2_o_ce && mc2_o_reg_write;
    wire es2_ex_memread = mc2_o_ce && mc2_o_memtoreg;
    execute_stage es2 (
        .es_i_ce(mc2_o_ce), 
        .es_i_jr(mc2_o_jr), 
        .es_i_jal(mc2_o_jal), 
        .es_i_fetch_queue(cd2_o_we), 
        .es_i_jal_addr(mc2_o_jal_addr), 
        .es_i_pc(mc2_o_pc),
.es_i_alu_src(mc2_o_alu_src), 
        .es_i_imm(mc2_o_imm), 
        .es_i_alu_op(mc2_o_opcode), 
        .es_i_alu_funct(mc2_o_funct),
        .es_i_addr_rd(es2_i_addr_rd),
        .es_i_data_rs(mx31_2_o_data_rs), 
        .es_i_data_rt(mx31_2_o_data_rt), 
        .es_o_ce(es2_o_ce),  
        .es_o_alu_pc(es2_o_alu_pc), 
        .es_o_opcode(es2_o_opcode), 
        .es_o_alu_value(es2_o_alu_value), 
        .es_o_change_pc(es2_o_change_pc), 
        .es_o_fetch_queue(es2_o_fetch_queue),
        .es_o_addr_rd(es2_o_addr_rd)
    );

    wire [3 : 0] ts1_o_store_mask;
    wire [`DWIDTH - 1 : 0] ts1_o_store_data;
    reg [3 : 0] ts1_ms_o_store_mask;
    reg [`DWIDTH - 1 : 0] ts1_ms_o_store_data;
    treatstore ts1 (
        .ts_i_store_data(mc1_o_data_rt), 
        .ts_i_opcode(mc1_o_opcode), 
        .ts_o_store_data(ts1_o_store_data), 
        .ts_o_store_mask(ts1_o_store_mask)
    );

    wire [3 : 0] ts2_o_store_mask;
    wire [`DWIDTH - 1 : 0] ts2_o_store_data;
    reg [3 : 0] ts2_ms_o_store_mask;
    reg [`DWIDTH - 1 : 0] ts2_ms_o_store_data;
    treatstore ts2 (
        .ts_i_store_data(mc2_o_data_rt), 
        .ts_i_opcode(mc2_o_opcode), 
        .ts_o_store_data(ts2_o_store_data), 
        .ts_o_store_mask(ts2_o_store_mask)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            es1_ms_o_ce <= 1'b0;
            es1_ms_o_memwrite <= 1'b0;
            es1_ms_o_memtoreg <= 1'b0;
            es1_ms_o_regwrite <= 1'b0;
            es1_queue2_o_fetch <= 1'b0;
            ts1_ms_o_store_mask <= 4'b0;
            es1_ctrl1_o_change_pc <= 1'b0;
            es1_ms_o_addr_rd <= {`AWIDTH{1'b0}};
            es1_ms_o_alu_value <= {`DWIDTH{1'b0}};
            ts1_ms_o_store_data <= {`DWIDTH{1'b0}};
            es1_ctrl1_o_alu_pc <= {`PC_WIDTH{1'b0}};
            es1_ms_o_opcode <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            es1_ms_o_ce <= es1_o_ce;
            es1_ms_o_opcode <= es1_o_opcode;
            es1_ms_o_addr_rd <= es1_o_addr_rd;
            es1_ctrl1_o_alu_pc <= es1_o_alu_pc;
            es1_ms_o_alu_value <= es1_o_alu_value;
            es1_ms_o_memwrite <= mc1_o_memwrite;
            es1_ms_o_memtoreg <= mc1_o_memtoreg;
            ts1_ms_o_store_mask <= ts1_o_store_mask;
            ts1_ms_o_store_data <= ts1_o_store_data;
            es1_queue2_o_fetch <= es1_o_fetch_queue;
            es1_ms_o_regwrite <= mc1_o_reg_write;
            es1_ctrl1_o_change_pc <= es1_o_change_pc;
        end
    end

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            es2_ms_o_ce <= 1'b0;
            es2_ms_o_memwrite <= 1'b0;
            es2_ms_o_memtoreg <= 1'b0;
            es2_ms_o_regwrite <= 1'b0;
            es2_queue1_o_fetch <= 1'b0;
            ts2_ms_o_store_mask <= 4'b0;
            es2_ctrl2_o_change_pc <= 1'b0;
            es2_ms_o_addr_rd <= {`AWIDTH{1'b0}};
            es2_ms_o_alu_value <= {`DWIDTH{1'b0}};
            ts2_ms_o_store_data <= {`DWIDTH{1'b0}};
            es2_ctrl2_o_alu_pc <= {`PC_WIDTH{1'b0}};
es2_ms_o_opcode <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            es2_ms_o_ce <= es2_o_ce;
            es2_ms_o_opcode <= es2_o_opcode;
            es2_ms_o_addr_rd <= es2_o_addr_rd;
            es2_ctrl2_o_alu_pc <= es2_o_alu_pc;
            es2_ms_o_alu_value <= es2_o_alu_value;
            es2_ms_o_memwrite <= mc2_o_memwrite;
            es2_ms_o_memtoreg <= mc2_o_memtoreg;
            ts2_ms_o_store_mask <= ts2_o_store_mask;
            ts2_ms_o_store_data <= ts2_o_store_data;
            es2_queue1_o_fetch <= es2_o_fetch_queue;
            es2_ms_o_regwrite <= mc2_o_reg_write;
            es2_ctrl2_o_change_pc <= es2_o_change_pc;
        end
    end

    wire [`DWIDTH - 1 : 0] ms_o_load_data_1, ms_o_load_data_2;
    reg ms_wb1_o_memtoreg, ms_wb2_o_memtoreg;
    reg ms_wb1_o_regwrite, ms_wb2_o_regwrite;
    reg [`AWIDTH - 1 : 0] ms_wb1_o_addr_rd, ms_wb2_o_addr_rd;
    reg [`DWIDTH - 1 : 0] ms_wb1_o_alu_value, ms_wb2_o_alu_value;
    reg [`DWIDTH - 1 : 0] ms_wb1_o_load_data_1, ms_wb2_o_load_data_2;
    memory m (
        .m_clk(d_clk), 
        .m_rst(d_rst), 
        .m_i_ce_1(es1_ms_o_ce), 
        .m_i_ce_2(es2_ms_o_ce), 
        .m_i_wr_en_1(es1_ms_o_memwrite), 
        .m_i_wr_en_2(es2_ms_o_memwrite), 
        .m_i_mask_1(ts1_ms_o_store_mask), 
        .m_i_mask_2(ts2_ms_o_store_mask), 
        .m_i_data_rs_1(ts1_ms_o_store_data), 
        .m_i_data_rs_2(ts2_ms_o_store_data), 
        .m_i_alu_value_1(es1_ms_o_alu_value), 
        .m_i_alu_value_2(es2_ms_o_alu_value), 
        .m_o_load_data_1(ms_o_load_data_1),
        .m_o_load_data_2(ms_o_load_data_2)
    );

    wire [`DWIDTH - 1 : 0] tl1_o_load_data;
    treatload tl1 (
        .tl_i_load_data(ms_o_load_data_1), 
        .tl_i_opcode(es1_ms_o_opcode),
        .tl_o_load_data(tl1_o_load_data)
    );

    wire [`DWIDTH - 1 : 0] tl2_o_load_data;
    treatload tl2 (
        .tl_i_load_data(ms_o_load_data_2), 
        .tl_i_opcode(es2_ms_o_opcode),
        .tl_o_load_data(tl2_o_load_data)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            ms_wb1_o_memtoreg <= 1'b0;
            ms_wb2_o_memtoreg <= 1'b0;
            ms_wb1_o_regwrite <= 1'b0;
            ms_wb2_o_regwrite <= 1'b0;
            ms_wb1_o_addr_rd <= {`AWIDTH{1'b0}};
            ms_wb2_o_addr_rd <= {`AWIDTH{1'b0}};
            ms_wb1_o_alu_value <= {`DWIDTH{1'b0}};
            ms_wb2_o_alu_value <= {`DWIDTH{1'b0}};
            ms_wb1_o_load_data_1 <= {`DWIDTH{1'b0}};
            ms_wb2_o_load_data_2 <= {`DWIDTH{1'b0}};
        end
        else begin
            ms_wb1_o_addr_rd <= es1_ms_o_addr_rd;
            ms_wb2_o_addr_rd <= es2_ms_o_addr_rd;
            ms_wb1_o_memtoreg <= es1_ms_o_memtoreg;
            ms_wb2_o_memtoreg <= es2_ms_o_memtoreg;
            ms_wb1_o_regwrite <= es1_ms_o_regwrite;
            ms_wb2_o_regwrite <= es2_ms_o_regwrite;
            ms_wb1_o_load_data_1 <= tl1_o_load_data;
            ms_wb2_o_load_data_2 <= tl2_o_load_data;
ms_wb1_o_alu_value <= es1_ms_o_alu_value;
            ms_wb2_o_alu_value <= es2_ms_o_alu_value;
        end 
    end

    wire es1_issue_load = mc1_o_ce && mc1_o_memtoreg && mc1_o_reg_write && (|es1_o_addr_rd);
    wire es1_commit_load = ms_wb1_o_memtoreg && ms_wb1_o_regwrite && (|ms_wb1_o_addr_rd);
    reg [(1 << `AWIDTH) - 1 : 0] pipe1_load_scoreboard;

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            pipe1_load_scoreboard <= {(1 << `AWIDTH){1'b0}};
        end
        else begin
            if (es1_commit_load) begin
                pipe1_load_scoreboard[ms_wb1_o_addr_rd] <= 1'b0;
            end
            if (es1_issue_load) begin
                pipe1_load_scoreboard[es1_o_addr_rd] <= 1'b1;
            end
        end
    end

    wire ds2_scoreboard_rs_block = (|ds2_es2_o_addr_rs) && pipe1_load_scoreboard[ds2_es2_o_addr_rs];
    wire ds2_scoreboard_rt_block = (|ds2_es2_o_addr_rt) && pipe1_load_scoreboard[ds2_es2_o_addr_rt];
    wire ds2_scoreboard_block = ds2_scoreboard_rs_block || ds2_scoreboard_rt_block;
    assign ds2_issue_stall = fw2_o_stall || ds2_scoreboard_block;

    wire fw1_o_stall;
    wire [1 : 0] fw1_o_data_rs, fw1_o_data_rt;
    forwarding fw1 (
        .ds_es_i_addr_rs1(mc1_o_addr_rs), 
        .ds_es_i_addr_rs2(mc1_o_addr_rt), 
        .self_ex_i_addr_rd(es1_ms_o_addr_rd), 
        .self_ex_i_regwrite(es1_ms_o_regwrite), 
        .self_ex_i_memread(es1_ms_o_memtoreg),
        .self_wb_i_addr_rd(ms_wb1_o_addr_rd), 
        .self_wb_i_regwrite(ms_wb1_o_regwrite), 
        .cross_ex_i_addr_rd(es2_o_addr_rd),
        .cross_ex_i_regwrite(es2_ex_regwrite),
        .cross_ex_i_memread(es2_ex_memread),
        .cross_wb_i_addr_rd(ms_wb2_o_addr_rd),
        .cross_wb_i_regwrite(ms_wb2_o_regwrite),
        .f_o_control_rs1(fw1_o_data_rs), 
        .f_o_control_rs2(fw1_o_data_rt),
        .f_o_stall(fw1_o_stall)
    );

    wire fw2_o_stall;
    wire [1 : 0] fw2_o_data_rs, fw2_o_data_rt;
    forwarding fw2 (
        .ds_es_i_addr_rs1(mc2_o_addr_rs),
        .ds_es_i_addr_rs2(mc2_o_addr_rt),
        .self_ex_i_addr_rd(es2_ms_o_addr_rd),
        .self_ex_i_regwrite(es2_ms_o_regwrite),
        .self_ex_i_memread(es2_ms_o_memtoreg),
        .self_wb_i_addr_rd(ms_wb2_o_addr_rd),
        .self_wb_i_regwrite(ms_wb2_o_regwrite),
        .cross_ex_i_addr_rd(es1_o_addr_rd),
        .cross_ex_i_regwrite(es1_ex_regwrite),
        .cross_ex_i_memread(es1_ex_memread),
        .cross_wb_i_addr_rd(ms_wb1_o_addr_rd),
        .cross_wb_i_regwrite(ms_wb1_o_regwrite),
        .f_o_control_rs1(fw2_o_data_rs),
        .f_o_control_rs2(fw2_o_data_rt),
        .f_o_stall(fw2_o_stall)
    );

    assign wb_ds1_o_data_rd = (ms_wb1_o_memtoreg) ? ms_wb1_o_load_data_1 : ms_wb1_o_alu_value;
    assign wb_ds2_o_data_rd = (ms_wb2_o_memtoreg) ? ms_wb2_o_load_data_2 : ms_wb2_o_alu_value;
endmodule
`endif
