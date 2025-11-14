`ifndef DATAPATH_V
`define DATAPATH_V
`include "./source/imem.v"
`include "./source/program_counter.v"
`include "./source/decoder_stage.v"
`include "./source/execute_stage.v"
`include "./source/execute_stage_1.v"
`include "./source/memory.v"
`include "./source/mux2_1.v"
`include "./source/mux21.v"
`include "./source/mux2_1_check_queue.v"
`include "./source/mux3_1.v"
`include "./source/forwarding.v"
`include "./source/treat_load.v"
`include "./source/treat_store.v"
`include "./source/check_dup_rd.v"
`include "./source/control_hazard.v"
`include "./source/queue_instr.v"
module datapath(
    d_clk, d_rst, d_i_ce, wb_ds1_o_data_rd, wb_ds2_o_data_rd, pc_o_pc_1, pc_o_pc_2
);
    input d_i_ce;
    input d_clk, d_rst;
    output [`PC_WIDTH - 1 : 0] pc_o_pc_1, pc_o_pc_2;
    output [`DWIDTH - 1 : 0] wb_ds1_o_data_rd, wb_ds2_o_data_rd;

    reg pc_im_o_ce;
    reg [`PC_WIDTH - 1 : 0] pc_im_o_pc_1, pc_im_o_pc_2;
    wire pc_o_ce;
    program_counter pc (
        .pc_i_clk(d_clk), 
        .pc_i_rst(d_rst), 
        .pc_i_ce(d_i_ce), 
        .pc_i_pc_1(pc_ds1_o_pc),
        .pc_i_pc_2(pc_ds2_o_pc),
        .pc_i_change_pc_1(pc_ds1_o_change_pc), 
        .pc_i_change_pc_2(pc_ds2_o_change_pc), 
        .pc_o_ce(pc_o_ce),
        .pc_o_pc_1(pc_o_pc_1), 
        .pc_o_pc_2(pc_o_pc_2) 
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

    reg choose_instr;
    reg im_ds1_o_ce, im_ds2_o_ce;
    reg [`PC_WIDTH - 1 : 0] im_ds1_o_pc, im_ds2_o_pc;
    reg [`IWIDTH - 1 : 0] im_ds1_o_instr, im_ds2_o_instr;
    wire im_o_ce;
    wire [`IWIDTH - 1 : 0] im_o_instr_1, im_o_instr_2;
    imem im (
        .im_clk(d_clk), 
        .im_rst(d_rst), 
        .im_i_ce(pc_im_o_ce), 
        .im_i_addr_1(pc_im_o_pc_1), 
        .im_i_addr_2(pc_im_o_pc_2), 
        .im_o_ce(im_o_ce),
        .im_o_instr_1(im_o_instr_1), 
        .im_o_instr_2(im_o_instr_2)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            im_ds1_o_ce <= 1'b0; 
            im_ds1_o_pc <= {`PC_WIDTH{1'b0}};
            im_ds1_o_instr <= {`IWIDTH{1'b0}};
        end
        else begin
            if (!forwarding1_stall) begin
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
            if (!forwarding2_stall) begin
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

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            q_i_we <= 1'b0;
            q_i_re <= 1'b0;
            q_ds1_o_instr <= {`IWIDTH{1'b0}};
            queue_i_instr <= {`IWIDTH{1'b0}};
        end
        else begin
            q_i_we <= cd_o_we;
            q_ds1_o_instr <= q_o_instr;
            queue_i_instr <= ds2_queue_o_instr;
            q_i_re <= es1_queue_o_request_instr;
            choose_instr <= es1_queue_o_request_instr;
        end
    end
    reg q_i_we;
    reg q_i_re;
    reg [`IWIDTH - 1 : 0] queue_i_instr;
    reg [`IWIDTH - 1 : 0] q_ds1_o_instr;
    wire [`IWIDTH - 1 : 0] q_o_instr;
    queue_instr queue (
        .q_clk(d_clk), 
        .q_rst(d_rst), 
        // .q_i_instr(), 
        .q_i_instr(queue_i_instr),
        .q_i_we(q_i_we), 
        .q_i_re(q_i_re), 
        .q_o_instr(q_o_instr)
    );

    wire [`IWIDTH - 1 : 0] mx_o_instr;
    mux2_1_check_queue mux_choose_instr (
        .mx_i_queue_instr(q_ds1_o_instr), 
        .mx_i_mem_instr(im_ds1_o_instr),
        // .mx_i_check_queue(es1_queue_o_request_instr), 
        .mx_i_check_queue(choose_instr), 
        .mx_o_instr(mx_o_instr)
    );

    reg ds1_es1_o_ce;
    reg ds1_es1_o_jr;
    reg ds1_es1_o_jal;
    reg ds1_es1_o_branch;
    reg ds1_es1_o_reg_dst;
    reg ds1_es1_o_alu_src;
    reg ds1_es1_o_memwrite;
    reg ds1_es1_o_memtoreg;
    reg ds1_es1_o_reg_write; 
    reg [`PC_WIDTH - 1 : 0] ds1_es1_o_pc;
    reg [`IMM_WIDTH - 1 : 0] ds1_es1_o_imm;
    reg [`AWIDTH - 1 : 0] ds1_es1_o_addr_rd;
    reg [`FUNCT_WIDTH - 1 : 0] ds1_es1_o_funct;
    reg [`OPCODE_WIDTH - 1 : 0] ds1_es1_o_opcode;
    reg [`JUMP_WIDTH - 1 : 0] ds1_es1_o_jal_addr;
    reg [`AWIDTH - 1 : 0] ds1_es1_o_addr_rs, ds1_es1_o_addr_rt;
    reg [`DWIDTH - 1 : 0] ds1_es1_o_data_rs, ds1_es1_o_data_rt;
    wire ds1_o_ce;
    wire ds1_o_jr;
    wire ds1_o_jal;
    wire ds1_o_branch;
    wire ds1_o_reg_dst;
    wire ds1_o_alu_src;
    wire ds1_o_memwrite;
    wire ds1_o_memtoreg;
    wire ds1_o_reg_write;
    wire [`IMM_WIDTH - 1 : 0] ds1_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] ds1_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds1_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds1_o_jal_addr;
    wire [`DWIDTH - 1 : 0] ds1_o_data_rs, ds1_o_data_rt;
    wire [`AWIDTH - 1 : 0] ds1_o_addr_rd, ds1_o_addr_rs, ds1_o_addr_rt;
    decoder_stage ds1 (
        .ds_i_clk(d_clk), 
        .ds_i_rst(d_rst), 
        .ds_i_ce(im_ds1_o_ce), 
        .ds_i_instr(mx_o_instr), 
        .ds_i_addr_rd(ms_wb1_o_addr_rd), 
        .ds_i_data_rd(wb_ds1_o_data_rd), 
        .ds_i_reg_write(ms_wb1_o_regwrite), 
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
        .ds_o_data_rs(ds1_o_data_rs),
        .ds_o_data_rt(ds1_o_data_rt),
        .ds_o_jal_addr(ds1_o_jal_addr), 
        .ds_o_memwrite(ds1_o_memwrite), 
        .ds_o_memtoreg(ds1_o_memtoreg), 
        .ds_o_reg_write(ds1_o_reg_write) 
    );
    
    reg ds2_es2_o_ce;
    reg ds2_es2_o_jr;
    reg ds2_es2_o_jal;
    reg ds2_es2_o_branch;
    reg ds2_es2_o_reg_dst;
    reg ds2_es2_o_alu_src;
    reg ds2_es2_o_memwrite;
    reg ds2_es2_o_memtoreg;
    reg ds2_es2_o_reg_write; 
    reg [`PC_WIDTH - 1 : 0] ds2_es2_o_pc;
    reg [`IMM_WIDTH - 1 : 0] ds2_es2_o_imm;
    reg [`AWIDTH - 1 : 0] ds2_es2_o_addr_rd;
    reg [`FUNCT_WIDTH - 1 : 0] ds2_es2_o_funct;
    reg [`OPCODE_WIDTH - 1 : 0] ds2_es2_o_opcode;
    reg [`IWIDTH - 1 : 0] ds2_queue_o_instr;
    reg [`JUMP_WIDTH - 1 : 0] ds2_es2_o_jal_addr;
    reg [`DWIDTH - 1 : 0] ds2_es2_o_data_rs, ds2_es2_o_data_rt;
    reg [`AWIDTH - 1 : 0] ds2_es2_o_addr_rs, ds2_es2_o_addr_rt;
    wire ds2_o_ce;
    wire ds2_o_jr;
    wire ds2_o_jal;
    wire ds2_o_branch;
    wire ds2_o_reg_dst;
    wire ds2_o_alu_src;
    wire ds2_o_memwrite;
    wire ds2_o_memtoreg;
    wire ds2_o_reg_write;
    wire [`IMM_WIDTH - 1 : 0] ds2_o_imm;
    wire [`FUNCT_WIDTH - 1 : 0] ds2_o_funct;
    wire [`OPCODE_WIDTH - 1 : 0] ds2_o_opcode;
    wire [`JUMP_WIDTH - 1 : 0] ds2_o_jal_addr;
    wire [`DWIDTH - 1 : 0] ds2_o_data_rs, ds2_o_data_rt;
    wire [`AWIDTH - 1 : 0] ds2_o_addr_rd, ds2_o_addr_rs, ds2_o_addr_rt;
    decoder_stage ds2 (
        .ds_i_clk(d_clk), 
        .ds_i_rst(d_rst), 
        .ds_i_ce(im_ds2_o_ce), 
        .ds_i_instr(im_ds2_o_instr), 
        .ds_i_addr_rd(ms_wb2_o_addr_rd), 
        .ds_i_data_rd(wb_ds2_o_data_rd), 
        .ds_i_reg_write(ms_wb2_o_regwrite), 
        .ds_o_ce(ds2_o_ce), 
        .ds_o_jr(ds2_o_jr), 
        .ds_o_imm(ds2_o_imm), 
        .ds_o_jal(ds2_o_jal), 
        .ds_o_funct(ds2_o_funct), 
        .ds_o_opcode(ds2_o_opcode), 
        .ds_o_branch(ds2_o_branch), 
        .ds_o_addr_rd(ds2_o_addr_rd), 
        .ds_o_addr_rt(ds2_o_addr_rt), 
        .ds_o_addr_rs(ds2_o_addr_rs), 
        .ds_o_reg_dst(ds2_o_reg_dst), 
        .ds_o_alu_src(ds2_o_alu_src), 
        .ds_o_data_rs(ds2_o_data_rs),
        .ds_o_data_rt(ds2_o_data_rt),
        .ds_o_jal_addr(ds2_o_jal_addr), 
        .ds_o_memwrite(ds2_o_memwrite), 
        .ds_o_memtoreg(ds2_o_memtoreg), 
        .ds_o_reg_write(ds2_o_reg_write) 
    );

    wire pc_ds1_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] pc_ds1_o_pc;
    control_hazard ch1 (
        .i_imm(ds1_o_imm), 
        .i_pc(im_ds1_o_pc), 
        .i_branch(ds1_o_branch), 
        .i_opcode(ds1_o_opcode), 
        .i_data_r1(ds1_o_data_rs), 
        .i_data_r2(ds1_o_data_rt), 
        .i_es_o_pc(es1_ctrl1_o_alu_pc), 
        .i_es_o_change_pc(es1_ctrl1_o_change_pc), 
        .o_pc(pc_ds1_o_pc), 
        .o_compare(pc_ds1_o_change_pc)
    );

    wire pc_ds2_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] pc_ds2_o_pc;
    control_hazard ch2 (
        .i_imm(ds2_o_imm), 
        .i_pc(im_ds2_o_pc), 
        .i_branch(ds2_o_branch), 
        .i_opcode(ds2_o_opcode), 
        .i_data_r1(ds2_o_data_rs), 
        .i_data_r2(ds2_o_data_rt), 
        .i_es_o_pc(es2_ctrl2_o_alu_pc), 
        .i_es_o_change_pc(es2_ctrl2_o_change_pc), 
        .o_pc(pc_ds2_o_pc), 
        .o_compare(pc_ds2_o_change_pc)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            ds1_es1_o_ce <= 1'b0;
            ds1_es1_o_jr <= 1'b0;
            ds1_es1_o_jal <= 1'b0;
            ds1_es1_o_branch <= 1'b0;
            ds1_es1_o_reg_dst <= 1'b0;
            ds1_es1_o_alu_src <= 1'b0;
            ds1_es1_o_memwrite <= 1'b0;
            ds1_es1_o_memtoreg <= 1'b0;
            ds1_es1_o_reg_write <= 1'b0; 
            ds1_es1_o_pc <= {`PC_WIDTH{1'b0}};
            ds1_es1_o_addr_rd <= {`AWIDTH{1'b0}};
            ds1_es1_o_imm <= {`IMM_WIDTH{1'b0}};
            ds1_es1_o_data_rs <= {`DWIDTH{1'b0}}; 
            ds1_es1_o_data_rt <= {`DWIDTH{1'b0}};
            ds1_es1_o_addr_rs <= {`AWIDTH{1'b0}}; 
            ds1_es1_o_addr_rt <= {`AWIDTH{1'b0}};
            ds1_es1_o_funct <= {`FUNCT_WIDTH{1'b0}};
            ds1_es1_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            ds1_es1_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
        end
        else begin
            if (!forwarding1_stall) begin
                ds1_es1_o_ce <= ds1_o_ce;
                ds1_es1_o_jr <= ds1_o_jr;
                ds1_es1_o_jal <= ds1_o_jal;
                ds1_es1_o_imm <= ds1_o_imm;
                ds1_es1_o_pc <= im_ds1_o_pc;
                ds1_es1_o_funct <= ds1_o_funct;
                ds1_es1_o_opcode <= ds1_o_opcode;
                ds1_es1_o_branch <= ds1_o_branch;
                ds1_es1_o_addr_rd <= ds1_o_addr_rd;
                ds1_es1_o_data_rs <= ds1_o_data_rs; 
                ds1_es1_o_data_rt <= ds1_o_data_rt;
                ds1_es1_o_addr_rs <= ds1_o_addr_rs; 
                ds1_es1_o_addr_rt <= ds1_o_addr_rt;
                ds1_es1_o_reg_dst <= ds1_o_reg_dst;
                ds1_es1_o_alu_src <= ds1_o_alu_src;
                ds1_es1_o_memwrite <= ds1_o_memwrite;
                ds1_es1_o_jal_addr <= ds1_o_jal_addr;
                ds1_es1_o_memtoreg <= ds1_o_memtoreg;
                ds1_es1_o_reg_write <= ds1_o_reg_write;  
            end
            else begin
                ds1_es1_o_ce <= 1'b0;
                ds1_es1_o_jr <= 1'b0;
                ds1_es1_o_jal <= 1'b0;
                ds1_es1_o_branch <= 1'b0;
                ds1_es1_o_reg_dst <= 1'b0;
                ds1_es1_o_alu_src <= 1'b0;
                ds1_es1_o_memwrite <= 1'b0;
                ds1_es1_o_memtoreg <= 1'b0;
                ds1_es1_o_reg_write <= 1'b0;
                ds1_es1_o_pc <= {`PC_WIDTH{1'b0}};
                ds1_es1_o_imm <= {`IMM_WIDTH{1'b0}};
                ds1_es1_o_addr_rd <= {`AWIDTH{1'b0}};  
                ds1_es1_o_data_rs <= {`DWIDTH{1'b0}}; 
                ds1_es1_o_data_rt <= {`DWIDTH{1'b0}};
                ds1_es1_o_addr_rs <= {`AWIDTH{1'b0}}; 
                ds1_es1_o_addr_rt <= {`AWIDTH{1'b0}};
                ds1_es1_o_funct <= {`FUNCT_WIDTH{1'b0}};
                ds1_es1_o_opcode <= {`OPCODE_WIDTH{1'b0}};
                ds1_es1_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
            end
        end
    end

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            ds2_es2_o_ce <= 1'b0;
            ds2_es2_o_jr <= 1'b0;
            ds2_es2_o_jal <= 1'b0;
            ds2_es2_o_branch <= 1'b0;
            ds2_es2_o_reg_dst <= 1'b0;
            ds2_es2_o_alu_src <= 1'b0;
            ds2_es2_o_memwrite <= 1'b0;
            ds2_es2_o_memtoreg <= 1'b0;
            ds2_es2_o_reg_write <= 1'b0;  
            ds2_es2_o_pc <= {`PC_WIDTH{1'b0}};
            ds2_es2_o_imm <= {`IMM_WIDTH{1'b0}};
            ds2_es2_o_addr_rd <= {`AWIDTH{1'b0}};
            ds2_es2_o_data_rs <= {`DWIDTH{1'b0}}; 
            ds2_es2_o_data_rt <= {`DWIDTH{1'b0}};
            ds2_es2_o_addr_rs <= {`AWIDTH{1'b0}}; 
            ds2_es2_o_addr_rt <= {`AWIDTH{1'b0}};
            ds2_queue_o_instr <= {`IWIDTH{1'b0}};
            ds2_es2_o_funct <= {`FUNCT_WIDTH{1'b0}};
            ds2_es2_o_opcode <= {`OPCODE_WIDTH{1'b0}};
            ds2_es2_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
        end
        else begin
            if (!forwarding2_stall) begin
                ds2_es2_o_ce <= ds2_o_ce;
                ds2_es2_o_jr <= ds2_o_jr;
                ds2_es2_o_jal <= ds2_o_jal;
                ds2_es2_o_imm <= ds2_o_imm;
                ds2_es2_o_pc <= im_ds2_o_pc;
                ds2_es2_o_funct <= ds2_o_funct;
                ds2_es2_o_opcode <= ds2_o_opcode;
                ds2_es2_o_branch <= ds2_o_branch;
                ds2_es2_o_addr_rd <= ds2_o_addr_rd;
                ds2_es2_o_data_rs <= ds2_o_data_rs; 
                ds2_es2_o_data_rt <= ds2_o_data_rt;
                ds2_es2_o_addr_rs <= ds2_o_addr_rs;
                ds2_es2_o_addr_rt <= ds2_o_addr_rt; 
                ds2_es2_o_reg_dst <= ds2_o_reg_dst;
                ds2_es2_o_alu_src <= ds2_o_alu_src;
                ds2_queue_o_instr <= im_ds2_o_instr;
                ds2_es2_o_memwrite <= ds2_o_memwrite;
                ds2_es2_o_jal_addr <= ds2_o_jal_addr;
                ds2_es2_o_memtoreg <= ds2_o_memtoreg;
                ds2_es2_o_reg_write <= ds2_o_reg_write;
            end
            else begin
                ds2_es2_o_ce <= 1'b0;
                ds2_es2_o_jr <= 1'b0;
                ds2_es2_o_jal <= 1'b0;
                ds2_es2_o_branch <= 1'b0;
                ds2_es2_o_reg_dst <= 1'b0;
                ds2_es2_o_alu_src <= 1'b0;
                ds2_es2_o_memwrite <= 1'b0;
                ds2_es2_o_memtoreg <= 1'b0;
                ds2_es2_o_reg_write <= 1'b0;  
                ds2_es2_o_pc <= {`PC_WIDTH{1'b0}};
                ds2_es2_o_imm <= {`IMM_WIDTH{1'b0}};
                ds2_queue_o_instr <= {`IWIDTH{1'b0}};
                ds2_es2_o_addr_rd <= {`AWIDTH{1'b0}};
                ds2_es2_o_data_rs <= {`DWIDTH{1'b0}}; 
                ds2_es2_o_data_rt <= {`DWIDTH{1'b0}};
                ds2_es2_o_addr_rs <= {`AWIDTH{1'b0}}; 
                ds2_es2_o_addr_rt <= {`AWIDTH{1'b0}};
                ds2_es2_o_funct <= {`FUNCT_WIDTH{1'b0}};
                ds2_es2_o_opcode <= {`OPCODE_WIDTH{1'b0}};
                ds2_es2_o_jal_addr <= {`JUMP_WIDTH{1'b0}};
            end
        end
    end

    wire ce;
    mux m4 (
        .a(ds2_es2_o_ce),
        .b(cd_o_we),
        .c(ce)
    );
    
    wire [`AWIDTH - 1 : 0] mx1_o_addr_rd;
    mux2_1  m1 (
        .mx_i_addr_rd(ds1_es1_o_addr_rd), 
        .mx_i_addr_rt(ds1_es1_o_addr_rt), 
        .mx_i_reg_dst(ds1_es1_o_reg_dst), 
        .mx_o_addr_rd(mx1_o_addr_rd)
    );  

    wire [`AWIDTH - 1 : 0] mx2_o_addr_rd;   
    mux2_1  m2 (
        .mx_i_addr_rd(ds2_es2_o_addr_rd), 
        .mx_i_addr_rt(ds2_es2_o_addr_rt), 
        .mx_i_reg_dst(ds2_es2_o_reg_dst), 
        .mx_o_addr_rd(mx2_o_addr_rd)
    );

    wire cd_o_we;
    check_dup cd (
        .cd_i_addr_rd_1(mx1_o_addr_rd), 
        .cd_i_addr_rs_2(ds2_es2_o_addr_rs), 
        .cd_i_addr_rt_2(ds2_es2_o_addr_rt), 
        .cd_i_opcode_2(ds2_es2_o_opcode),
        .cd_o_we(cd_o_we)
    );

    wire [`DWIDTH - 1 : 0] mx_es1_o_data_rs;
    mux3_1 mux1 (
        .data(ds1_es1_o_data_rs), 
        .alu_value(es1_ms_o_alu_value), 
        .write_back_data(wb_ds1_o_data_rd), 
        .forwarding(forwarding1_1), 
        .data_out(mx_es1_o_data_rs)
    );

    wire [`DWIDTH - 1 : 0] mx_es1_o_data_rt;
    mux3_1 mux2 (
        .data(ds1_es1_o_data_rt), 
        .alu_value(es1_ms_o_alu_value), 
        .write_back_data(wb_ds1_o_data_rd), 
        .forwarding(forwarding1_2), 
        .data_out(mx_es1_o_data_rt)
    );

    wire [`DWIDTH - 1 : 0] mx_es2_o_data_rs;
    mux3_1 mux3 (
        .data(ds2_es2_o_data_rs), 
        .alu_value(es2_ms_o_alu_value), 
        .write_back_data(wb_ds2_o_data_rd), 
        .forwarding(forwarding2_1), 
        .data_out(mx_es2_o_data_rs)
    );

    wire [`DWIDTH - 1 : 0] mx_es2_o_data_rt;
    mux3_1 mux4 (
        .data(ds2_es2_o_data_rt), 
        .alu_value(es2_ms_o_alu_value), 
        .write_back_data(wb_ds2_o_data_rd), 
        .forwarding(forwarding2_2), 
        .data_out(mx_es2_o_data_rt)
    ); 

    reg es1_ms_o_ce;
    reg es1_ms_o_memwrite;
    reg es1_ms_o_memtoreg;
    reg es1_ms_o_regwrite;
    reg es1_ctrl1_o_change_pc;
    reg [`AWIDTH - 1 : 0] es1_ms_o_addr_rd;
    reg [`DWIDTH - 1 : 0] es1_ms_o_alu_value;
    reg [`PC_WIDTH - 1 : 0] es1_ctrl1_o_alu_pc;
    reg [`OPCODE_WIDTH - 1 : 0] es1_tl1_o_opcode;
    reg es1_queue_o_request_instr;
    wire es1_o_ce;
    wire es1_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] es1_o_alu_pc;
    wire [`DWIDTH - 1 : 0] es1_o_alu_value;
    wire [`OPCODE_WIDTH - 1 : 0] es1_o_opcode;
    wire queue_o_request_instr;
    execute_1 es1 (
        .es_i_ce(ds1_es1_o_ce), 
        .es_i_jr(ds1_es1_o_jr), 
        .es_i_pc(ds1_es1_o_pc), 
        .es_i_jal(ds1_es1_o_jal), 
        .es_i_imm(ds1_es1_o_imm), 
        .es_i_fetch_queue(cd_o_we),
        .es_i_alu_op(ds1_es1_o_opcode), 
        .es_i_alu_src(ds1_es1_o_alu_src), 
        .es_i_alu_funct(ds1_es1_o_funct),
        .es_i_data_rs(ds1_es1_o_data_rs), 
        .es_i_data_rt(ds1_es1_o_data_rt), 
        .es_i_jal_addr(ds1_es1_o_jal_addr), 
        .es_o_ce(es1_o_ce), 
        .es_o_opcode(es1_o_opcode),
        .es_o_alu_pc(es1_o_alu_pc),
        .es_o_alu_value(es1_o_alu_value), 
        .es_o_change_pc(es1_o_change_pc),
        .es_o_fetch_queue(queue_o_request_instr)
    );

    reg es2_ms_o_ce;
    reg es2_ms_o_memwrite;
    reg es2_ms_o_memtoreg;
    reg es2_ms_o_regwrite;
    reg es2_ctrl2_o_change_pc;
    reg [`AWIDTH - 1 : 0] es2_ms_o_addr_rd;
    reg [`DWIDTH - 1 : 0] es2_ms_o_alu_value;
    reg [`PC_WIDTH - 1 : 0] es2_ctrl2_o_alu_pc;
    reg [`OPCODE_WIDTH - 1 : 0] es2_tl2_o_opcode;
    wire es2_o_ce;
    wire es2_o_change_pc;
    wire [`PC_WIDTH - 1 : 0] es2_o_alu_pc;
    wire [`DWIDTH - 1 : 0] es2_o_alu_value;
    wire [`OPCODE_WIDTH - 1 : 0] es2_o_opcode;
    execute es2 (
        .es_i_ce(ce), 
        .es_i_jr(ds2_es2_o_jr), 
        .es_i_pc(ds2_es2_o_pc), 
        .es_i_jal(ds2_es2_o_jal), 
        .es_i_imm(ds2_es2_o_imm), 
        .es_i_alu_op(ds2_es2_o_opcode), 
        .es_i_alu_src(ds2_es2_o_alu_src), 
        .es_i_alu_funct(ds2_es2_o_funct),
        .es_i_data_rs(ds2_es2_o_data_rs), 
        .es_i_data_rt(ds2_es2_o_data_rt), 
        .es_i_jal_addr(ds2_es2_o_jal_addr), 
        .es_o_ce(es2_o_ce), 
        .es_o_opcode(es2_o_opcode),
        .es_o_alu_pc(es2_o_alu_pc),
        .es_o_alu_value(es2_o_alu_value), 
        .es_o_change_pc(es2_o_change_pc)
    );

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            es1_ms_o_ce <= 1'b0;
            es1_ms_o_memwrite <= 1'b0;
            es1_ms_o_memtoreg <= 1'b0;
            es1_ms_o_regwrite <= 1'b0;
            es1_ctrl1_o_change_pc <= 1'b0;
            es1_queue_o_request_instr <= 1'b0;
            es1_ms_o_addr_rd <= {`AWIDTH{1'b0}};
            es1_ms_o_alu_value <= {`DWIDTH{1'b0}};
            es1_ctrl1_o_alu_pc <= {`PC_WIDTH{1'b0}};
            es1_tl1_o_opcode <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            es1_ms_o_ce <= es1_o_ce;
            es1_tl1_o_opcode <= es1_o_opcode;
            es1_ms_o_addr_rd <= mx1_o_addr_rd;
            es1_ctrl1_o_alu_pc <= es1_o_alu_pc;
            es1_ms_o_alu_value <= es1_o_alu_value;
            es1_ms_o_memtoreg <= ds1_es1_o_memtoreg;
            es1_ms_o_memwrite <= ds1_es1_o_memwrite;
            es1_ms_o_regwrite <= ds1_es1_o_reg_write;
            es1_ctrl1_o_change_pc <= es1_o_change_pc;
            es1_queue_o_request_instr <= queue_o_request_instr;
        end
    end

    always @(posedge d_clk, negedge d_rst) begin
        if (!d_rst) begin
            es2_ms_o_ce <= 1'b0;
            es2_ms_o_memwrite <= 1'b0;
            es2_ms_o_memtoreg <= 1'b0;
            es2_ms_o_regwrite <= 1'b0;
            es2_ctrl2_o_change_pc <= 1'b0;
            es2_ms_o_addr_rd <= {`AWIDTH{1'b0}};
            es2_ms_o_alu_value <= {`DWIDTH{1'b0}};
            es2_ctrl2_o_alu_pc <= {`PC_WIDTH{1'b0}};
            es2_tl2_o_opcode <= {`OPCODE_WIDTH{1'b0}};
        end
        else begin
            es2_ms_o_ce <= es2_o_ce;
            es2_tl2_o_opcode <= es2_o_opcode;
            es2_ms_o_addr_rd <= mx2_o_addr_rd;
            es2_ctrl2_o_alu_pc <= es2_o_alu_pc;
            es2_ms_o_alu_value <= es2_o_alu_value;
            es2_ms_o_memtoreg <= ds2_es2_o_memtoreg;
            es2_ms_o_memwrite <= ds2_es2_o_memwrite;
            es2_ms_o_regwrite <= ds2_es2_o_reg_write;
            es2_ctrl2_o_change_pc <= es2_o_change_pc;
        end
    end 

    wire [3 : 0] ts1_ms_o_mask;
    wire [`DWIDTH - 1 : 0] ts1_ms_o_data_store;
    treatstore ts1 (
        .ts_i_opcode(ds1_es1_o_opcode), 
        .ts_i_store_data(ds1_es1_o_data_rs), 
        .ts_o_store_mask(ts1_ms_o_mask),
        .ts_o_store_data(ts1_ms_o_data_store) 
    );
    
    wire [3 : 0] ts2_ms_o_mask;
    wire [`DWIDTH - 1 : 0] ts2_ms_o_data_store;
    treatstore ts2 (
        .ts_i_opcode(ds2_es2_o_opcode), 
        .ts_i_store_data(ds2_es2_o_data_rs), 
        .ts_o_store_mask(ts2_ms_o_mask),
        .ts_o_store_data(ts2_ms_o_data_store) 
    );

    reg ms_wb1_o_memtoreg, ms_wb2_o_memtoreg;
    reg ms_wb1_o_regwrite, ms_wb2_o_regwrite;
    reg [`AWIDTH - 1 : 0] ms_wb1_o_addr_rd, ms_wb2_o_addr_rd;
    reg [`DWIDTH - 1 : 0] ms_wb1_o_alu_value, ms_wb2_o_alu_value;
    reg [`DWIDTH - 1 : 0] ms_wb1_o_load_data, ms_wb2_o_load_data;
    wire [`DWIDTH - 1 : 0] mem_o_load_data_1, mem_o_load_data_2;
    memory m (
        .m_clk(d_clk), 
        .m_rst(d_rst), 
        .m_i_ce_1(es1_ms_o_ce), 
        .m_i_ce_2(es2_ms_o_ce), 
        .m_i_mask_1(ts1_ms_o_mask), 
        .m_i_mask_2(ts2_ms_o_mask), 
        .m_i_wr_en_1(es1_ms_o_memwrite), 
        .m_i_wr_en_2(es2_ms_o_memwrite), 
        .m_i_data_rs_1(ts1_ms_o_data_store), 
        .m_i_data_rs_2(ts2_ms_o_data_store),
        .m_i_alu_value_1(es1_ms_o_alu_value), 
        .m_i_alu_value_2(es2_ms_o_alu_value), 
        .m_o_load_data_1(mem_o_load_data_1),
        .m_o_load_data_2(mem_o_load_data_2)
    );

    wire [`DWIDTH - 1 : 0] tl1_o_load_data;
    treatload tl1 (
        .tl_i_load_data(mem_o_load_data_1), 
        .tl_i_opcode(es1_tl1_o_opcode), 
        .tl_o_load_data(tl1_o_load_data)
    );

    wire [`DWIDTH - 1 : 0] tl2_o_load_data;
    treatload tl2 (
        .tl_i_load_data(mem_o_load_data_2), 
        .tl_i_opcode(es2_tl2_o_opcode), 
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
            ms_wb1_o_load_data <= {`DWIDTH{1'b0}};
            ms_wb2_o_load_data <= {`DWIDTH{1'b0}};
        end
        else begin
            ms_wb1_o_addr_rd <= es1_ms_o_addr_rd;
            ms_wb2_o_addr_rd <= es2_ms_o_addr_rd;
            ms_wb1_o_load_data <= tl1_o_load_data;
            ms_wb2_o_load_data <= tl2_o_load_data;
            ms_wb1_o_regwrite <= es1_ms_o_regwrite;
            ms_wb2_o_regwrite <= es2_ms_o_regwrite;
            ms_wb1_o_memtoreg <= es1_ms_o_memtoreg;
            ms_wb2_o_memtoreg <= es2_ms_o_memtoreg;
            ms_wb1_o_alu_value <= es1_ms_o_alu_value;
            ms_wb2_o_alu_value <= es2_ms_o_alu_value;
        end
    end

    wire forwarding1_stall;
    wire [1 : 0] forwarding1_1, forwarding1_2;
    forwarding f1 (
        .ds_es_i_opcode(ds1_es1_o_opcode), 
        .es_ms_i_addr_rd(es1_ms_o_addr_rd), 
        .ms_wb_i_addr_rd(ms_wb1_o_addr_rd), 
        .es_ms_i_regwrite(es1_ms_o_regwrite), 
        .ms_wb_i_regwrite(ms_wb1_o_regwrite), 
        .ds_es_i_addr_rs1(ds1_es1_o_addr_rs), 
        .ds_es_i_addr_rs2(ds1_es1_o_addr_rt), 
        .f_o_stall(forwarding1_stall),
        .f_o_control_rs1(forwarding1_1), 
        .f_o_control_rs2(forwarding1_2) 
    );

    wire forwarding2_stall;
    wire [1 : 0] forwarding2_1, forwarding2_2;
    forwarding f2 (
        .ds_es_i_opcode(ds2_es2_o_opcode), 
        .es_ms_i_addr_rd(es2_ms_o_addr_rd), 
        .ms_wb_i_addr_rd(ms_wb2_o_addr_rd), 
        .ds_es_i_addr_rs1(ds2_es2_o_addr_rs), 
        .ds_es_i_addr_rs2(ds2_es2_o_addr_rt), 
        .es_ms_i_regwrite(es2_ms_o_regwrite), 
        .ms_wb_i_regwrite(ms_wb2_o_regwrite), 
        .f_o_stall(forwarding2_stall),
        .f_o_control_rs1(forwarding2_1), 
        .f_o_control_rs2(forwarding2_2)
    );

    assign wb_ds1_o_data_rd = (ms_wb1_o_memtoreg) ? ms_wb1_o_load_data : ms_wb1_o_alu_value;
    assign wb_ds2_o_data_rd = (ms_wb2_o_memtoreg) ? ms_wb2_o_load_data : ms_wb2_o_alu_value;
endmodule
`endif 