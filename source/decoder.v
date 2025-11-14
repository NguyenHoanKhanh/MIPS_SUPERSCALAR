`ifndef DECODER_V
`define DECODER_V
`include "./source/header.vh"
module decoder (
    d_i_ce, d_i_instr, d_o_opcode, d_o_funct, d_o_addr_rs, d_o_addr_rt,
    d_o_addr_rd, d_o_imm, d_o_ce, d_o_alu_src, d_o_reg_wr, d_o_memwrite, 
    d_o_memtoreg, d_o_jal, d_o_jal_addr, d_o_jr, d_o_branch, d_o_reg_dst
);
    input d_i_ce;
    input [`IWIDTH - 1 : 0] d_i_instr;
    output reg d_o_ce;
    output reg d_o_jr;
    output reg d_o_jal;
    output reg d_o_reg_wr;
    output reg d_o_branch;
    output reg d_o_alu_src;
    output reg d_o_reg_dst;
    output reg d_o_memtoreg;
    output reg d_o_memwrite;
    output reg [`IMM_WIDTH - 1 : 0] d_o_imm;
    output reg [`FUNCT_WIDTH - 1 : 0] d_o_funct;
    output reg [`OPCODE_WIDTH - 1 : 0] d_o_opcode;
    output reg [`JUMP_WIDTH - 1 : 0] d_o_jal_addr;
    output reg [`AWIDTH - 1 : 0] d_o_addr_rs, d_o_addr_rt, d_o_addr_rd;

    wire [`DWIDTH - 1 : 0] d_i_data_rs, d_i_data_rt;
    wire [`FUNCT_WIDTH - 1 : 0] d_i_funct = d_i_instr[5 : 0];
    wire [`OPCODE_WIDTH - 1 : 0] d_i_opcode = d_i_instr[31 : 26];

    wire op_beq = d_i_opcode == `BEQ;
    wire op_bne = d_i_opcode == `BNE;
    wire op_ori = d_i_opcode == `ORI;
    wire op_jal = d_i_opcode == `JAL;
    wire op_andi = d_i_opcode == `ANDI;
    wire op_addi = d_i_opcode == `ADDI;
    wire op_slti = d_i_opcode == `SLTI;
    wire op_rtype = d_i_opcode == `RTYPE;
    wire op_addiu = d_i_opcode == `ADDIU;
    wire op_sltiu = d_i_opcode == `SLTIU;
    wire op_load = d_i_opcode == `LOAD_WORD;
    wire op_store = d_i_opcode == `STORE_WORD;


    wire funct_jr = d_i_funct == `JR;
    wire [4 : 0] rs, rt, rd;
    wire [`IMM_WIDTH - 1 : 0] imm;
    wire [`FUNCT_WIDTH - 1 : 0] funct; 
    wire [`OPCODE_WIDTH - 1 : 0] opcode;
    wire [`JUMP_WIDTH - 1 : 0] temp_jal;
    assign rs = d_i_instr[25 : 21];
    assign rt = d_i_instr[20 : 16];
    assign rd = d_i_instr[15 : 11];
    assign imm = d_i_instr[15 : 0];
    assign funct = d_i_instr[5 : 0];
    assign opcode = d_i_instr[31 : 26];
    assign temp_jal = d_i_instr[25 : 0];

    always @(*) begin
        d_o_ce = 1'b0;
        d_o_jr = 1'b0;
        d_o_jal = 1'b0;
        d_o_reg_wr = 1'b0;
        d_o_branch = 1'b0;
        d_o_alu_src = 1'b0;
        d_o_reg_dst = 1'b0;
        d_o_memwrite = 1'b0;
        d_o_memtoreg = 1'b0;
        d_o_imm = {`IMM_WIDTH{1'b0}};
        d_o_addr_rs = {`AWIDTH{1'b0}};
        d_o_addr_rt = {`AWIDTH{1'b0}};
        d_o_addr_rd = {`AWIDTH{1'b0}};
        d_o_funct = {`FUNCT_WIDTH{1'b0}};
        d_o_opcode = {`OPCODE_WIDTH{1'b0}};
        d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
        if (d_i_ce) begin
            if (op_rtype) begin
                if (funct_jr) begin
                    d_o_ce = 1'b1;
                    d_o_jr = 1'b1;
                    d_o_jal = 1'b0;
                    d_o_branch = 1'b0;
                    d_o_reg_wr = 1'b0;
                    d_o_funct = funct;
                    d_o_alu_src = 1'b0;
                    d_o_reg_dst = 1'b0;
                    d_o_opcode = opcode;
                    d_o_memtoreg = 1'b0;
                    d_o_memwrite = 1'b0;
                    d_o_addr_rs = 5'd31;
                    d_o_imm = {`IMM_WIDTH{1'b0}};
                    d_o_addr_rt = {`AWIDTH{1'b0}};
                    d_o_addr_rd = {`AWIDTH{1'b0}};
                    d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
                end
                else begin
                    d_o_ce = 1'b1;
                    d_o_jr = 1'b0;
                    d_o_jal = 1'b0;
                    d_o_addr_rs = rs;
                    d_o_addr_rt = rt;
                    d_o_addr_rd = rd;
                    d_o_reg_wr = 1'b1;
                    d_o_branch = 1'b0;
                    d_o_funct = funct;
                    d_o_reg_dst = 1'b1;
                    d_o_alu_src = 1'b0;
                    d_o_memtoreg = 1'b0;
                    d_o_memwrite = 1'b0;
                    d_o_opcode = opcode;
                    d_o_imm = {`IMM_WIDTH{1'b0}};
                    d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
                end
            end
            else if (op_addi || op_addiu || op_slti || op_sltiu || op_andi || op_ori) begin
                d_o_imm = imm;
                d_o_ce = 1'b1;
                d_o_jr = 1'b0;
                d_o_jal = 1'b0;
                d_o_addr_rs = rs;
                d_o_addr_rt = rt;
                d_o_reg_wr = 1'b1;
                d_o_branch = 1'b0;
                d_o_reg_dst = 1'b0;
                d_o_alu_src = 1'b1;
                d_o_memtoreg = 1'b0;
                d_o_memwrite = 1'b0;
                d_o_opcode = opcode;
                d_o_addr_rd = {`AWIDTH{1'b0}};
                d_o_funct = {`FUNCT_WIDTH{1'b0}};
                d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
            end
            else if (op_beq || op_bne) begin
                d_o_ce = 1'b1;
                d_o_jr = 1'b0;
                d_o_imm = imm;
                d_o_jal = 1'b0;
                d_o_addr_rs = rs;
                d_o_addr_rt = rt;
                d_o_reg_wr = 1'b0;
                d_o_branch = 1'b1;
                d_o_alu_src = 1'b0;
                d_o_reg_dst = 1'b0;
                d_o_opcode = opcode;
                d_o_memtoreg = 1'b0;
                d_o_memwrite = 1'b0;
                d_o_addr_rd = {`AWIDTH{1'b0}};
                d_o_funct = {`FUNCT_WIDTH{1'b0}};
                d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
            end
            else if (op_load || op_store) begin
                d_o_ce = 1'b1;
                d_o_jr = 1'b0;
                d_o_imm = imm;
                d_o_jal = 1'b0;
                d_o_addr_rs = rs;
                d_o_addr_rt = rt;
                d_o_branch = 1'b0;
                d_o_opcode = opcode;
                d_o_addr_rd = {`AWIDTH{1'b0}};
                d_o_funct = {`FUNCT_WIDTH{1'b0}};
                d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
                if (op_load) begin
                    d_o_reg_wr = 1'b1;
                    d_o_reg_dst = 1'b0;
                    d_o_alu_src = 1'b1;
                    d_o_memtoreg = 1'b1;
                end
                else if (op_store) begin
                    d_o_reg_dst = 1'b0;
                    d_o_alu_src = 1'b1;
                    d_o_memwrite = 1'b1;
                end
            end
            else if (op_jal) begin
                d_o_ce = 1'b1;
                d_o_jr = 1'b0;
                d_o_jal = 1'b1;
                d_o_reg_wr = 1'b1;
                d_o_branch = 1'b0;
                d_o_reg_dst = 1'b1;
                d_o_alu_src = 1'b0;
                d_o_addr_rd = 5'd31;
                d_o_memwrite = 1'b0;
                d_o_memtoreg = 1'b0;
                d_o_opcode = opcode;
                d_o_jal_addr = temp_jal;
                d_o_imm = {`IMM_WIDTH{1'b0}};
                d_o_addr_rs = {`AWIDTH{1'b0}};
                d_o_addr_rt = {`AWIDTH{1'b0}};
                d_o_funct = {`FUNCT_WIDTH{1'b0}};
            end
            else begin
                d_o_ce = 1'b0;
                d_o_jr = 1'b0;
                d_o_jal = 1'b0;
                d_o_reg_wr = 1'b0; 
                d_o_branch = 1'b0;
                d_o_alu_src = 1'b0;
                d_o_reg_dst = 1'b0;
                d_o_memwrite = 1'b0;
                d_o_memtoreg = 1'b0;
                d_o_imm = {`IMM_WIDTH{1'b0}};
                d_o_addr_rs = {`AWIDTH{1'b0}};
                d_o_addr_rt = {`AWIDTH{1'b0}};
                d_o_addr_rd = {`AWIDTH{1'b0}};
                d_o_funct = {`FUNCT_WIDTH{1'b0}};
                d_o_opcode = {`OPCODE_WIDTH{1'b0}};
                d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
            end
        end
        else begin
            d_o_ce = 1'b0;
            d_o_jr = 1'b0;
            d_o_jal = 1'b0;
            d_o_reg_wr = 1'b0;
            d_o_branch = 1'b0;
            d_o_reg_dst = 1'b0;
            d_o_alu_src = 1'b0;
            d_o_memwrite = 1'b0;
            d_o_memtoreg = 1'b0;
            d_o_imm = {`DWIDTH{1'b0}};
            d_o_addr_rs = {`AWIDTH{1'b0}};
            d_o_addr_rt = {`AWIDTH{1'b0}};
            d_o_addr_rd = {`AWIDTH{1'b0}};
            d_o_funct = {`FUNCT_WIDTH{1'b0}};
            d_o_opcode = {`OPCODE_WIDTH{1'b0}};
            d_o_jal_addr = {`JUMP_WIDTH{1'b0}};
        end
    end
endmodule
`endif 